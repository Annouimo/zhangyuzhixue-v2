import 'package:flutter/material.dart';

/// 讲义相关：课程列表、章节列表、讲义正文
class LectureRepository {
  /// 读取课程列表（静默 mock）
  static Future<List<Map<String, dynamic>>> getCourses() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {'id': 1, 'name': '公益讲座'},
      {'id': 2, 'name': '导数系统课'},
      {'id': 3, 'name': '解析几何系统课'},
    ];
  }

  /// 读取章节列表（静默 mock）
  static Future<List<Map<String, dynamic>>> getChapters(int courseId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (courseId == 1) {
      return [
        {'id': 1, 'title': '第 1 讲 函数基础'},
        {'id': 2, 'title': '第 2 讲 三角函数入门'},
        {'id': 3, 'title': '第 3 讲 数列初步'},
        {'id': 4, 'title': '第 4 讲 概率统计'},
      ];
    } else if (courseId == 2) {
      return [
        {'id': 5, 'title': '第 1 讲 导数的概念'},
        {'id': 6, 'title': '第 2 讲 求导法则'},
        {'id': 7, 'title': '第 3 讲 导数与单调性'},
        {'id': 8, 'title': '第 4 讲 极值与最值'},
        {'id': 9, 'title': '第 5 讲 导数综合应用'},
      ];
    }
    return [
      {'id': 10, 'title': '第 1 讲 直线与圆'},
      {'id': 11, 'title': '第 2 讲 椭圆'},
      {'id': 12, 'title': '第 3 讲 双曲线'},
      {'id': 13, 'title': '第 4 讲 抛物线'},
      {'id': 14, 'title': '第 5 讲 圆锥曲线综合'},
      {'id': 15, 'title': '第 6 讲 参数方程与极坐标'},
    ];
  }

  /// 读取讲义正文内容（静默 mock）
  static Future<Map<String, dynamic>> getLectureContent(int chapterId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'title': '第 1 讲 导数的概念',
      'total_pages': 5,
      'current_page': 1,
      'content': '一、导数的定义\n\n设函数 y = f(x) 在点 x0 的某邻域内有定义，若极限\n\nlim_(Δx→0) [f(x0+Δx) - f(x0)] / Δx\n\n存在，则称函数 f(x) 在点 x0 处可导，该极限值称为 f(x) 在 x0 处的导数，记作 f\'"(x0)。\n\n二、导数的几何意义\n\n导数 f\'"(x0) 表示曲线 y = f(x) 在点 (x0, f(x0)) 处切线的斜率。\n\n切线方程：y - f(x0) = f\'"(x0)(x - x0)\n\n法线方程：y - f(x0) = -1/f\'"(x0) (x - x0)\n\n三、基本初等函数的导数公式\n\n1. (C)\' = 0\n2. (x^n)\' = nx^(n-1)\n3. (sin x)\' = cos x\n4. (cos x)\' = -sin x\n5. (e^x)\' = e^x\n6. (ln x)\' = 1/x',
    };
  }
}