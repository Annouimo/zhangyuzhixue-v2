import 'package:flutter/material.dart';

/// 评分相关：提交评分、读取评分
class RatingRepository {
  /// 读取题目评分（静默 mock）
  static Future<Map<String, dynamic>> getRating(int questionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'user_difficulty': 6,
      'user_calculation': 6,
      'user_elegance': 6,
      'algorithm_difficulty': 6.6,
      'algorithm_calculation': 6.6,
    };
  }

  /// 提交评分（写入操作，显示 Toast）
  static Future<void> submitRating(
    BuildContext context,
    int questionId, {
    required int difficulty,
    required int calculation,
    required int elegance,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在进行提交评分操作，需要写入评分数据')),
    );
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
