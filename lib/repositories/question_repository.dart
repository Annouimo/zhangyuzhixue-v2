import 'package:flutter/material.dart';

/// 题目相关：推荐、搜索、详情、概念标签
class QuestionRepository {
  /// 读取推荐题目列表（静默 mock）
  static Future<List<Map<String, dynamic>>> getRecommended() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {'id': 1, 'title': '2025 海淀一模 Q20', 'type': '解答题', 'course': '导数系统课', 'status': '进行中'},
      {'id': 2, 'title': '2025 东城一模 Q6', 'type': '解答题', 'course': '公益讲座', 'status': '未做'},
    ];
  }

  /// 读取题目详情（题干、公式、图表）（静默 mock）
  static Future<Map<String, dynamic>> getQuestionDetail(int questionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'id': questionId,
      'number': '第 3 题',
      'course': '导数第 1 讲课后练习',
      'stem': '在三角形 ABC 中，...（题目略）',
      'concept_tags': ['体积', '平面'],
      'difficulty': 6.6,
      'calculation': 5.2,
    };
  }

  /// 读取筛选条件选项（年份/地区/考试）（静默 mock）
  static Future<Map<String, dynamic>> getFilterOptions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'years': [2025, 2024, 2023],
      'regions': ['海淀', '东城', '西城', '朝阳'],
      'exam_types': ['一模', '二模', '期末', '高考'],
    };
  }

  /// 按条件搜索题目列表（静默 mock）
  static Future<List<Map<String, dynamic>>> searchQuestions({
    int? year, String? region, String? examType,
    double? minDifficulty, double? maxDifficulty,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {'id': 3, 'source': '2025 东城一模 第 1 题', 'difficulty': 0.3, 'calculation': 1.2, 'type': '选择题'},
      {'id': 4, 'source': '2025 东城一模 第 2 题', 'difficulty': 0.5, 'calculation': 1.8, 'type': '填空题'},
    ];
  }
}
