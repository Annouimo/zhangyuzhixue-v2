import 'package:flutter/material.dart';

/// 作业相关：列表、进度、截止日期
class AssignmentRepository {
  /// 读取待办作业列表（静默 mock）
  static Future<List<Map<String, dynamic>>> getPendingAssignments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {'name': '初始作业', 'progress': '5/11', 'course': '公益讲座', 'days_left': 5},
      {'name': '导数第 1 讲课后练习', 'progress': '2/6', 'course': '导数系统课', 'days_left': 5},
    ];
  }

  /// 读取作业内题目列表（静默 mock）
  static Future<List<Map<String, dynamic>>> getAssignmentQuestions(int assignmentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {'id': 1, 'number': '第 1 题', 'type': '填空题', 'status': '已完成'},
      {'id': 2, 'number': '第 2 题', 'type': '选择题', 'status': '未做'},
      {'id': 3, 'number': '第 3 题', 'type': '解答题', 'status': '进行中'},
    ];
  }
}
