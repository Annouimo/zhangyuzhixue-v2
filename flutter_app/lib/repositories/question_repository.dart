import 'package:flutter/material.dart';

/// 题目相关：推荐、搜索、详情、概念标签
class QuestionRepository {
  /// 读取推荐题目列表（静默 mock）
  static Future<List<Map<String, dynamic>>> getRecommended() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {'id': 1, 'title': '2025 海淀一模 Q20', 'type': '解答题', 'course': '导数系统课', 'status': '进行中'},
      {'id': 2, 'title': '2025 东城一模 Q6', 'type': '解答题', 'course': '公益讲座', 'status': '未做'},
      {'id': 3, 'title': '2025 西城一模 Q15', 'type': '填空题', 'course': '导数系统课', 'status': '未做'},
      {'id': 4, 'title': '2025 朝阳一模 Q8', 'type': '选择题', 'course': '公益讲座', 'status': '已完成'},
      {'id': 5, 'title': '2025 丰台一模 Q20', 'type': '解答题', 'course': '导数系统课', 'status': '未做'},
    ];
  }

  /// 读取题目详情（题干、公式、图表）（静默 mock）
  static Future<Map<String, dynamic>> getQuestionDetail(int questionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'id': questionId,
      'number': '第 3 题',
      'course': '导数第 1 讲课后练习',
      'stem': '在三角形 ABC 中，内角 A, B, C 的对边分别为 a, b, c，\n已知 a = 2, b = 3, cos C = 1/4。\n\n(1) 求 c 的值;\n(2) 求 sin 2C 的值。',
      'concept_tags': ['余弦定理', '正弦定理', '二倍角公式'],
      'difficulty': 6.6,
      'calculation': 5.2,
    };
  }

  /// 读取筛选条件选项（年份/地区/考试）（静默 mock）
  static Future<Map<String, dynamic>> getFilterOptions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'years': [2026, 2025, 2024, 2023],
      'regions': ['海淀', '东城', '西城', '朝阳', '丰台', '石景山'],
      'exam_types': ['一模', '二模', '三模', '期末', '高考'],
    };
  }

  /// 按条件搜索题目列表（静默 mock）
  static Future<List<Map<String, dynamic>>> searchQuestions({
    int? year, String? region, String? examType,
    double? minDifficulty, double? maxDifficulty,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {'id': 6, 'source': '2025 东城一模 第 1 题', 'difficulty': 0.3, 'calculation': 1.2, 'type': '选择题'},
      {'id': 7, 'source': '2025 东城一模 第 2 题', 'difficulty': 0.5, 'calculation': 1.8, 'type': '填空题'},
      {'id': 8, 'source': '2025 东城一模 第 15 题', 'difficulty': 0.7, 'calculation': 2.5, 'type': '填空题'},
      {'id': 9, 'source': '2025 东城一模 第 19 题', 'difficulty': 0.8, 'calculation': 3.2, 'type': '解答题'},
      {'id': 10, 'source': '2025 东城一模 第 20 题', 'difficulty': 0.9, 'calculation': 4.0, 'type': '解答题'},
      {'id': 11, 'source': '2025 海淀一模 第 7 题', 'difficulty': 0.5, 'calculation': 1.5, 'type': '选择题'},
    ];
  }
}