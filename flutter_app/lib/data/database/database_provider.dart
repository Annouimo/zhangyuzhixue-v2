import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../debug/audit_logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';
import 'dart:convert' show utf8;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/assets_database.dart';
import '../database/courses_database.dart';
import '../database/app_database.dart';

/// 三库生命周期管理
class DatabaseProvider {
  DatabaseProvider._internal();
  static DatabaseProvider? _instance;
  factory DatabaseProvider() {
    _instance ??= DatabaseProvider._internal();
    return _instance!;
  }

  AppDatabase? _appDb;
  AssetsDatabase? _assetsDb;
  CoursesDatabase? _coursesDb;
  bool _initialized = false;
  String? _dbDirPath;
  String? _imagesDirPath;
  int _dbVersion = 0;
  final ValueNotifier<int> _dbVersionNotifier = ValueNotifier<int>(0);

  /// 数据库版本号——每次替换/清空时递增，供 UI 层监听以重建页面
  ValueNotifier<int> get dbVersionNotifier => _dbVersionNotifier;

  void _bumpVersion() {
    _dbVersion++;
    _dbVersionNotifier.value = _dbVersion;
  }

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationSupportDirectory();
    _dbDirPath = dir.path;
    await _ensureDefaultDb(dir, 'assets.db');
    await _ensureDefaultDb(dir, 'courses.db');
    _imagesDirPath = '${dir.path}/images';
    await _ensureUserDbSchema(dir);
    await _openAll(dir);
    _initialized = true;
  }

  /// ⚠️ 仅限测试使用！绝对不要在业务代码中调用。
  ///
  /// 用指定目录路径初始化三库，跳过 getApplicationSupportDirectory()
  /// 和 rootBundle 的默认资源复制。测试中请传入临时目录。
  ///
  /// 误传 /sdcard/ 等无权限路径会导致 App 崩溃。
  @visibleForTesting
  Future<void> initWithPath(String dirPath) async {
    if (_initialized) return;
    _dbDirPath = dirPath;
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await _ensureUserDbSchema(dir);
    await _openAll(dir);
    _initialized = true;
  }

  Future<void> _openAll(Directory dir) async {
    _assetsDb = AssetsDatabase(LazyDatabase(() async {
      return NativeDatabase(File('${dir.path}/assets.db'));
    }));
    _coursesDb = CoursesDatabase(LazyDatabase(() async {
      return NativeDatabase(File('${dir.path}/courses.db'));
    }));
    _appDb = AppDatabase(LazyDatabase(() async {
      return NativeDatabase(File('${dir.path}/user.db'));
    }));
    await _appDb!.customStatement('PRAGMA journal_mode=WAL');
  }

  Future<void> _ensureDefaultDb(Directory dir, String name) async {
    final file = File('${dir.path}/$name');
    final verFile = name == 'assets.db' ? '.qbank_version' : '.courses_version';
    int bundleVersion = 0;
    try {
      final verStr = await rootBundle.loadString('assets/db/$verFile');
      bundleVersion = int.tryParse(verStr.trim()) ?? 0;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_${name}_version';
    final cachedVersion = prefs.getInt(cacheKey) ?? 0;
    if (!await file.exists() || bundleVersion > cachedVersion) {
      final data = await rootBundle.load('assets/db/$name');
      await file.writeAsBytes(data.buffer.asUint8List());
      await prefs.setInt(cacheKey, bundleVersion);
    }
  }

  /// 检测 user.db 表结构是否匹配当前 schemaVersion。
  /// 旧版 schema（表名不匹配）→ 删掉重建，数据由登录时全量拉取恢复。
  Future<void> _ensureUserDbSchema(Directory dir) async {
    final file = File('${dir.path}/user.db');
    if (!await file.exists()) return;
    AppDatabase? db;
    try {
      db = AppDatabase(NativeDatabase(file));
      await db.customStatement('SELECT 1');
      await db.close();
    } catch (e) {
      AuditLogger.instance.error('DatabaseProvider._checkSchema', e);
      await db?.close();
      // ignore: avoid_print
      print('user.db schema mismatch detected, deleting...');
      await file.delete();
    }
  }

  AppDatabase get appDb {
    _ensureInitialized();
    return _appDb!;
  }

  AssetsDatabase get assetsDb {
    _ensureInitialized();
    return _assetsDb!;
  }

  CoursesDatabase get coursesDb {
    _ensureInitialized();
    return _coursesDb!;
  }

  Future<void> replaceAssetsDb(String newPath, {int newVersion = 0}) async {
    await _assetsDb?.close();
    final target = File('${_dbDirPath!}/assets.db');
    if (await target.exists()) await target.delete();
    await File(newPath).copy(target.path);
    _assetsDb = AssetsDatabase(NativeDatabase(target));
    _bumpVersion();
    if (newVersion > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_assets.db_version', newVersion);
    }
  }

  Future<void> replaceCoursesDb(String newPath, {int newVersion = 0}) async {
    await _coursesDb?.close();
    final target = File('${_dbDirPath!}/courses.db');
    if (await target.exists()) await target.delete();
    await File(newPath).copy(target.path);
    _coursesDb = CoursesDatabase(NativeDatabase(target));
    _bumpVersion();
    if (newVersion > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('cached_courses.db_version', newVersion);
    }
  }

  /// 替换 user.db（与 replaceAssetsDb / replaceLecturesDb 同构）
  Future<void> replaceUserDb(String newPath) async {
    await _appDb?.close();
    final target = File('${_dbDirPath!}/user.db');
    if (await target.exists()) await target.delete();
    await File(newPath).copy(target.path);
    _appDb = AppDatabase(NativeDatabase(target));
    await _appDb!.customStatement('PRAGMA journal_mode=WAL');
    await _ensurePreferenceSchema();
    _bumpVersion();
  }

  /// 确保 preference_filter 表有 knowledge_cards 和 question_types 列。
  /// 服务端 pull_user_db 生成的 user.db 可能缺失（旧版本 schema），
  /// 替换后补齐以防 INSERT 崩溃。
  Future<void> _ensurePreferenceSchema() async {
    if (_appDb == null) return;
    try {
      final cols = await (_appDb!.customSelect(
        "SELECT name FROM pragma_table_info('preference_filter')",
      )).get();
      final names = cols.map((r) => r.data['name'] as String).toSet();
      if (!names.contains('knowledge_cards')) {
        await _appDb!.customStatement(
          'ALTER TABLE preference_filter ADD COLUMN knowledge_cards TEXT',
        );
      }
      if (!names.contains('question_types')) {
        await _appDb!.customStatement(
          'ALTER TABLE preference_filter ADD COLUMN question_types TEXT',
        );
      }
    } catch (_) {
      // 表不存在则跳过，Drift 会在首次使用时按 schema 创建
    }
  }

  Future<void> clearUserDb() async {
    await _appDb?.close();
    final file = File('${_dbDirPath!}/user.db');
    if (await file.exists()) {
      await file.delete();
    }
    _appDb = AppDatabase(NativeDatabase(file));
    await _appDb!.customStatement('PRAGMA journal_mode=WAL');
    _bumpVersion();
  }

  /// ⚠️ 仅限测试使用！绝对不要在业务代码中调用。
  ///
  /// 用指定目录路径初始化三库，跳过 getApplicationSupportDirectory()
  /// 和 rootBundle 的默认资源复制。测试中请传入临时目录。
  ///
  /// 误传 /sdcard/ 等无权限路径会导致 App 崩溃。
  @visibleForTesting
  Future<void> reset() async {
    await _appDb?.close();
    await _assetsDb?.close();
    await _coursesDb?.close();
    _appDb = null;
    _assetsDb = null;
    _coursesDb = null;
    _initialized = false;
    _dbDirPath = null;
  }

  /// ⚠️ 仅限测试使用！在测试中用内存数据库替换 appDb 实例。
  @visibleForTesting
  void setAppDbForTesting(AppDatabase db) {
    _appDb = db;
    _initialized = true;
  }

  /// ⚠️ 仅限测试使用！在测试中用内存数据库替换 assetsDb 实例。
  @visibleForTesting
  void setAssetsDbForTesting(AssetsDatabase db) {
    _assetsDb = db;
    _initialized = true;
  }

  /// ⚠️ 仅限测试使用！在测试中用内存数据库替换 coursesDb 实例。
  @visibleForTesting
  void setCoursesDbForTesting(CoursesDatabase db) {
    _coursesDb = db;
    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('DatabaseProvider not initialized. Call init() first.');
    }
  }

  /// 配图目录路径
  String get imagesDir {
    _ensureInitialized();
    return _imagesDirPath!;
  }

  /// 替换配图：解压 tar.gz 到 images 目录
  Future<void> replaceImages(String tarPath) async {
    final bytes = await File(tarPath).readAsBytes();
    final archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));
    final dir = Directory(_imagesDirPath!);
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    for (final entry in archive) {
      if (entry.isFile) {
        await File('${dir.path}/${entry.name}')
            .writeAsBytes(entry.content as List<int>);
      }
    }
  }
}
