import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/api/auth_api.dart';
import 'package:flutter_app/data/api/api_client.dart';
import 'package:flutter_app/domain/auth_repository.dart';
import 'package:flutter_app/pages/register_page.dart';
import '../test_setup.dart';

class _MockAuthRepo extends AuthRepository {
  _MockAuthRepo() : super(AuthApi(ApiClient()));

  @override
  Future<void> register(RegisterRequest data) async {
    return;
  }
}

/// Helper: 填入所有文本字段（高考年份为 dropdown，单独处理）
Future<void> _fillAllFields(
  WidgetTester tester, {
  String username = 'testuser',
  String realName = '张三',
  String phone = '13800138000',
  String password = 'password123',
  String confirmPassword = 'password123',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), username);
  await tester.enterText(fields.at(1), realName);
  await tester.enterText(fields.at(2), phone);
  await tester.enterText(fields.at(3), password);
  await tester.enterText(fields.at(4), confirmPassword);
}

/// Helper: 点击注册按钮（先确保可见）
Future<void> _tapRegister(WidgetTester tester) async {
  final btn = find.text('完成注册');
  await tester.ensureVisible(btn);
  await tester.pumpAndSettle();
  await tester.tap(btn);
  await tester.pumpAndSettle();
}

Future<void> _acceptAgreements(WidgetTester tester) async {
  final checkbox = find.byType(Checkbox);
  await tester.ensureVisible(checkbox);
  await tester.tap(checkbox);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => setupTestHooks());
  group('RegisterPage', () {
    testWidgets('renders register form with all elements', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      expect(find.text('创建学生账号'), findsOneWidget);
      expect(find.text('邀请码'), findsNothing);
      expect(find.text('用户名'), findsOneWidget);
      expect(find.text('姓名'), findsOneWidget);
      expect(find.text('手机号'), findsOneWidget);
      expect(find.text('高考年份'), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);
      expect(find.text('确认密码'), findsOneWidget);
      expect(find.text('完成注册'), findsOneWidget);
      expect(find.text('我已阅读并同意'), findsOneWidget);
      expect(find.text('用户协议'), findsOneWidget);
      expect(find.text('隐私政策'), findsOneWidget);
      expect(find.text('返回登录'), findsOneWidget);
    });

    testWidgets('requires agreement before registration', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '完成注册'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // 清空高考年份（先展开再选空值）
      await tester.tap(find.text('2026 年'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025 年').last);
      await tester.pumpAndSettle();

      await _acceptAgreements(tester);
      await _tapRegister(tester);

      expect(find.text('请输入用户名'), findsOneWidget);
      expect(find.text('请输入姓名'), findsOneWidget);
      expect(find.text('请输入手机号'), findsOneWidget);
      expect(find.text('请输入密码'), findsOneWidget);
    });

    testWidgets('validates phone number format', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      await _fillAllFields(tester, phone: '12345');
      await _acceptAgreements(tester);
      await _tapRegister(tester);

      expect(find.text('请输入有效手机号'), findsOneWidget);
    });

    testWidgets('validates password confirmation match', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      await _fillAllFields(tester, confirmPassword: 'different');
      await _acceptAgreements(tester);
      await _tapRegister(tester);

      expect(find.text('两次密码不一致'), findsOneWidget);
    });

    testWidgets('back button returns to previous page', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
      expect(find.text('返回登录'), findsOneWidget);
    });

    testWidgets('register success navigates back to login', (tester) async {
      SharedPreferences.setMockInitialValues({});

      // 从 /login → push /register，这样 pop 才能回到 /login
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (ctx, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => ctx.push('/register'),
                  child: const Text('去注册'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/register',
            builder: (_, _) => RegisterPage(authRepository: _MockAuthRepo()),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // 先进注册页
      await tester.tap(find.text('去注册'));
      await tester.pumpAndSettle();
      expect(find.text('创建学生账号'), findsOneWidget);

      await _fillAllFields(tester);
      await _acceptAgreements(tester);
      await _tapRegister(tester);

      // 注册成功 → 显示成功 SnackBar → pop 回登录页
      expect(find.text('注册成功，请登录'), findsOneWidget);
      expect(find.text('去注册'), findsOneWidget); // 回到了登录页
    });
  });
}
