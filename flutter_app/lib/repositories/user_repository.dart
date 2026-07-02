import 'package:flutter/material.dart';

/// 用户相关：信息、积分、流水
class UserRepository {
  /// 读取用户基本信息（静默 mock）
  static Future<Map<String, dynamic>> getUserInfo() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'name': '李小红',
      'student_id': '2026001',
      'points': 9.2,
    };
  }

  /// 读取做题历史列表（静默 mock）
  static Future<List<Map<String, dynamic>>> getAnswerHistory() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {'title': '2025 海淀一模 Q20', 'type': '解答题', 'status': '进行中'},
      {'title': '2025 东城一模 Q19', 'type': '解答题', 'status': '已完成'},
    ];
  }

  /// 读取积分流水（静默 mock）
  static Future<List<Map<String, dynamic>>> getPointsHistory() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {'time': '2026-07-02 19:00', 'type': '组卷消耗', 'change': -10, 'balance': 9.2, 'note': '创建试卷"导数专项练习"'},
      {'time': '2026-07-01 10:00', 'type': '完成作业', 'change': 5, 'balance': 19.2, 'note': '完成"导数第1讲课后练习"'},
    ];
  }
}
