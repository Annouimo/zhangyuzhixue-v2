import 'package:flutter/material.dart';
import 'auth_repository.dart';

/// 用户相关：信息、积分、流水
class UserRepository {
  /// 读取用户基本信息（静默 mock，数据来自 AuthRepository）
  static Future<Map<String, dynamic>> getUserInfo() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return AuthRepository.getMockUser();
  }

  /// 读取做题历史列表（静默 mock）
  static Future<List<Map<String, dynamic>>> getAnswerHistory() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {'title': '2025 海淀一模 Q20', 'type': '解答题', 'status': '进行中'},
      {'title': '2025 东城一模 Q19', 'type': '解答题', 'status': '已完成'},
      {'title': '2025 西城一模 Q15', 'type': '填空题', 'status': '已完成'},
      {'title': '2025 朝阳一模 Q8', 'type': '选择题', 'status': '已完成'},
      {'title': '2024 海淀二模 Q20', 'type': '解答题', 'status': '未做'},
      {'title': '2024 东城一模 Q10', 'type': '选择题', 'status': '进行中'},
    ];
  }

  /// 读取积分流水（静默 mock）
  static Future<List<Map<String, dynamic>>> getPointsHistory() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {'time': '2026-07-02 19:00', 'type': '组卷消耗', 'change': -10, 'balance': 9.2, 'note': '创建试卷"导数专项练习"'},
      {'time': '2026-07-01 10:00', 'type': '完成作业', 'change': 5, 'balance': 19.2, 'note': '完成"导数第1讲课后练习"'},
      {'time': '2026-06-30 08:30', 'type': '每日签到', 'change': 1, 'balance': 14.2, 'note': '连续签到第 3 天'},
      {'time': '2026-06-28 15:20', 'type': '完成作业', 'change': 5, 'balance': 13.2, 'note': '完成"函数综合练习"'},
      {'time': '2026-06-25 20:10', 'type': '组卷消耗', 'change': -10, 'balance': 8.2, 'note': '创建试卷"数列专项检测"'},
      {'time': '2026-06-20 12:00', 'type': '完成题目', 'change': 2, 'balance': 18.2, 'note': '独立完成一道压轴题'},
    ];
  }
}