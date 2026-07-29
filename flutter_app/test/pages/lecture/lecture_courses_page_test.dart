import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/domain/lecture_repository.dart';
import 'package:flutter_app/pages/lecture/lecture_courses_page.dart';
import 'package:flutter_app/pages/lecture/lecture_chapters_page.dart';
import '../../test_setup.dart';

/// Mock LectureRepository
class _MockLectureRepo implements LectureRepository {
  final List<Course> courses;
  _MockLectureRepo({this.courses = const []});

  @override
  Future<List<Course>> getCourses() async => courses;

  @override
  Future<ChapterList> getChapters(int courseId) async =>
      ChapterList(courseName: '', items: []);

  @override
  Future<LectureContent> getContent(int chapterId) async =>
      LectureContent(chapterId: chapterId, title: '', mdContent: '');

  @override
  LectureContentParsed parseContent(LectureContent content) =>
      LectureContentParsed(pages: []);

  @override
  void clearCache() {}
}

/// Mock that fails
class _FailingLectureRepo implements LectureRepository {
  @override
  Future<List<Course>> getCourses() async => throw Exception('加载失败');

  @override
  Future<ChapterList> getChapters(int courseId) async =>
      throw UnimplementedError();

  @override
  Future<LectureContent> getContent(int chapterId) async =>
      throw UnimplementedError();

  @override
  LectureContentParsed parseContent(LectureContent content) =>
      throw UnimplementedError();

  @override
  void clearCache() {}
}

void main() {
    setUp(() => setupTestHooks());
  group('LectureCoursesPage', () {
    testWidgets('shows loading indicator then courses list', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: LectureCoursesPage(
              lectureRepository: _MockLectureRepo(
                courses: [
                  const Course(id: 1, name: '代数', chapterCount: 5),
                  const Course(id: 2, name: '几何', chapterCount: 3),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('代数'), findsOneWidget);
      expect(find.textContaining('共 5 讲'), findsOneWidget);
      expect(find.text('几何'), findsOneWidget);
      expect(find.textContaining('共 3 讲'), findsOneWidget);
    });

    testWidgets('shows empty state when no courses', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: LectureCoursesPage(
              lectureRepository: _MockLectureRepo(courses: []),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂时没有讲义内容，后续会陆续上线'), findsOneWidget);
    });

    testWidgets('shows error and retry button on failure', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: LectureCoursesPage(
              lectureRepository: _FailingLectureRepo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('navigates to chapters page on course tap', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => LectureCoursesPage(
              lectureRepository: _MockLectureRepo(
                courses: [const Course(id: 1, name: '代数', chapterCount: 5)],
              ),
            ),
          ),
          GoRoute(
                      path: '/lecture/chapters',
                      builder: (_, state) {
              final courseId = int.tryParse(
                    state.uri.queryParameters['courseId'] ?? '',
                  ) ??
                  0;
              return LectureChaptersPage(
                courseId: courseId,
                lectureRepository: _MockLectureRepo(),
              );
            },
          ),
        ],
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('代数'));
      await tester.pumpAndSettle();

      // Should show the chapters page (which has empty state)
      expect(find.text('这门课程暂时没有章节内容'), findsOneWidget);
    });
  });
}
