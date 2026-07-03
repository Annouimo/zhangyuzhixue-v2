/// 章鱼智学 — QuestionRepository
/// 对应页面：solve.html, recommend.html, paper_builder.html
/// data-db: question.getDetail.*, recommend.*, question.search.*, question.filter.*

class QuestionDetail {
  final int id;
  final String title;
  final String number;
  final String assignName;
  final String stem;
  final List<String> conceptTags;
  final String congratsText;

  const QuestionDetail({
    required this.id,
    required this.title,
    required this.number,
    required this.assignName,
    required this.stem,
    required this.conceptTags,
    required this.congratsText,
  });

  factory QuestionDetail.fromJson(Map<String, dynamic> json) => QuestionDetail(
        id: json['id'] as int,
        title: json['title'] as String,
        number: json['number'] as String,
        assignName: json['assign_name'] as String,
        stem: json['stem'] as String,
        conceptTags: (json['concept_tags'] as List).cast<String>(),
        congratsText: json['congrats_text'] as String,
      );
}

class RecommendedQuestion {
  final int id;
  final String title;
  final String questionType;
  final double difficulty;
  final String status;

  const RecommendedQuestion({
    required this.id,
    required this.title,
    required this.questionType,
    required this.difficulty,
    required this.status,
  });

  factory RecommendedQuestion.fromJson(Map<String, dynamic> json) =>
      RecommendedQuestion(
        id: json['id'] as int,
        title: json['title'] as String,
        questionType: json['question_type'] as String,
        difficulty: (json['difficulty'] as num).toDouble(),
        status: json['status'] as String,
      );
}

class SearchResult {
  final int totalCount;
  final List<SearchQuestion> items;

  const SearchResult({required this.totalCount, required this.items});

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        totalCount: json['total_count'] as int,
        items: (json['items'] as List)
            .map((e) => SearchQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SearchQuestion {
  final int id;
  final String title;
  final String meta;
  final double difficulty;
  final double calculation;

  const SearchQuestion({
    required this.id,
    required this.title,
    required this.meta,
    required this.difficulty,
    required this.calculation,
  });

  factory SearchQuestion.fromJson(Map<String, dynamic> json) => SearchQuestion(
        id: json['id'] as int,
        title: json['title'] as String,
        meta: json['meta'] as String,
        difficulty: (json['difficulty'] as num).toDouble(),
        calculation: (json['calculation'] as num).toDouble(),
      );
}

class FilterOptions {
  final List<String> years;
  final List<String> regions;
  final List<String> conceptTags;
  final List<String> knowledgeCards;

  const FilterOptions({
    required this.years,
    required this.regions,
    required this.conceptTags,
    required this.knowledgeCards,
  });

  factory FilterOptions.fromJson(Map<String, dynamic> json) => FilterOptions(
        years: (json['years'] as List).cast<String>(),
        regions: (json['regions'] as List).cast<String>(),
        conceptTags: (json['concept_tags'] as List).cast<String>(),
        knowledgeCards: (json['knowledge_cards'] as List).cast<String>(),
      );
}

class SearchFilters {
  final List<String> years;
  final List<String> regions;
  final List<String> conceptTags;
  final List<String> knowledgeCards;
  final double? diffMin;
  final double? diffMax;
  final double? calcMin;
  final double? calcMax;

  const SearchFilters({
    required this.years,
    required this.regions,
    required this.conceptTags,
    required this.knowledgeCards,
    this.diffMin,
    this.diffMax,
    this.calcMin,
    this.calcMax,
  });

  Map<String, dynamic> toJson() => {
        'years': years,
        'regions': regions,
        'concept_tags': conceptTags,
        'knowledge_cards': knowledgeCards,
        'diff_min': diffMin,
        'diff_max': diffMax,
        'calc_min': calcMin,
        'calc_max': calcMax,
      };
}

class QuestionRepository {
  /// GET /api/questions/{id}/
  static Future<QuestionDetail> getQuestionDetail(int id) async {
    throw UnimplementedError('QuestionRepository.getQuestionDetail');
  }

  /// GET /api/questions/recommended/
  static Future<List<RecommendedQuestion>> getRecommended() async {
    throw UnimplementedError('QuestionRepository.getRecommended');
  }

  /// POST /api/questions/{id}/start-solve/
  static Future<void> startSolve(int questionId) async {
    throw UnimplementedError('QuestionRepository.startSolve');
  }

  /// GET /api/questions/{id}/next/
  static Future<int?> nextQuestion(int currentId) async {
    throw UnimplementedError('QuestionRepository.nextQuestion');
  }

  /// GET /api/questions/search?{filters}
  static Future<SearchResult> searchQuestions(SearchFilters filters) async {
    throw UnimplementedError('QuestionRepository.searchQuestions');
  }

  /// GET /api/questions/filter-options/
  static Future<FilterOptions> getFilterOptions() async {
    throw UnimplementedError('QuestionRepository.getFilterOptions');
  }
}
