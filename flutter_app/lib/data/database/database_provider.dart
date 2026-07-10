import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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
    await _openAll(dir);
    _initialized = true;
  }

  @visibleForTesting
  Future<void> initWithPath(String dirPath) async {
    if (_initialized) return;
    _dbDirPath = dirPath;
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
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

  Future<void> clearUserDb() async {
    await _appDb?.close();
    final file = File('${_dbDirPath!}/user.db');
    if (await file.exists()) {
      await file.delete();
    }
    _appDb = AppDatabase(NativeDatabase(file));
    await _appDb!.customStatement('PRAGMA journal_mode=WAL');
  }

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
