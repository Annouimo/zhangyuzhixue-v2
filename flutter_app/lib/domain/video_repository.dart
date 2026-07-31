import '../data/daos/lecture_dao.dart';
import '../data/daos/video_dao.dart';
import '../data/database/courses_database.dart' as db;

class VideoSummary {
  const VideoSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.platformName,
    this.publishedAt,
  });

  final int id;
  final String title;
  final String description;
  final String coverUrl;
  final String platformName;
  final String? publishedAt;
}

class VideoCategorySection {
  const VideoCategorySection({
    required this.id,
    required this.name,
    required this.description,
    required this.videos,
  });

  final int id;
  final String name;
  final String description;
  final List<VideoSummary> videos;
}

class RelatedLecture {
  const RelatedLecture({
    required this.chapterId,
    required this.title,
    required this.courseName,
    required this.relationLabel,
  });

  final int chapterId;
  final String title;
  final String courseName;
  final String relationLabel;
}

class RelatedVideo {
  const RelatedVideo({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.relationLabel,
  });

  final int id;
  final String title;
  final String categoryName;
  final String relationLabel;
}

class VideoDetail extends VideoSummary {
  const VideoDetail({
    required super.id,
    required super.title,
    required super.description,
    required super.coverUrl,
    required super.platformName,
    required super.publishedAt,
    required this.videoUrl,
    required this.categoryName,
    required this.relatedLectures,
  });

  final String videoUrl;
  final String categoryName;
  final List<RelatedLecture> relatedLectures;
}

class VideoRepository {
  VideoRepository(this._videoDao, this._lectureDao);

  final VideoDao _videoDao;
  final LectureDao _lectureDao;

  Future<List<VideoCategorySection>> getCatalog() async {
    final categories = await _videoDao.getCategories();
    return Future.wait(categories.map((category) async {
      final videos = await _videoDao.getVideos(category.id);
      return VideoCategorySection(
        id: category.id,
        name: category.name,
        description: category.description,
        videos: videos.map(_summaryFromRow).toList(),
      );
    }));
  }

  Future<VideoDetail> getDetail(int videoId) async {
    final video = await _videoDao.getVideo(videoId);
    if (video == null) throw StateError('Video not found: $videoId');
    final category = await _videoDao.getCategory(video.categoryId);
    final links = await _videoDao.getLectureLinks(videoId);
    final lectures = <RelatedLecture>[];
    for (final link in links) {
      final chapter = await _lectureDao.getChapterById(link.chapterId);
      if (chapter == null) continue;
      final course = await _lectureDao.getCourseById(chapter.courseId);
      lectures.add(RelatedLecture(
        chapterId: chapter.id,
        title: chapter.title,
        courseName: course?.name ?? '',
        relationLabel: link.relationLabel,
      ));
    }
    return VideoDetail(
      id: video.id,
      title: video.title,
      description: video.description,
      coverUrl: video.coverUrl,
      platformName: video.platformName,
      publishedAt: video.publishedAt,
      videoUrl: video.videoUrl,
      categoryName: category?.name ?? '',
      relatedLectures: lectures,
    );
  }

  Future<List<RelatedVideo>> getRelatedVideos(int chapterId) async {
    final links = await _videoDao.getVideoLinks(chapterId);
    final videos = <RelatedVideo>[];
    for (final link in links) {
      final video = await _videoDao.getVideo(link.videoId);
      if (video == null) continue;
      final category = await _videoDao.getCategory(video.categoryId);
      videos.add(RelatedVideo(
        id: video.id,
        title: video.title,
        categoryName: category?.name ?? '',
        relationLabel: link.relationLabel,
      ));
    }
    return videos;
  }

  VideoSummary _summaryFromRow(db.VideoRow row) => VideoSummary(
        id: row.id,
        title: row.title,
        description: row.description,
        coverUrl: row.coverUrl,
        platformName: row.platformName,
        publishedAt: row.publishedAt,
      );
}
