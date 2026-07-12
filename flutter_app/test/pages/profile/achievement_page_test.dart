import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/domain/achievement_repository.dart';
import 'package:flutter_app/pages/profile/achievement_page.dart';
import '../../test_setup.dart';

class _MockAchieveRepo implements AchievementRepository {
  @override Future<AchievementSummary> getSummary() async => const AchievementSummary(unlockedCount: 1, totalCount: 5);
  @override Future<int> unlockedCount() async => 1;
  @override Future<List<AchievementCategory>> getCategories() async => [
    AchievementCategory(label: '基础成就', list: [
      AchievementItem(iconEmoji: '🎯', name: '初次练习', description: '完成第一道题', status: 'unlocked',
        unlockedAt: '2025-01-01', progressPercent: 100, progress: 1, threshold: 1),
      AchievementItem(iconEmoji: '🔥', name: '持续学习', description: '连续7天', status: 'in_progress',
        progressPercent: 42, progress: 3, threshold: 7),
    ]),
  ];
}

void main() {
    setUp(() => setupTestHooks());
  group('AchievementPage', () {
    testWidgets('loads and displays categories from repo', (tester) async {
      await tester.pumpWidget(MaterialApp(home: AchievementPage(achievementRepository: _MockAchieveRepo())));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('基础成就'), findsOneWidget);
      expect(find.text('初次练习'), findsOneWidget);
      expect(find.text('持续学习'), findsOneWidget);
      expect(find.text('✅ 已解锁'), findsOneWidget);
      expect(find.text('3/7'), findsOneWidget);
    });
  });
}
