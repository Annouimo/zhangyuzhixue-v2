import 'package:flutter/material.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/data/api/notification_api.dart';
import 'package:flutter_app/domain/notification_repository.dart';
import 'package:flutter_app/pages/notifications/notification_center_page.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotificationRepository extends NotificationRepository {
  _FakeNotificationRepository(this.notifications)
    : super(NotificationApi(ApiClient()));

  List<StudentNotification> notifications;

  @override
  Future<NotificationPageData> list({
    bool unreadOnly = false,
    String? cursor,
  }) async => NotificationPageData(
    items: notifications
        .where((item) => !unreadOnly || item.isUnread)
        .toList(growable: false),
  );

  @override
  Future<void> markRead(int id) async {
    notifications = notifications
        .map((item) => item.id == id ? item.asRead() : item)
        .toList();
  }

  @override
  Future<int> markAllRead() async {
    final count = notifications.where((item) => item.isUnread).length;
    notifications = notifications.map((item) => item.asRead()).toList();
    return count;
  }
}

StudentNotification _notification({
  required int id,
  required String title,
  DateTime? readAt,
}) => StudentNotification(
  id: id,
  category: 'system',
  title: title,
  content: '通知正文',
  priority: 'normal',
  actionType: 'none',
  actionTarget: '',
  payload: const {},
  createdAt: DateTime(2026, 7, 29, 12),
  readAt: readAt,
);

void main() {
  testWidgets('shows notifications and filters unread items', (tester) async {
    final repository = _FakeNotificationRepository([
      _notification(id: 1, title: '未读通知'),
      _notification(id: 2, title: '已读通知', readAt: DateTime(2026, 7, 29)),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: NotificationCenterPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('未读通知'), findsOneWidget);
    expect(find.text('已读通知'), findsOneWidget);

    await tester.tap(find.text('未读'));
    await tester.pumpAndSettle();

    expect(find.text('未读通知'), findsOneWidget);
    expect(find.text('已读通知'), findsNothing);
  });

  testWidgets('marks all notifications as read', (tester) async {
    final repository = _FakeNotificationRepository([
      _notification(id: 1, title: '待处理通知'),
    ]);
    var unreadChanged = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationCenterPage(
          repository: repository,
          onUnreadChanged: () => unreadChanged++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('全部已读'));
    await tester.pumpAndSettle();

    expect(repository.notifications.single.isUnread, isFalse);
    expect(unreadChanged, 1);
  });
}
