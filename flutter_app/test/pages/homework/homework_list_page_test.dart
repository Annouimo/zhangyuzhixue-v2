import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/domain/assignment_repository.dart';
import 'package:flutter_app/pages/homework/homework_list_page.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAssignmentRepo implements AssignmentRepository {
  final List<AssignmentSummary> assignments;
  _MockAssignmentRepo({this.assignments = const []});

  @override
  Future<List<AssignmentSummary>> getPending() async => assignments;

  @override
  Future<AssignmentDetail> getQuestions(int id) async =>
      throw UnimplementedError();

  @override
  Future<int> pendingCount() async => assignments.length;
}

class _FailingAssignmentRepo implements AssignmentRepository {
  @override
  Future<List<AssignmentSummary>> getPending() async =>
      throw Exception('加载失败');

  @override
  Future<AssignmentDetail> getQuestions(int id) async =>
      throw UnimplementedError();

  @override
  Future<int> pendingCount() async => throw UnimplementedError();
}

void main() {
  group('HomeworkListPage', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppPrefs().init();
    });
    testWidgets('shows loading then assignment list', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: HomeworkListPage(
              assignmentRepository: _MockAssignmentRepo(
                assignments: [
                  const AssignmentSummary(
                    id: 1, title: '第一次函数作业', courseName: '代数',
                    doneCount: 2, totalCount: 10, deadlineDays: 5, status: 'pending',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('第一次函数作业'), findsOneWidget);
      expect(find.text('代数'), findsOneWidget);
      expect(find.text('2/10'), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: HomeworkListPage(
              assignmentRepository: _MockAssignmentRepo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂无待办作业'), findsOneWidget);
    });

    testWidgets('shows error and retry', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: HomeworkListPage(
              assignmentRepository: _FailingAssignmentRepo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('navigates to detail on tap', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => HomeworkListPage(
              assignmentRepository: _MockAssignmentRepo(
                assignments: [
                  const AssignmentSummary(
                    id: 5, title: '作业', courseName: '',
                    doneCount: 0, totalCount: 3, deadlineDays: 0, status: 'pending',
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/homework/detail',
            builder: (_, state) {
              return const Scaffold(body: Center(child: Text('DetailPage')));
            },
          ),
        ],
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the assignment card via its card widget
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('DetailPage'), findsOneWidget);
    });
  });
}
