import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'assets_database.dart';
import 'courses_database.dart';

/// 双库生命周期管理（仅 assets + courses，无 appDb）
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

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    await _ensureDefaultDb(dir, 'assets.db');
    await _ensureDefaultDb(dir, 'courses.db');
    await _openAll(dir);
    _initialized = true;
  }

  /// 首次启动时从 bundle 复制默认数据库到文档目录
  Future<void> _ensureDefaultDb(Directory dir, String name) async {
    final file = File('${dir.path}/$name');
    if (!await file.exists()) {
      final data = await rootBundle.load('assets/db/$name');
      await file.writeAsBytes(data.buffer.asUint8List());
    }
  }

  Future<void> _openAll(Directory dir) async {
    _assetsDb = AssetsDatabase(LazyDatabase(() async {
      return NativeDatabase(File('${dir.path}/assets.db'));
    }));
    _coursesDb = CoursesDatabase(LazyDatabase(() async {
      return NativeDatabase(File('${dir.path}/courses.db'));
    }));
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
    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/assets.db');
    await File(newPath).copy(target.path);
    _assetsDb = AssetsDatabase(NativeDatabase(target));
  }

  Future<void> replaceCoursesDb(String newPath) async {
    await _coursesDb?.close();
    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/courses.db');
    await File(newPath).copy(target.path);
    _coursesDb = CoursesDatabase(NativeDatabase(target));
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('DatabaseProvider not initialized. Call init() first.');
    }
  }
}
