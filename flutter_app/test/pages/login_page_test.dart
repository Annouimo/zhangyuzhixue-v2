import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/data/api/auth_api.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/domain/auth_repository.dart';
import 'package:flutter_app/pages/login_page.dart';

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

void main() {
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

      // 按钮使用 ElevatedButton，找 ElevatedButton 中的 Text
      final loginButtons = find.text('登录');
      expect(loginButtons, findsOneWidget);

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

      // 直接点登录（不填内容）
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
  });
}
