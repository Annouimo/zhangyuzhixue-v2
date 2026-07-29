import 'api_client.dart';

class NotificationApi {
  const NotificationApi(this._client);

  final ApiClient _client;

  Future<NotificationPageData> list({
    bool unreadOnly = false,
    String? cursor,
    int pageSize = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      if (unreadOnly) 'status': 'unread',
      'page_size': pageSize,
    };
    if (cursor case final value?) queryParameters['cursor'] = value;
    final response = await _client.dio.get(
      '/sync/notifications/',
      queryParameters: queryParameters,
    );
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return NotificationPageData(
      items: (data['items'] as List? ?? const [])
          .map(
            (item) => StudentNotification.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      nextCursor: data['next_cursor'] as String?,
    );
  }

  Future<int> unreadCount() async {
    final response = await _client.dio.get('/sync/notifications/unread-count/');
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return data['count'] as int? ?? 0;
  }

  Future<void> markRead(int id) async {
    await _client.dio.post('/sync/notifications/$id/read/');
  }

  Future<int> markAllRead() async {
    final response = await _client.dio.post('/sync/notifications/read-all/');
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return data['updated'] as int? ?? 0;
  }
}

class NotificationPageData {
  const NotificationPageData({required this.items, this.nextCursor});

  final List<StudentNotification> items;
  final String? nextCursor;
}

class StudentNotification {
  const StudentNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.priority,
    required this.actionType,
    required this.actionTarget,
    required this.payload,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final String category;
  final String title;
  final String content;
  final String priority;
  final String actionType;
  final String actionTarget;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  StudentNotification asRead() => StudentNotification(
    id: id,
    category: category,
    title: title,
    content: content,
    priority: priority,
    actionType: actionType,
    actionTarget: actionTarget,
    payload: payload,
    createdAt: createdAt,
    readAt: readAt ?? DateTime.now(),
  );

  factory StudentNotification.fromJson(Map<String, dynamic> json) =>
      StudentNotification(
        id: json['id'] as int,
        category: json['category'] as String? ?? 'system',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        priority: json['priority'] as String? ?? 'normal',
        actionType: json['action_type'] as String? ?? 'none',
        actionTarget: json['action_target'] as String? ?? '',
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
      );
}
