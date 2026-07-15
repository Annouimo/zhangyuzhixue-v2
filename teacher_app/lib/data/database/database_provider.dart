import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';
import 'assets_database.dart';
import 'courses_database.dart';
import '../debug/audit_logger.dart';

/// 双库生命周期管理（教师端：assetsDb + coursesDb，无 userDb/积分）
class DatabaseProvider {
  DatabaseProvider._internal();
  static DatabaseProvider? _instance;
  factory DatabaseProvider() {
    _instance ??= DatabaseProvider._internal();
    return _instance!;
  }

  AssetsDatabase? _assetsDb;
  CoursesDatabase? _coursesDb;
  bool _initialized = false;
  String? _imagesDirPath;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationSupportDirectory();
    await _ensureDefaultDb(dir, 'assets.db');
    await _ensureDefaultDb(dir, 'courses.db');
    _imagesDirPath = '${dir.path}/images';
    _assetsDb = AssetsDatabase(LazyDatabase(() async {
      return NativeDatabase(File('${dir.path}/assets.db'));
    }));
    _coursesDb = CoursesDatabase(LazyDatabase(() async {
      return NativeDatabase(File('${dir.path}/courses.db'));
    }));
    _initialized = true;
  }

  Future<void> _ensureDefaultDb(Directory dir, String name) async {
    final file = File('${dir.path}/$name');
    if (!await file.exists()) {
      final data = await rootBundle.load('assets/db/$name');
      await file.writeAsBytes(data.buffer.asUint8List());
    }
  }

  AssetsDatabase get assetsDb {
    _ensureInitialized();
    return _assetsDb!;
  }

  CoursesDatabase get coursesDb {
    _ensureInitialized();
    return _coursesDb!;
  }

  Future<void> replaceAssetsDb(String newPath) async {
    await _assetsDb?.close();
    final target = File('${await _dbDirPath()}/assets.db');
    if (await target.exists()) await target.delete();
    await File(newPath).copy(target.path);
    _assetsDb = AssetsDatabase(NativeDatabase(target));
  }

  Future<void> replaceCoursesDb(String newPath) async {
    await _coursesDb?.close();
    final target = File('${await _dbDirPath()}/courses.db');
    if (await target.exists()) await target.delete();
    await File(newPath).copy(target.path);
    _coursesDb = CoursesDatabase(NativeDatabase(target));
  }

  /// 配图目录路径
  String get imagesDir {
    _ensureInitialized();
    try { AuditLogger.instance.page('DatabaseProvider', {'imagesDir': _imagesDirPath!}); } catch (_) {}
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

  Future<String> _dbDirPath() async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('DatabaseProvider not initialized. Call init() first.');
    }
  }
}
