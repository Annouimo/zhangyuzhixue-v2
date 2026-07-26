import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/theme/app_theme.dart';

/// 第二阶段学生端 UI 精修使用的固定测试视口。
enum UiTestViewport {
  mobile(Size(390, 844)),
  desktop(Size(1280, 800));

  const UiTestViewport(this.size);

  final Size size;
}

/// 固定主题，避免 widget 测试结果依赖运行测试的操作系统主题。
enum UiTestTheme { light, dark }

/// 在固定视口和固定主题下渲染一个 UI 场景。
///
/// 业务页面的视觉回归测试应优先使用此入口，不再各自创建不同尺寸的
/// [MediaQuery]。交互测试仍可按需要直接构建自己的 [MaterialApp]。
Future<void> pumpUiScenario(
  WidgetTester tester,
  Widget child, {
  UiTestViewport viewport = UiTestViewport.mobile,
  UiTestTheme theme = UiTestTheme.light,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport.size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme == UiTestTheme.light ? ThemeMode.light : ThemeMode.dark,
      home: child,
    ),
  );
}
