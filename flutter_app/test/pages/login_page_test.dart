import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/api/auth_api.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/domain/auth_repository.dart';
import 'package:flutter_app/domain/preference_repository.dart';
import 'package:flutter_app/data/prefs/app_prefs.dart';
import 'package:flutter_app/pages/login_page.dart';
import '../test_setup.dart';

class _MockAuthRepo extends AuthRepository {
  final bool shouldSucceed;
  _MockAuthRepo({this.shouldSucceed = true})
      : super(AuthApi(ApiClient()));

  @override
  Future<LoginResult> login(LoginRequest request) async {
    if (shouldSucceed) {
      return LoginResult(
        accessToken: 'mock_access',
        refreshToken: 'mock_refresh',
        user: {'id': 1, 'username': 'test', 'role': 'student'},
      );
    }
    throw Exception('40001: 用户名或密码错误');
  }
}

class _FailingAuthRepo extends AuthRepository {
  _FailingAuthRepo() : super(AuthApi(ApiClient()));

  @override
  Future<LoginResult> login(LoginRequest request) async {
    throw Exception('Connection failed');
  }
}

/// 始终返回 1 条偏好的 mock（替代 PreferenceRepository）
class _HasPrefs implements PreferenceRepository {
  @override
  Future<int> getCount() async => 1;
  @override
  Future<List<PreferenceSummary>> getList() async => [];
  @override
  Future<PreferenceFilter> getEdit(int id) async => throw UnimplementedError();
  @override
  Future<void> save({required String name, required PreferenceFilter filter}) async {}
  @override
  Future<void> delete(int id) async {}
}

void main() {
    setUp(() => setupTestHooks());
  group('LoginPage', () {
    testWidgets('renders login form with all elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            authRepository: _MockAuthRepo(),
          ),
        ),
      );

      expect(find.text('🐙 章鱼智学'), findsOneWidget);
      expect(find.text('📚 登录'), findsOneWidget);
      expect(find.text('用户名'), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);
      expect(find.text('登录'), findsOneWidget);
      expect(find.text('使用邀请码注册'), findsOneWidget);
    });

    testWidgets('shows validation error on empty fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            authRepository: _MockAuthRepo(),
          ),
        ),
      );

      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      expect(find.text('请输入用户名'), findsOneWidget);
      expect(find.text('请输入密码'), findsOneWidget);
    });

    testWidgets('shows error snackbar on login failure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            authRepository: _MockAuthRepo(shouldSucceed: false),
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'testuser');
      await tester.enterText(fields.last, 'wrongpass');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      expect(find.text('用户名或密码错误'), findsOneWidget);
    });

    testWidgets('shows generic error on network failure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            authRepository: _FailingAuthRepo(),
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'testuser');
      await tester.enterText(fields.last, 'pass');
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      expect(find.text('登录失败，请稍后重试'), findsOneWidget);
    });

    testWidgets('login success navigates to home with router', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AppPrefs().init();

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, _) => LoginPage(
              authRepository: _MockAuthRepo(),
              preferenceRepository: _HasPrefs(),
            ),
          ),
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: Center(child: Text('主页')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      expect(find.text('📚 登录'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'testuser');
      await tester.enterText(fields.last, 'pass');
      await tester.tap(find.text('登录'));
      // 异步操作：登录 → 存 token → 偏好检查 → 导航，逐帧推进
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // 登录成功 → 导航到主页
      expect(find.text('主页'), findsOneWidget);
      expect(find.text('📚 登录'), findsNothing);
    });
  });
}
