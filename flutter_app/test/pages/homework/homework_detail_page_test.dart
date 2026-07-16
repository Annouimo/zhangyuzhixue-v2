import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/domain/assignment_repository.dart';
import 'package:flutter_app/pages/homework/homework_detail_page.dart';
import '../../test_setup.dart';

class _MockDetailRepo implements AssignmentRepository {
  final AssignmentDetail? detail;
  _MockDetailRepo({this.detail});

  @override
  Future<List<AssignmentSummary>> getPending() async =>
      throw UnimplementedError();

  @override
  Future<List<AssignmentSummary>?> getPendingCached() async => null;

  @override
  Future<List<AssignmentSummary>> getPendingLocal() async => [];

  @override
  Future<AssignmentDetail> getQuestions(int id) async =>
      detail ?? AssignmentDetail(
        title: '', courseName: '', questions: [],
        doneCount: 0, totalCount: 0, deadlineDays: 0,
      );

  @override
  Future<int> pendingCount() async => throw UnimplementedError();
}

class _FailingDetailRepo implements AssignmentRepository {
  @override
  Future<List<AssignmentSummary>> getPending() async =>
      throw UnimplementedError();

  @override
  Future<List<AssignmentSummary>?> getPendingCached() async => null;

  @override
  Future<List<AssignmentSummary>> getPendingLocal() async => [];

  @override
  Future<AssignmentDetail> getQuestions(int id) async =>
      throw Exception('作业不存在');

  @override
  Future<int> pendingCount() async => throw UnimplementedError();
}

void main() {
    setUp(() => setupTestHooks());
  group('HomeworkDetailPage', () {
    testWidgets('shows loading then detail', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: HomeworkDetailPage(
              assignmentId: 1,
              assignmentRepository: _MockDetailRepo(
                detail: const AssignmentDetail(
                  title: '函数作业', courseName: '代数',
                  doneCount: 3, totalCount: 10, deadlineDays: 5,
                  questions: [
                    QuestionSummary(id: 1, number: '1', questionType: 'choice', status: 'completed'),
                    QuestionSummary(id: 2, number: '2', questionType: 'fill', status: 'pending'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.text('函数作业'), findsAtLeast(1));
      expect(find.text('代数'), findsOneWidget);
    });

    testWidgets('shows question list with status', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: HomeworkDetailPage(
              assignmentId: 1,
              assignmentRepository: _MockDetailRepo(
                detail: const AssignmentDetail(
                  title: '作业', courseName: '',
                  doneCount: 1, totalCount: 2, deadlineDays: 0,
                  questions: [
                    QuestionSummary(id: 10, number: '7', questionType: 'choice', status: 'completed'),
                    QuestionSummary(id: 11, number: '8', questionType: 'fill', status: 'pending'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('第 7 题'), findsOneWidget);
      expect(find.text('第 8 题'), findsOneWidget);
      // Completed question shows check icon
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows error on load failure', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: HomeworkDetailPage(
              assignmentId: 999,
              assignmentRepository: _FailingDetailRepo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('navigates to solve on question tap', (tester) async {
      final router = GoRouter(
        initialLocation: '/homework/detail?id=1',
        routes: [
          GoRoute(
            path: '/homework/detail',
            builder: (_, state) => HomeworkDetailPage(
              assignmentId: 1,
              assignmentRepository: _MockDetailRepo(
                detail: const AssignmentDetail(
                  title: '作业', courseName: '',
                  doneCount: 0, totalCount: 1, deadlineDays: 0,
                  questions: [
                    QuestionSummary(id: 5, number: '1', questionType: 'choice', status: 'pending'),
                  ],
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/solve/choice',
            builder: (_, state) =>
                const Scaffold(body: Center(child: Text('SolvePage'))),
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

      await tester.tap(find.text('第 1 题'));
      await tester.pumpAndSettle();

      expect(find.text('SolvePage'), findsOneWidget);
    });
  });
}
