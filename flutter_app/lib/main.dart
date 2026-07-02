import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/recommend_list_page.dart';
import 'pages/assignment_list_page.dart';
import 'pages/assignment_questions_page.dart';
import 'pages/solve_page.dart';
import 'pages/exam_builder_page.dart';
import 'pages/exam_preview_page.dart';
import 'pages/lecture_list_page.dart';
import 'pages/lecture_chapter_page.dart';
import 'pages/lecture_content_page.dart';
import 'pages/profile_page.dart';
import 'pages/answer_history_page.dart';
import 'pages/points_history_page.dart';
import 'widgets/bottom_nav_bar.dart';
import 'repositories/auth_repository.dart';

void main() {
  runApp(const ZhangyuzhixueApp());
}

/// App 根组件
class ZhangyuzhixueApp extends StatelessWidget {
  const ZhangyuzhixueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '章鱼智学',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          primary: AppTheme.primaryColor,
        ),
        scaffoldBackgroundColor: AppTheme.bgColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      initialRoute: AuthRepository.isLoggedIn() ? '/' : '/login',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        final path = uri.path;
        final queryParams = uri.queryParameters;

        Widget page;
        switch (path) {
          case '/login':
            page = const LoginPage();
            break;
          case '/register':
            page = const RegisterPage();
            break;
          case '/':
            page = const MainShell();
            break;
          case '/recommend-list':
            page = const RecommendListPage();
            break;
          case '/assignment-questions':
            page = AssignmentQuestionsPage(assignmentId: int.tryParse(queryParams['id'] ?? '') ?? 1);
            break;
          case '/solve':
            page = SolvePage(questionId: int.tryParse(queryParams['id'] ?? '') ?? 1);
            break;
          case '/exam-builder':
            page = const ExamBuilderPage();
            break;
          case '/exam-preview':
            page = ExamPreviewPage(examId: int.tryParse(queryParams['id'] ?? '') ?? 1);
            break;
          case '/lecture-chapter':
            page = LectureChapterPage(courseId: int.tryParse(queryParams['courseId'] ?? '') ?? 1);
            break;
          case '/lecture-content':
            page = LectureContentPage(chapterId: int.tryParse(queryParams['chapterId'] ?? '') ?? 1);
            break;
          case '/answer-history':
            page = const AnswerHistoryPage();
            break;
          case '/points-history':
            page = const PointsHistoryPage();
            break;
          default:
            page = const MainShell();
        }
        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    );
  }
}

/// 主壳（含底部导航栏）
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    AssignmentListPage(),
    LectureListPage(),
    ProfilePage(),
  ];

  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: switchToTab,
      ),
    );
  }
}
