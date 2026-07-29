import 'api_client.dart';

class ContributionApi {
  const ContributionApi(this._client);
  final ApiClient _client;

  Future<Map<String, dynamic>> getConfig() async {
    final response = await _client.dio.get(
      '/interactions/contributions/config/',
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> list() async {
    final response = await _client.dio.get('/interactions/contributions/');
    return (response.data['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getDetail(int id) async {
    final response = await _client.dio.get('/interactions/contributions/$id/');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<Map<String, dynamic>> getQuestionContext(int questionId) async {
    final response = await _client.dio.get(
      '/interactions/contributions/question/$questionId/context/',
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final response = await _client.dio.post(
      '/interactions/contributions/',
      data: body,
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<Map<String, dynamic>> resubmit(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.dio.post(
      '/interactions/contributions/$id/resubmit/',
      data: body,
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<void> withdraw(int id) async {
    await _client.dio.post('/interactions/contributions/$id/withdraw/');
  }
}

class ContributionConfig {
  const ContributionConfig({
    required this.aiPrompt,
    required this.latexEditorUrl,
    required this.tags,
  });

  final String aiPrompt;
  final String latexEditorUrl;
  final List<ContributionTag> tags;

  factory ContributionConfig.fromJson(
    Map<String, dynamic> json,
  ) => ContributionConfig(
    aiPrompt: json['ai_prompt'] as String? ?? '',
    latexEditorUrl:
        json['latex_editor_url'] as String? ?? 'https://www.latexlive.com/',
    tags: (json['tags'] as List? ?? const [])
        .map(
          (item) =>
              ContributionTag.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );
}

class ContributionTag {
  const ContributionTag({required this.id, required this.name, this.parentId});
  final int id;
  final String name;
  final int? parentId;

  factory ContributionTag.fromJson(Map<String, dynamic> json) =>
      ContributionTag(
        id: json['id'] as int,
        name: json['name'] as String,
        parentId: json['parent_id'] as int?,
      );
}
