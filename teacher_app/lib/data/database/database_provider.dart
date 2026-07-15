import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'assets_database.dart';
import 'courses_database.dart';

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
    return _imagesDirPath!;
  }

  /// 替换配图：解压 tar.gz 到 images 目录
  Future<void> replaceImages(String tarPath) async {
    final bytes = await File(tarPath).readAsBytes();
    // gzip decompress
    final raw = gzip.decode(bytes);
    final dir = Directory(_imagesDirPath!);
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);

    int pos = 0;
    while (pos + 512 <= raw.length) {
      // Check for end-of-archive (512 zero bytes)
      final header = raw.sublist(pos, pos + 512);
      if (header.every((b) => b == 0)) break;

      // Parse filename (bytes 0-99, null-terminated)
      final nameEnd = header.indexOf(0);
      final name = nameEnd > 0
          ? String.fromCharCodes(header.sublist(0, nameEnd))
          : '';
      if (name.isEmpty) { pos += 512; continue; }

      // Parse size (bytes 124-135, octal string)
      final sizeStr = String.fromCharCodes(
          header.sublist(124, 136).takeWhile((b) => b != 0 && b != 32));
      final size = int.tryParse(sizeStr, radix: 8) ?? 0;

      pos += 512; // skip header
      if (size > 0) {
        // Skip leading '/' in name (tar stores './' or relative paths)
        final cleanName = name.startsWith('./') ? name.substring(2) : name;
        await File('${dir.path}/$cleanName').writeAsBytes(
            raw.sublist(pos, pos + size));
        pos += size;
        // Pad to 512-byte boundary
        if (size % 512 != 0) pos += 512 - (size % 512);
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
