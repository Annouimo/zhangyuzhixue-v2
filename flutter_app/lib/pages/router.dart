import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/prefs/app_prefs.dart';
import 'main_shell.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'solve/solve_choice_page.dart';
import 'solve/solve_fill_page.dart';
import 'solve/solve_map_page.dart';
import 'solve/solve_step_page.dart';
import 'solve/solve_rate_page.dart';
import 'lecture/lecture_chapters_page.dart';
import 'lecture/lecture_content_page.dart';
import 'homework/homework_detail_page.dart';
import 'exam/exam_auto_page.dart';
import 'exam/exam_pick_page.dart';
import 'exam/exam_quicklook_page.dart';
import 'exam/exam_quicklook_other_page.dart';
import 'exam/exam_history_page.dart';
import 'exam/exam_explore_page.dart';
import 'exam/exam_favorites_page.dart';
import 'exam/answer_sheet_page.dart';
import 'statistics/statistics_page.dart';
import 'recommend_page.dart';

/// 路由路径常量
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const mainShell = '/';
  static const solveChoice = '/solve/choice';
  static const solveFill = '/solve/fill';
  static const solveMap = '/solve/map';
  static const solveStep = '/solve/step';
  static const solveRate = '/solve/rate';
  static const lectureChapters = '/lecture/chapters';
  static const lectureContent = '/lecture/content';
  static const homeworkDetail = '/homework/detail';
  static const examAuto = '/exam/auto';
  static const examPick = '/exam/pick';
  static const examQuicklook = '/exam/quicklook';
  static const examQuicklookOther = '/exam/quicklook_other';
  static const examHistory = '/exam/history';
  static const examExplore = '/exam/explore';
  static const examFavorites = '/exam/favorites';
  static const answerSheet = '/exam/answersheet';
  static const recommend = '/recommend';
  static const statistics = '/statistics';
}

/// 从 query 参数解析 int
int? _intParam(Map<String, String> params, String key) {
  final v = params[key];
  if (v == null) return null;
  return int.tryParse(v);
}

/// 路由配置
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(path: AppRoutes.login, name: 'login', builder: (_, __) => const LoginPage()),
    GoRoute(path: AppRoutes.register, name: 'register', builder: (_, __) => const RegisterPage()),
    GoRoute(path: AppRoutes.mainShell, name: 'home', builder: (_, __) => const MainShell()),
    GoRoute(path: AppRoutes.solveChoice, name: 'solve-choice', builder: (_, state) {
      return SolveChoicePage(questionId: _intParam(state.uri.queryParameters, 'id') ?? 0, nextQuestionId: _intParam(state.uri.queryParameters, 'next')); }),
    GoRoute(path: AppRoutes.solveFill, name: 'solve-fill', builder: (_, state) {
      return SolveFillPage(questionId: _intParam(state.uri.queryParameters, 'id') ?? 0, nextQuestionId: _intParam(state.uri.queryParameters, 'next')); }),
    GoRoute(path: AppRoutes.solveMap, name: 'solve-map', builder: (_, state) {
      return SolveMapPage(questionId: _intParam(state.uri.queryParameters, 'id') ?? 0); }),
    GoRoute(path: AppRoutes.solveStep, name: 'solve-step', builder: (_, state) {
      return SolveStepPage(questionId: _intParam(state.uri.queryParameters, 'id') ?? 0, methodIndex: _intParam(state.uri.queryParameters, 'method') ?? 0, stepIndex: _intParam(state.uri.queryParameters, 'step') ?? 0); }),
    GoRoute(path: AppRoutes.solveRate, name: 'solve-rate', builder: (_, state) {
      return SolveRatePage(questionId: _intParam(state.uri.queryParameters, 'id') ?? 0); }),
    GoRoute(path: AppRoutes.lectureChapters, name: 'lecture-chapters', builder: (_, state) {
      return LectureChaptersPage(courseId: _intParam(state.uri.queryParameters, 'courseId') ?? 0); }),
    GoRoute(path: AppRoutes.lectureContent, name: 'lecture-content', builder: (_, state) {
      return LectureContentPage(chapterId: _intParam(state.uri.queryParameters, 'chapterId') ?? 0, initialPage: _intParam(state.uri.queryParameters, 'page') ?? 1); }),
    GoRoute(path: AppRoutes.homeworkDetail, name: 'homework-detail', builder: (_, state) {
      return HomeworkDetailPage(assignmentId: _intParam(state.uri.queryParameters, 'id') ?? 0); }),
    // 组卷路由
    GoRoute(path: AppRoutes.examAuto, name: 'exam-auto', builder: (_, __) => const ExamAutoPage()),
    GoRoute(path: AppRoutes.examPick, name: 'exam-pick', builder: (_, __) => const ExamPickPage()),
    GoRoute(path: AppRoutes.examQuicklook, name: 'exam-quicklook', builder: (_, state) {
      return ExamQuicklookPage(examId: _intParam(state.uri.queryParameters, 'id') ?? 0); }),
    GoRoute(path: AppRoutes.examQuicklookOther, name: 'exam-quicklook-other', builder: (_, state) {
      return ExamQuicklookOtherPage(examId: _intParam(state.uri.queryParameters, 'id') ?? 0); }),
    GoRoute(path: AppRoutes.examHistory, name: 'exam-history', builder: (_, __) => const ExamHistoryPage()),
    GoRoute(path: AppRoutes.examExplore, name: 'exam-explore', builder: (_, __) => const ExamExplorePage()),
    GoRoute(path: AppRoutes.examFavorites, name: 'exam-favorites', builder: (_, __) => const ExamFavoritesPage()),
    GoRoute(path: AppRoutes.answerSheet, name: 'answer-sheet', builder: (_, state) {
      return AnswerSheetPage(examId: _intParam(state.uri.queryParameters, 'id') ?? 0); }),
    GoRoute(path: AppRoutes.recommend, name: 'recommend', builder: (_, __) => const RecommendPage()),
    GoRoute(path: AppRoutes.statistics, name: 'statistics', builder: (_, __) => const StatisticsPage()),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('页面未找到')),
    body: Center(child: Text('未找到页面: ${state.uri}')),
  ),
);

/// 获取初始路由（根据登录状态）
String getInitialRoute() {
  final token = AppPrefs().accessToken;
  return (token != null && token.isNotEmpty) ? AppRoutes.mainShell : AppRoutes.login;
}
