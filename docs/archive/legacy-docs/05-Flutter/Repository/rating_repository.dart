/// 章鱼智学 — RatingRepository
/// data-db: rating.*
/// 对应页面：solve.html(评分弹层)

class Rating {
  final double? userDifficulty;
  final double? userCalculation;
  final double? userElegance;
  final double algorithmDifficulty;
  final double algorithmCalculation;

  const Rating({
    this.userDifficulty,
    this.userCalculation,
    this.userElegance,
    required this.algorithmDifficulty,
    required this.algorithmCalculation,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
        userDifficulty: json['user']?['difficulty'] != null
            ? (json['user']['difficulty'] as num).toDouble()
            : null,
        userCalculation: json['user']?['calculation'] != null
            ? (json['user']['calculation'] as num).toDouble()
            : null,
        userElegance: json['user']?['elegance'] != null
            ? (json['user']['elegance'] as num).toDouble()
            : null,
        algorithmDifficulty:
            (json['algorithm']['difficulty'] as num).toDouble(),
        algorithmCalculation:
            (json['algorithm']['calculation'] as num).toDouble(),
      );
}

class RatingRepository {
  /// GET /api/questions/{questionId}/rating/
  Future<Rating> getRating(int questionId) async {
    throw UnimplementedError('RatingRepository.getRating');
  }

  /// POST /api/questions/{questionId}/rating/
  Future<void> submitRating({
    required int questionId,
    required double difficulty,
    required double calculation,
    required double elegance,
  }) async {
    throw UnimplementedError('RatingRepository.submitRating');
  }
}
