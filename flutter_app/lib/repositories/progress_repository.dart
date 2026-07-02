import 'package:flutter/material.dart';

/// 进度相关：当前步骤、反馈记录、步骤序列
class ProgressRepository {
  /// 读取解题步骤序列（静默 mock）
  static Future<List<Map<String, dynamic>>> getSteps(int questionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {
        'step_number': 1,
        'title': '第 1 步',
        'analysis': '由余弦定理 c = a + b - 2ab cos C\n代入已知条件：\nc = 4 + 9 - 2 x 2 x 3 x 1/4\nc = 13 - 3 = 10\n所以 c = √10',
        'knowledge_cards': ['余弦定理'],
      },
      {
        'step_number': 2,
        'title': '第 2 步',
        'analysis': '由 sin C + cos C = 1\nsin C = 1 - cos C = 1 - 1/16 = 15/16\n又 C 为三角形内角，sin C > 0，故 sin C = √15 / 4',
        'knowledge_cards': ['同角三角函数关系', '正弦定理'],
      },
      {
        'step_number': 3,
        'title': '第 3 步',
        'analysis': '由正弦定理 a/sin A = c/sin C\n代入：2/sin A = √10 / (√15/4)\nsin A = 2 x √15 / 4 / √10\nsin A = √6 / 4',
        'knowledge_cards': ['正弦定理'],
      },
      {
        'step_number': 4,
        'title': '第 4 步',
        'analysis': '由余弦定理 cos A = (b + c - a) / (2bc)\n代入：cos A = (9 + 10 - 4) / (2 x 3 x √10)\ncos A = 15 / (6√10) = 5 / (2√10)\n\n步骤 4 完成，本题求解完毕。',
        'knowledge_cards': ['余弦定理', '化简'],
      },
    ];
  }

  /// 读取当前用户做题进度（静默 mock）
  static Future<Map<String, dynamic>> getProgress(int questionId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'current_step': 1,
      'feedbacks': {
        '1': '全对',
        '2': null,
      },
      'completed': false,
    };
  }

  /// 记录步骤反馈（写入操作，显示 Toast）
  static Future<void> submitStepFeedback(
    BuildContext context,
    int questionId,
    int stepNumber,
    String feedback,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在进行记录步骤 $stepNumber 反馈操作，需要写入反馈数据（$feedback）')),
    );
    await Future.delayed(const Duration(milliseconds: 200));
  }
}