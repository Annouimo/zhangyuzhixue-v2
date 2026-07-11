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
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.mainShell,
      name: 'home',
      builder: (context, state) => const MainShell(),
    ),
    GoRoute(
      path: AppRoutes.solveChoice,
      name: 'solve-choice',
      builder: (context, state) {
        final id = _intParam(state.uri.queryParameters, 'id') ?? 0;
        final next = _intParam(state.uri.queryParameters, 'next');
        return SolveChoicePage(questionId: id, nextQuestionId: next);
      },
    ),
    GoRoute(
      path: AppRoutes.solveFill,
      name: 'solve-fill',
      builder: (context, state) {
        final id = _intParam(state.uri.queryParameters, 'id') ?? 0;
        final next = _intParam(state.uri.queryParameters, 'next');
        return SolveFillPage(questionId: id, nextQuestionId: next);
      },
    ),
    GoRoute(
      path: AppRoutes.solveMap,
      name: 'solve-map',
      builder: (context, state) {
        final id = _intParam(state.uri.queryParameters, 'id') ?? 0;
        return SolveMapPage(questionId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.solveStep,
      name: 'solve-step',
      builder: (context, state) {
        final id = _intParam(state.uri.queryParameters, 'id') ?? 0;
        final m = _intParam(state.uri.queryParameters, 'method') ?? 0;
        final s = _intParam(state.uri.queryParameters, 'step') ?? 0;
        return SolveStepPage(questionId: id, methodIndex: m, stepIndex: s);
      },
    ),
    GoRoute(
      path: AppRoutes.solveRate,
      name: 'solve-rate',
      builder: (context, state) {
        final id = _intParam(state.uri.queryParameters, 'id') ?? 0;
        return SolveRatePage(questionId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.lectureChapters,
      name: 'lecture-chapters',
      builder: (context, state) {
        final courseId = _intParam(state.uri.queryParameters, 'courseId') ?? 0;
        return LectureChaptersPage(courseId: courseId);
      },
    ),
    GoRoute(
      path: AppRoutes.lectureContent,
      name: 'lecture-content',
      builder: (context, state) {
        final chapterId = _intParam(state.uri.queryParameters, 'chapterId') ?? 0;
        final page = _intParam(state.uri.queryParameters, 'page') ?? 1;
        return LectureContentPage(chapterId: chapterId, initialPage: page);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('页面未找到')),
    body: Center(
      child: Text('未找到页面: ${state.uri}'),
    ),
  ),
);

/// 获取初始路由（根据登录状态）
String getInitialRoute() {
  final token = AppPrefs().accessToken;
  return (token != null && token.isNotEmpty) ? AppRoutes.mainShell : AppRoutes.login;
}
