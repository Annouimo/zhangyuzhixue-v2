import 'package:flutter/material.dart';

/// 讲义相关：课程列表、章节列表、讲义正文
class LectureRepository {
  /// 读取课程列表（静默 mock）
  static Future<List<Map<String, dynamic>>> getCourses() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {'id': 1, 'name': '公益讲座'},
      {'id': 2, 'name': '导数系统课'},
    ];
  }

  /// 读取章节列表（静默 mock）
  static Future<List<Map<String, dynamic>>> getChapters(int courseId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      {'id': 1, 'title': '第 1 讲 xxx'},
      {'id': 2, 'title': '第 2 讲 xxx'},
    ];
  }

  /// 读取讲义正文内容（静默 mock）
  static Future<Map<String, dynamic>> getLectureContent(int chapterId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'title': '第 1 讲 xxx',
      'total_pages': 7,
      'current_page': 1,
      'content': '(讲义正文内容略，支持富文本、图片、公式)',
    };
  }
}
