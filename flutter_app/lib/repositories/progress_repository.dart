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
        'analysis': '在三角形 ABC 中，（解析略）',
        'knowledge_cards': ['三角恒等变形'],
      },
      {
        'step_number': 2,
        'title': '第 2 步',
        'analysis': '（解析略）',
        'knowledge_cards': ['正弦定理', '化简'],
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
        '2': null,  // 还未做到这一步
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
