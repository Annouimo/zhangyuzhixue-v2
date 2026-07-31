import 'package:flutter/material.dart';
import 'package:flutter_app/domain/video_repository.dart';
import 'package:flutter_app/pages/video/video_catalog_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_setup.dart';

const _categories = [
  VideoCategorySection(
    id: 1,
    name: '系列系统课程',
    description: '说明',
    videos: [
      VideoSummary(
        id: 1,
        title: '没有封面的视频',
        description: '',
        coverUrl: '',
        platformName: 'B站',
      ),
    ],
  ),
  VideoCategorySection(id: 2, name: '专题深度解析', description: '', videos: []),
  VideoCategorySection(id: 3, name: '学习经验分享', description: '', videos: []),
  VideoCategorySection(id: 4, name: '学术交流', description: '', videos: []),
];

void main() {
  setUp(setupTestHooks);

  Future<void> pumpCatalog(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: VideoCatalogPage(catalogLoader: () async => _categories),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('uses wrapping category chips on compact screens', (tester) async {
    await pumpCatalog(tester, const Size(390, 844));

    expect(find.byKey(const ValueKey('video-category-wrap')), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(4));
    expect(find.byType(SegmentedButton<int>), findsNothing);
  });

  testWidgets('keeps segmented categories on wider screens', (tester) async {
    await pumpCatalog(tester, const Size(900, 844));

    expect(
      find.byKey(const ValueKey('video-category-segmented')),
      findsOneWidget,
    );
    expect(find.byType(SegmentedButton<int>), findsOneWidget);
  });

  testWidgets('omits the large media area when the cover is empty', (
    tester,
  ) async {
    await pumpCatalog(tester, const Size(390, 844));

    expect(find.byKey(const ValueKey('video-cover')), findsNothing);
    expect(find.text('没有封面的视频'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
  });
}
