import 'package:flutter/material.dart';

/// 组卷相关：创建试卷、删除、预览、积分消耗
class ExamRepository {
  /// 读取已组试卷列表（静默 mock）
  static Future<List<Map<String, dynamic>>> getMyExams() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {
        'name': '导数专项练习',
        'choice_count': 2,
        'fill_count': 2,
        'solution_count': 3,
        'total': 7,
        'questions': [
          {'source': '2025 东城一模 第 1 题', 'difficulty': 0.3, 'calculation': 1.2},
          {'source': '2025 东城一模 第 2 题', 'difficulty': 0.5, 'calculation': 1.8},
          {'source': '2025 海淀一模 第 15 题', 'difficulty': 0.7, 'calculation': 2.5},
          {'source': '2025 海淀一模 第 20 题', 'difficulty': 0.9, 'calculation': 4.0},
        ],
      },
      {
        'name': '数列专项检测',
        'choice_count': 3,
        'fill_count': 1,
        'solution_count': 2,
        'total': 6,
        'questions': [
          {'source': '2024 西城二模 第 3 题', 'difficulty': 0.4, 'calculation': 1.0},
          {'source': '2024 西城二模 第 8 题', 'difficulty': 0.6, 'calculation': 2.0},
          {'source': '2024 海淀期末 第 18 题', 'difficulty': 0.7, 'calculation': 3.0},
        ],
      },
    ];
  }

  /// 确认组卷（写入操作，显示 Toast）
  static Future<void> confirmCreateExam(BuildContext context, String name, List<int> questionIds) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在进行确认组卷操作，需要写入试卷数据并扣减积分')),
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 删除试卷（写入操作，显示 Toast）
  static Future<void> deleteExam(BuildContext context, int examId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在进行删除试卷操作，需要删除试卷及题目关联记录')),
    );
    await Future.delayed(const Duration(milliseconds: 300));
  }
}