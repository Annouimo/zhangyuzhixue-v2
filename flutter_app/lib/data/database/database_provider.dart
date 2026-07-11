import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../debug/audit_logger.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../database/assets_database.dart';
import '../database/lectures_database.dart';
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
  LecturesDatabase? _lecturesDb;
  bool _initialized = false;
  String? _dbDirPath;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _dbDirPath = dir.path;
    await _ensureDefaultDb(dir, 'assets.db');
    await _ensureDefaultDb(dir, 'lectures.db');
    await _ensureUserDbSchema(dir);
    await _openAll(dir);
    _initialized = true;
  }

  /// ⚠️ 仅限测试使用！绝对不要在业务代码中调用。
  ///
  /// 用指定目录路径初始化三库，跳过 getApplicationDocumentsDirectory()
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
    _lecturesDb = LecturesDatabase(LazyDatabase(() async {
      return NativeDatabase(File('${dir.path}/lectures.db'));
    }));
    _appDb = AppDatabase(LazyDatabase(() async {
      return NativeDatabase(File('${dir.path}/user.db'));
    }));
    await _appDb!.customStatement('PRAGMA journal_mode=WAL');
  }

  Future<void> _ensureDefaultDb(Directory dir, String name) async {
    final file = File('${dir.path}/$name');
    if (!await file.exists()) {
      final data = await rootBundle.load('assets/db/$name');
      await file.writeAsBytes(data.buffer.asUint8List());
    }
  }

  /// 检测 user.db 表结构是否匹配当前 schemaVersion。
  /// 旧版 schema（表名不匹配）→ 删掉重建，数据由登录时全量拉取恢复。
  Future<void> _ensureUserDbSchema(Directory dir) async {
    final file = File('${dir.path}/user.db');
    if (!await file.exists()) return;
    NativeDatabase? conn;
    try {
      conn = NativeDatabase(file);
      await conn.runCustom('SELECT 1 FROM user_profile LIMIT 1');
      await conn.close();
    } catch (e) {
      AuditLogger.instance.error('DatabaseProvider._checkSchema', e);
      await conn?.close();
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

  LecturesDatabase get lecturesDb {
    _ensureInitialized();
    return _lecturesDb!;
  }

  Future<void> replaceAssetsDb(String newPath) async {
    await _assetsDb?.close();
    final target = File('${_dbDirPath!}/assets.db');
    await File(newPath).copy(target.path);
    _assetsDb = AssetsDatabase(NativeDatabase(target));
  }

  Future<void> replaceLecturesDb(String newPath) async {
    await _lecturesDb?.close();
    final target = File('${_dbDirPath!}/lectures.db');
    await File(newPath).copy(target.path);
    _lecturesDb = LecturesDatabase(NativeDatabase(target));
  }

  /// 替换 user.db（与 replaceAssetsDb / replaceLecturesDb 同构）
  Future<void> replaceUserDb(String newPath) async {
    await _appDb?.close();
    final target = File('${_dbDirPath!}/user.db');
    await File(newPath).copy(target.path);
    _appDb = AppDatabase(NativeDatabase(target));
    await _appDb!.customStatement('PRAGMA journal_mode=WAL');
  }

  Future<void> clearUserDb() async {
    await _appDb?.close();
    final file = File('${_dbDirPath!}/user.db');
    if (await file.exists()) {
      await file.delete();
    }
    _appDb = AppDatabase(NativeDatabase(file));
    await _appDb!.customStatement('PRAGMA journal_mode=WAL');
  }

  /// ⚠️ 仅限测试使用！绝对不要在业务代码中调用。
  ///
  /// 用指定目录路径初始化三库，跳过 getApplicationDocumentsDirectory()
  /// 和 rootBundle 的默认资源复制。测试中请传入临时目录。
  ///
  /// 误传 /sdcard/ 等无权限路径会导致 App 崩溃。
  @visibleForTesting
  Future<void> reset() async {
    await _appDb?.close();
    await _assetsDb?.close();
    await _lecturesDb?.close();
    _appDb = null;
    _assetsDb = null;
    _lecturesDb = null;
    _initialized = false;
    _dbDirPath = null;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('DatabaseProvider not initialized. Call init() first.');
    }
  }
}
