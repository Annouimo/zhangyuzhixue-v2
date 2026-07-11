import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/lecture_repository.dart';
import 'package:flutter_app/pages/lecture/lecture_content_page.dart';
import 'package:flutter_app/pages/lecture/lecture_pager_widget.dart';

/// Mock LectureRepository for content
class _MockContentRepo implements LectureRepository {
  final LectureContent? content;
  _MockContentRepo({this.content});

  @override
  Future<List<Course>> getCourses() async => throw UnimplementedError();

  @override
  Future<ChapterList> getChapters(int courseId) async =>
      throw UnimplementedError();

  @override
  Future<LectureContent> getContent(int chapterId) async =>
      content ?? LectureContent(chapterId: chapterId, title: '', mdContent: '');

  @override
  LectureContentParsed parseContent(LectureContent content) {
    final pages = content.mdContent
        .split('<!-- pagebreak -->')
        .where((p) => p.trim().isNotEmpty)
        .map((pageMd) {
      final blocks = pageMd
          .split('<!-- reveal -->')
          .map((b) => b.trim())
          .where((b) => b.isNotEmpty)
          .toList();
      return LecturePage(blocks: blocks);
    }).toList();
    return LectureContentParsed(pages: pages);
  }

  @override
  void clearCache() {}
}

/// Mock that fails
class _FailingContentRepo implements LectureRepository {
  @override
  Future<List<Course>> getCourses() async => throw UnimplementedError();

  @override
  Future<ChapterList> getChapters(int courseId) async =>
      throw UnimplementedError();

  @override
  Future<LectureContent> getContent(int chapterId) async =>
      throw Exception('无法加载讲义');

  @override
  LectureContentParsed parseContent(LectureContent content) =>
      throw UnimplementedError();

  @override
  void clearCache() {}
}

Widget _wrapApp(Widget child) {
  return MediaQuery(
    data: const MediaQueryData(size: Size(400, 800)),
    child: MaterialApp(home: child),
  );
}

void main() {
  group('LecturePagerWidget', () {
    testWidgets('shows page info and navigation buttons', (tester) async {
      await tester.pumpWidget(_wrapApp(
        Scaffold(
          body: LecturePagerWidget(
            currentPage: 1,
            totalPages: 3,
            revealedCount: 0,
            totalBlocks: 1,
            onPrev: () {},
            onNext: () {},
          ),
        ),
      ));

      expect(find.textContaining('第 1 / 3'), findsOneWidget);
      expect(find.textContaining('展开 0 / 1'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('calls onPrev and onNext when tapped', (tester) async {
      int prevCalls = 0;
      int nextCalls = 0;

      await tester.pumpWidget(_wrapApp(
        Scaffold(
          body: LecturePagerWidget(
            currentPage: 2,
            totalPages: 5,
            revealedCount: 1,
            totalBlocks: 3,
            onPrev: () => prevCalls++,
            onNext: () => nextCalls++,
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(prevCalls, 1);

      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(nextCalls, 1);
    });

    testWidgets('prev disabled on first page with no revealed blocks', (tester) async {
      await tester.pumpWidget(_wrapApp(
        Scaffold(
          body: LecturePagerWidget(
            currentPage: 1,
            totalPages: 3,
            revealedCount: 0,
            totalBlocks: 1,
            onPrev: () {},
            onNext: () {},
          ),
        ),
      ));

      // ◀ icon should be grey (disabled)
      final prevIcon = tester.widget<Icon>(
        find.byIcon(Icons.chevron_left).first,
      );
      expect(prevIcon.color, Colors.grey[400]);
    });

    testWidgets('next disabled on last page with all revealed', (tester) async {
      await tester.pumpWidget(_wrapApp(
        Scaffold(
          body: LecturePagerWidget(
            currentPage: 3,
            totalPages: 3,
            revealedCount: 2,
            totalBlocks: 3,
            onPrev: () {},
            onNext: () {},
          ),
        ),
      ));

      final nextIcon = tester.widget<Icon>(
        find.byIcon(Icons.chevron_right).first,
      );
      expect(nextIcon.color, Colors.grey[400]);
    });
  });

  group('LectureContentPage', () {
    testWidgets('shows loading then content and pager', (tester) async {
      await tester.pumpWidget(_wrapApp(
        LectureContentPage(
          chapterId: 1,
          lectureRepository: _MockContentRepo(
            content: LectureContent(
              chapterId: 1,
              title: '第1讲 函数',
              mdContent: '第一段\n<!-- pagebreak -->\n第二页',
            ),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('第1讲 函数'), findsOneWidget);
      expect(find.textContaining('第一段'), findsOneWidget);
      // Pager visible
      expect(find.textContaining('第 1 / 2'), findsOneWidget);
    });

    testWidgets('page navigation shows correct pager state', (tester) async {
      await tester.pumpWidget(_wrapApp(
        LectureContentPage(
          chapterId: 1,
          lectureRepository: _MockContentRepo(
            content: LectureContent(
              chapterId: 1,
              title: '测试',
              mdContent: '第一页\n<!-- pagebreak -->\n第二页',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Pager shows page 1
      expect(find.textContaining('第 1 / 2'), findsOneWidget);
    });

    testWidgets('reveal and collapse blocks', (tester) async {
      await tester.pumpWidget(_wrapApp(
        LectureContentPage(
          chapterId: 1,
          lectureRepository: _MockContentRepo(
            content: LectureContent(
              chapterId: 1,
              title: '测试',
              mdContent: '第一块\n<!-- reveal -->\n第二块（隐藏）',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // blocks[0] visible
      expect(find.textContaining('第一块'), findsOneWidget);

      // Expand blocks[1]
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // blocks[1] now visible
      expect(find.textContaining('第二块（隐藏）'), findsOneWidget);
      // Pager shows expanded state
      expect(find.textContaining('展开 1 / 2'), findsOneWidget);

      // Collapse back
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Back to expanded 0
      expect(find.textContaining('展开 0 / 2'), findsOneWidget);
    });

    testWidgets('shows error state on load failure', (tester) async {
      await tester.pumpWidget(_wrapApp(
        LectureContentPage(
          chapterId: 999,
          lectureRepository: _FailingContentRepo(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('multiple blocks reveal and collapse sequentially', (tester) async {
      await tester.pumpWidget(_wrapApp(
        LectureContentPage(
          chapterId: 1,
          lectureRepository: _MockContentRepo(
            content: LectureContent(
              chapterId: 1,
              title: '多块',
              mdContent: '块0\n<!-- reveal -->\n块1\n<!-- reveal -->\n块2\n<!-- reveal -->\n块3',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Start: expand 0/4
      expect(find.textContaining('展开 0 / 4'), findsOneWidget);

      // Reveal 1→2→3 sequentially
      for (int i = 1; i <= 3; i++) {
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();
        expect(find.textContaining('展开 $i / 4'), findsOneWidget);
      }

      // Collapse 3→2→1 sequentially
      for (int i = 3; i >= 1; i--) {
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();
        final expected = i - 1;
        expect(find.textContaining('展开 $expected / 4'), findsOneWidget);
      }
    });
  });
}
