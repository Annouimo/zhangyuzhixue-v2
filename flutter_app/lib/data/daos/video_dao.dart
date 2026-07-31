import 'package:drift/drift.dart';
import 'package:shared/debug/audit_logger.dart';

import '../database/courses_database.dart' as db;
import '../database/database_provider.dart';

class VideoDao {
  VideoDao(this._provider);

  final DatabaseProvider _provider;
  db.CoursesDatabase get _db => _provider.coursesDb;

  Future<List<db.VideoCategoryRow>> getCategories() async {
    final query = _db.select(_db.videoCategories)
      ..orderBy([
        (row) => OrderingTerm(expression: row.sortOrder),
        (row) => OrderingTerm(expression: row.id),
      ]);
    final rows = await query.get();
    AuditLogger.instance.dao('VideoDao.getCategories', rows.length, {});
    return rows;
  }

  Future<List<db.VideoRow>> getVideos(int categoryId) async {
    final query = _db.select(_db.videos)
      ..where((row) => row.categoryId.equals(categoryId))
      ..orderBy([
        (row) => OrderingTerm(expression: row.sortOrder),
        (row) => OrderingTerm(expression: row.id),
      ]);
    return query.get();
  }

  Future<db.VideoRow?> getVideo(int id) {
    final query = _db.select(_db.videos)..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<db.VideoCategoryRow?> getCategory(int id) {
    final query = _db.select(_db.videoCategories)
      ..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<db.VideoDocumentLinkRow>> getLectureLinks(int videoId) async {
    final query = _db.select(_db.videoDocumentLinks)
      ..where((row) => row.videoId.equals(videoId))
      ..orderBy([
        (row) => OrderingTerm(expression: row.sortOrder),
        (row) => OrderingTerm(expression: row.id),
      ]);
    return query.get();
  }

  Future<List<db.VideoDocumentLinkRow>> getVideoLinks(int chapterId) async {
    final query = _db.select(_db.videoDocumentLinks)
      ..where((row) => row.chapterId.equals(chapterId))
      ..orderBy([
        (row) => OrderingTerm(expression: row.sortOrder),
        (row) => OrderingTerm(expression: row.id),
      ]);
    return query.get();
  }
}
