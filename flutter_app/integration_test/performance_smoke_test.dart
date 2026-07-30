@Tags(['performance'])
library;

import 'dart:io';
import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_app/data/daos/lecture_dao.dart';
import 'package:flutter_app/data/daos/progress_dao.dart';
import 'package:flutter_app/data/daos/question_dao.dart';
import 'package:flutter_app/data/database/database_provider.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:flutter_app/debug/performance_trace.dart';
import 'package:flutter_app/main.dart' as app;
import 'package:flutter_app/pages/main_shell.dart';
import 'package:flutter_app/pages/question_bank/question_detail_page.dart';
import 'package:flutter_app/pages/recommend_page.dart';
import 'package:flutter_app/pages/router.dart';
import 'package:flutter_app/pages/solve/solve_choice_page.dart';
import 'package:flutter_app/pages/solve/solve_fill_page.dart';
import 'package:flutter_app/pages/solve/solve_map_page.dart';
import 'package:flutter_app/pages/statistics/statistics_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _hotRuns = int.fromEnvironment('PERFORMANCE_HOT_RUNS', defaultValue: 3);
const _scanMode = bool.fromEnvironment('PERFORMANCE_SCAN');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final trace = PerformanceTrace.instance;

  testWidgets(
    'Windows profile performance journeys',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const dataScale = String.fromEnvironment(
        'PERFORMANCE_DATA_SCALE',
        defaultValue: 'Normal',
      );
      SharedPreferences.setMockInitialValues({
        PrefKeys.accessToken: 'performance-local-token',
        PrefKeys.firstLaunchComplete: true,
      });
      await AppPrefs().init();
      await _prepareStableData(dataScale);
      trace
        ..setEnabled(true)
        ..clear()
        ..configureRun(
          'windows-profile-${DateTime.now().toUtc().toIso8601String()}',
        );

      final startupTimings = <FrameTiming>[];
      final startupCallback = startupTimings.addAll;
      WidgetsBinding.instance.addTimingsCallback(startupCallback);
      final startupSpan = trace.start('journey', 'frames_startup');
      app.main();
      await _waitFor(
        tester,
        find.byType(MainShell),
        timeout: const Duration(seconds: 30),
      );
      final contentReadySpan = trace.start('frame', 'MainShell.contentReady');
      await tester.pump();
      contentReadySpan.finish();
      startupSpan.finish();
      WidgetsBinding.instance.removeTimingsCallback(startupCallback);

      final questionDao = QuestionDao(DatabaseProvider());
      final progressDao = ProgressDao(DatabaseProvider());
      final lectureDao = LectureDao(DatabaseProvider());
      final questions = await questionDao.getAll();
      final attempts = await progressDao.getAllAttempts();
      final chapters = await lectureDao.getChapters(
        (await lectureDao.getAllCourses()).firstOrNull?.id ?? -1,
      );

      binding.reportData = {
        'environment': {
          'platform': 'windows',
          'mode': 'profile',
          'viewport': '1200x800',
          'dataScale': dataScale,
          'suite': _scanMode ? 'scan' : 'deepDive',
          'hotRuns': _hotRuns,
          'questionCount': questions.length,
          'attemptCount': attempts.length,
          'chapterCount': chapters.length,
        },
        'frames_startup': _summarizeFrames(startupTimings),
      };
      addTearDown(() {
        binding.reportData!['trace'] = trace.report(
          runName: 'windows-profile-smoke',
        );
      });

      if (_scanMode) {
        await _runPerformanceScan(
          tester,
          binding,
          questions: questions,
          chapters: chapters,
        );
        return;
      }

      await _runJourneyVariants(
        binding,
        'frames_tab_profile',
        reset: () => _returnHome(tester),
        action: () async {
          await _selectMainTab(tester, MainTab.content);
          await _selectMainTab(tester, MainTab.practice);
          await _selectMainTab(tester, MainTab.profile);
          await _waitFor(tester, find.text('学习档案'));
          await _selectMainTab(tester, MainTab.practice);
          await _selectMainTab(tester, MainTab.profile);
          await _waitFor(tester, find.text('学习档案'));
        },
      );

      await _runJourneyVariants(
        binding,
        'frames_recommend',
        reset: () => _returnHome(tester),
        action: () async {
          await _tapAndWait(
            tester,
            find.text('推荐练习'),
            ready: find.byType(RecommendPage),
            actionName: 'home.openRecommend',
          );
          await _waitForAny(tester, [
            find.byType(SolveChoicePage),
            find.byType(SolveFillPage),
            find.byType(SolveMapPage),
          ]);
        },
      );

      await _runJourneyVariants(
        binding,
        'frames_statistics',
        reset: () => _returnHome(tester),
        action: () async {
          NavigationThrottle.reset();
          appRouter.push(AppRoutes.statistics);
          await _waitFor(tester, find.byType(StatisticsPage));
          await _waitFor(tester, find.text('核心概览'));
          await _tapAndWait(
            tester,
            find.text('近一月'),
            ready: find.text('当前展示：近一月'),
            actionName: 'statistics.changeRange',
          );
        },
      );

      final solveQuestion = questions
          .where((question) => question.questionType == 'choice')
          .firstOrNull;
      if (solveQuestion != null) {
        await _runJourneyVariants(
          binding,
          'frames_enter_solve',
          reset: () => _returnHome(tester),
          action: () async {
            final context = tester.element(find.byType(MainShell));
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    StudentQuestionDetailPage(questionId: solveQuestion.id),
              ),
            );
            await _waitFor(tester, find.byType(StudentQuestionDetailPage));
            await _waitFor(tester, find.text('练习此题'));
            await _tapAndWait(
              tester,
              find.text('练习此题'),
              ready: find.byType(SolveChoicePage),
              actionName: 'questionDetail.startSolve',
            );
            await _waitFor(tester, find.text('选择题'));
          },
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

Future<void> _runPerformanceScan(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding, {
  required List<dynamic> questions,
  required List<dynamic> chapters,
}) async {
  await _returnHome(tester);
  await _traceScan(binding, 'frames_scan_tab_content', () async {
    await _selectMainTab(tester, MainTab.content);
    await _waitForScanReady(tester);
  });
  await _returnHome(tester);
  await _traceScan(binding, 'frames_scan_tab_profile', () async {
    await _selectMainTab(tester, MainTab.profile);
    await _waitFor(tester, find.text('学习档案'));
    await _waitForScanReady(tester);
  });

  final routes = <({String name, String location, String type})>[
    (name: 'recommend', location: AppRoutes.recommend, type: 'RecommendPage'),
    (
      name: 'question_bank',
      location: AppRoutes.questionBank,
      type: 'StudentQuestionBankPage',
    ),
    (
      name: 'paper_library',
      location: AppRoutes.paperLibrary,
      type: 'PaperLibraryPage',
    ),
    (name: 'exam_home', location: AppRoutes.examHome, type: 'ExamHomePage'),
    (
      name: 'paper_folders',
      location: AppRoutes.paperFolders,
      type: 'PaperFolderListPage',
    ),
    (
      name: 'lecture_courses',
      location: AppRoutes.lectureCourses,
      type: 'LectureCoursesPage',
    ),
    (
      name: 'statistics',
      location: AppRoutes.statistics,
      type: 'StatisticsPage',
    ),
    (
      name: 'profile_edit',
      location: AppRoutes.profileEdit,
      type: 'ProfileEditPage',
    ),
    (
      name: 'achievements',
      location: AppRoutes.profileAchievements,
      type: 'AchievementPage',
    ),
    (name: 'level', location: AppRoutes.profileLevel, type: 'LevelDetailPage'),
    (name: 'points', location: AppRoutes.profilePoints, type: 'PointsPage'),
    (
      name: 'history',
      location: AppRoutes.profileHistory,
      type: 'QuestionHistoryPage',
    ),
    (
      name: 'preferences',
      location: AppRoutes.profilePreferences,
      type: 'PreferenceListPage',
    ),
    (
      name: 'study_archive',
      location: AppRoutes.studyArchive,
      type: 'StudyArchivePage',
    ),
    (
      name: 'growth_center',
      location: AppRoutes.growthCenter,
      type: 'GrowthCenterPage',
    ),
    (name: 'settings', location: AppRoutes.settings, type: 'SettingsPage'),
    (name: 'sync_queue', location: AppRoutes.syncQueue, type: 'SyncQueuePage'),
    (
      name: 'contributions',
      location: AppRoutes.contributions,
      type: 'ContributionListPage',
    ),
    (
      name: 'contribution_help',
      location: AppRoutes.contributionHelp,
      type: 'ContributionHelpPage',
    ),
    (name: 'review', location: AppRoutes.review, type: 'ReviewPage'),
  ];
  for (final route in routes) {
    await _scanRoute(tester, binding, route);
  }

  if (chapters.isNotEmpty) {
    final chapter = chapters.first;
    await _scanRoute(tester, binding, (
      name: 'lecture_content',
      location: '${AppRoutes.lectureContent}?chapterId=${chapter.id}',
      type: 'LectureContentPage',
    ));
  }

  for (final questionType in const ['choice', 'fill', 'map']) {
    final question = questions
        .cast<dynamic>()
        .where((item) => item.questionType == questionType)
        .firstOrNull;
    if (question == null) continue;
    final route = switch (questionType) {
      'choice' => AppRoutes.solveChoice,
      'fill' => AppRoutes.solveFill,
      _ => AppRoutes.solveMap,
    };
    final pageType = switch (questionType) {
      'choice' => 'SolveChoicePage',
      'fill' => 'SolveFillPage',
      _ => 'SolveMapPage',
    };
    await _scanRoute(tester, binding, (
      name: 'solve_$questionType',
      location: '$route?id=${question.id}&mode=review',
      type: pageType,
    ));
  }
}

Future<void> _scanRoute(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  ({String name, String location, String type}) route,
) => _traceScan(binding, 'frames_scan_${route.name}', () async {
  NavigationThrottle.reset();
  appRouter.go(route.location);
  await _waitFor(
    tester,
    find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == route.type,
      description: route.type,
    ),
  );
  await _waitForScanReady(tester);
});

Future<void> _waitForScanReady(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  var readyPumps = 0;
  do {
    await tester.pump(const Duration(milliseconds: 25));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      readyPumps++;
      if (readyPumps >= 2) return;
    } else {
      readyPumps = 0;
    }
  } while (DateTime.now().isBefore(deadline));
  throw TestFailure('Page did not become content-ready within $timeout');
}

Future<void> _traceScan(
  IntegrationTestWidgetsFlutterBinding binding,
  String reportKey,
  Future<void> Function() action,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
  final timings = <FrameTiming>[];
  final callback = timings.addAll;
  WidgetsBinding.instance.addTimingsCallback(callback);
  final span = PerformanceTrace.instance.start('journey', reportKey);
  try {
    await action();
    span.finish();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  } catch (error) {
    span.finish({'failed': true, 'errorType': error.runtimeType.toString()});
    binding.reportData!['failure'] = {
      'journey': reportKey,
      'errorType': error.runtimeType.toString(),
      'message': error.toString(),
    };
    rethrow;
  } finally {
    WidgetsBinding.instance.removeTimingsCallback(callback);
    binding.reportData![reportKey] = _summarizeFrames(timings);
  }
}

Future<void> _runJourneyVariants(
  IntegrationTestWidgetsFlutterBinding binding,
  String baseName, {
  required Future<void> Function() reset,
  required Future<void> Function() action,
}) async {
  for (var index = 0; index <= _hotRuns; index++) {
    await reset();
    final suffix = index == 0 ? 'cold' : 'hot_$index';
    await _traceJourney(binding, '${baseName}_$suffix', action);
  }
}

Future<void> _prepareStableData(String scale) async {
  final normalizedScale = scale.toLowerCase();
  final attemptCount = switch (normalizedScale) {
    'small' => 20,
    'normal' => 500,
    'large' => 5000,
    _ => throw ArgumentError.value(
      scale,
      'PERFORMANCE_DATA_SCALE',
      'Expected Small, Normal, or Large',
    ),
  };
  final runtimeDir = Directory(
    '${Directory.current.parent.path}${Platform.pathSeparator}.hermes'
    '${Platform.pathSeparator}tmp${Platform.pathSeparator}performance'
    '${Platform.pathSeparator}runtime${Platform.pathSeparator}$normalizedScale',
  );
  if (await runtimeDir.exists()) {
    await runtimeDir.delete(recursive: true);
  }
  await runtimeDir.create(recursive: true);
  await _copyBundledDatabase(runtimeDir, 'assets.db');
  await _copyBundledDatabase(runtimeDir, 'courses.db');

  final provider = DatabaseProvider();
  await provider.reset();
  await provider.initWithPath(runtimeDir.path);
  final questionCount = (await QuestionDao(provider).getAll()).length;
  if (questionCount == 0) {
    throw TestFailure('The performance fixture contains no questions');
  }

  final now = DateTime.now().toUtc();
  await provider.appDb.transaction(() async {
    await provider.appDb.customStatement(
      'INSERT INTO user_profile '
      '(id, name, student_id, school, gaokao_year, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [
        1,
        'performance_user',
        'PERF-0001',
        '性能测试学校',
        '2027',
        now.toIso8601String(),
      ],
    );
    for (var index = 0; index < attemptCount; index++) {
      final timestamp = now
          .subtract(Duration(hours: index % (24 * 120)))
          .toIso8601String();
      await provider.appDb.customStatement(
        'INSERT INTO submission_detail '
        '(question_id, attempt_number, status, is_correct, created_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [
          (index % questionCount) + 1,
          (index ~/ questionCount) + 1,
          'completed',
          index % 4 == 0 ? 0 : 1,
          timestamp,
          timestamp,
        ],
      );
    }
  });
}

Future<void> _copyBundledDatabase(Directory target, String name) async {
  final bytes = await rootBundle.load('assets/db/$name');
  await File('${target.path}${Platform.pathSeparator}$name').writeAsBytes(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    flush: true,
  );
}

Future<void> _traceJourney(
  IntegrationTestWidgetsFlutterBinding binding,
  String reportKey,
  Future<void> Function() action,
) async {
  await Future<void>.delayed(const Duration(seconds: 2));
  final timings = <FrameTiming>[];
  final callback = timings.addAll;
  WidgetsBinding.instance.addTimingsCallback(callback);
  Object? actionError;
  StackTrace? actionStack;
  try {
    await PerformanceTrace.instance.measureAsync('journey', reportKey, action);
  } catch (error, stack) {
    actionError = error;
    actionStack = stack;
  }
  await Future<void>.delayed(const Duration(seconds: 2));
  WidgetsBinding.instance.removeTimingsCallback(callback);
  binding.reportData![reportKey] = _summarizeFrames(timings);
  if (actionError != null) {
    binding.reportData!['failure'] = {
      'journey': reportKey,
      'errorType': actionError.runtimeType.toString(),
      'message': actionError.toString(),
    };
    Error.throwWithStackTrace(actionError, actionStack!);
  }
}

Map<String, Object?> _summarizeFrames(List<FrameTiming> timings) {
  final build = timings
      .map((timing) => timing.buildDuration.inMicroseconds / 1000)
      .toList(growable: false);
  final raster = timings
      .map((timing) => timing.rasterDuration.inMicroseconds / 1000)
      .toList(growable: false);
  final total = timings
      .map((timing) => timing.totalSpan.inMicroseconds / 1000)
      .toList(growable: false);
  return {
    'frame_count': timings.length,
    'average_frame_build_time_millis': _average(build),
    '90th_percentile_frame_build_time_millis': _percentile(build, 0.9),
    'worst_frame_build_time_millis': _max(build),
    'average_frame_rasterizer_time_millis': _average(raster),
    '90th_percentile_frame_rasterizer_time_millis': _percentile(raster, 0.9),
    'worst_frame_rasterizer_time_millis': _max(raster),
    '90th_percentile_frame_total_time_millis': _percentile(total, 0.9),
    'worst_frame_total_time_millis': _max(total),
    'slow_frame_count': total.where((value) => value > 33).length,
    'severe_frame_count': total.where((value) => value > 100).length,
    'missed_frame_build_budget_count': build
        .where((value) => value > 16.7)
        .length,
    'missed_frame_rasterizer_budget_count': raster
        .where((value) => value > 16.7)
        .length,
  };
}

double _average(List<double> values) => values.isEmpty
    ? 0
    : values.reduce((left, right) => left + right) / values.length;

double _max(List<double> values) => values.isEmpty
    ? 0
    : values.reduce((left, right) => left > right ? left : right);

double _percentile(List<double> values, double percentile) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index];
}

Future<void> _selectMainTab(WidgetTester tester, MainTab tab) async {
  final prefix = 'main-tab-${tab.name}';
  final candidates = [
    find.byKey(ValueKey('$prefix-unselected')),
    find.byKey(ValueKey('$prefix-selected')),
  ];
  await _waitForAny(tester, candidates);
  final target = candidates.firstWhere(
    (candidate) => candidate.evaluate().isNotEmpty,
  );
  final inkResponse = find.ancestor(
    of: target,
    matching: find.byWidgetPredicate((widget) => widget is InkResponse),
  );
  await _waitFor(tester, inkResponse);
  await _tapAndWait(tester, inkResponse, actionName: 'mainTab.${tab.name}');
  await _waitForMainTab(tester, tab);
}

Future<void> _waitForMainTab(
  WidgetTester tester,
  MainTab tab, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  int? currentIndex;
  do {
    await tester.pump(const Duration(milliseconds: 16));
    final rail = find.byType(NavigationRail);
    if (rail.evaluate().isNotEmpty) {
      currentIndex = tester.widget<NavigationRail>(rail).selectedIndex;
    } else {
      final bar = find.byType(NavigationBar);
      if (bar.evaluate().isNotEmpty) {
        currentIndex = tester.widget<NavigationBar>(bar).selectedIndex;
      }
    }
    if (currentIndex == tab.index) return;
  } while (DateTime.now().isBefore(deadline));
  throw TestFailure(
    'Main tab did not change to ${tab.name} within $timeout; '
    'current index: $currentIndex, route: '
    '${appRouter.routeInformationProvider.value.uri}',
  );
}

Future<void> _returnHome(WidgetTester tester) async {
  NavigationThrottle.reset();
  appRouter.go(AppRoutes.mainShell);
  await _waitFor(tester, find.byType(MainShell));
  if (find.text('学习与出卷').evaluate().isNotEmpty) return;
  await _selectMainTab(tester, MainTab.practice);
}

Future<void> _tapAndWait(
  WidgetTester tester,
  Finder target, {
  Finder? ready,
  required String actionName,
  Duration timeout = const Duration(seconds: 15),
}) async {
  await _waitFor(tester, target, timeout: timeout);
  final span = PerformanceTrace.instance.startAction(actionName);
  final feedbackSpan = PerformanceTrace.instance.start(
    'frame',
    '$actionName.feedback',
  );
  await tester.tap(target);
  await tester.pump();
  feedbackSpan.finish();
  if (ready != null) {
    await _waitFor(tester, ready, timeout: timeout);
  }
  span.finish();
}

Future<void> _waitForAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  do {
    await tester.pump(const Duration(milliseconds: 50));
    if (finders.any((finder) => finder.evaluate().isNotEmpty)) return;
  } while (DateTime.now().isBefore(deadline));
  throw TestFailure('None of the expected widgets appeared within $timeout');
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  do {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  } while (DateTime.now().isBefore(deadline));
  throw TestFailure('Could not find $finder within $timeout');
}
