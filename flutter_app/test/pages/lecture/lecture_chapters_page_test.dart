import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/domain/lecture_repository.dart';
import 'package:flutter_app/pages/lecture/lecture_chapters_page.dart';

/// Mock LectureRepository
class _MockChaptersRepo implements LectureRepository {
  final ChapterList? chapterList;
  _MockChaptersRepo({this.chapterList});

  @override
  Future<List<Course>> getCourses() async => throw UnimplementedError();

  @override
  Future<ChapterList> getChapters(int courseId) async =>
      chapterList ?? ChapterList(courseName: '', items: []);

  @override
  Future<LectureContent> getContent(int chapterId) async =>
      LectureContent(chapterId: chapterId, title: '', mdContent: '');

  @override
  LectureContentParsed parseContent(LectureContent content) =>
      LectureContentParsed(pages: []);

  @override
  void clearCache() {}
}

void main() {
  group('LectureChaptersPage', () {
    testWidgets('shows loading then chapters list', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: LectureChaptersPage(
              courseId: 1,
              lectureRepository: _MockChaptersRepo(
                chapterList: ChapterList(
                  courseName: '代数',
                  items: [
                    const Chapter(id: 1, title: '第1讲 函数', pageCount: 0),
                    const Chapter(id: 2, title: '第2讲 方程', pageCount: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('代数'), findsOneWidget);
      expect(find.text('第1讲 函数'), findsOneWidget);
      expect(find.text('第2讲 方程'), findsOneWidget);
    });

    testWidgets('shows empty state when no chapters', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: LectureChaptersPage(
              courseId: 1,
              lectureRepository: _MockChaptersRepo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂无章节'), findsOneWidget);
    });

    testWidgets('navigates to content page on chapter tap', (tester) async {
      final router = GoRouter(
        initialLocation: '/lecture/chapters?courseId=1',
        routes: [
          GoRoute(
            path: '/lecture/chapters',
            builder: (_, state) {
              final courseId = int.tryParse(
                    state.uri.queryParameters['courseId'] ?? '',
                  ) ??
                  0;
              return LectureChaptersPage(
                courseId: courseId,
                lectureRepository: _MockChaptersRepo(
                  chapterList: ChapterList(
                    courseName: '代数',
                    items: [
                      const Chapter(id: 10, title: '第1讲 函数', pageCount: 0),
                    ],
                  ),
                ),
              );
            },
          ),
          GoRoute(
            path: '/lecture/content',
            builder: (_, state) {
              return const Scaffold(
                body: Center(child: Text('ContentPage')),
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

      await tester.tap(find.text('第1讲 函数'));
      await tester.pumpAndSettle();

      expect(find.text('ContentPage'), findsOneWidget);
    });
  });
}
