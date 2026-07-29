import '../data/api/notification_api.dart';

class NotificationRepository {
  const NotificationRepository(this._api);

  final NotificationApi _api;

  Future<NotificationPageData> list({
    bool unreadOnly = false,
    String? cursor,
  }) => _api.list(unreadOnly: unreadOnly, cursor: cursor);

  Future<int> unreadCount() => _api.unreadCount();

  Future<void> markRead(int id) => _api.markRead(id);

  Future<int> markAllRead() => _api.markAllRead();
}
