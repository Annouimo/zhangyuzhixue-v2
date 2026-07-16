import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared/theme/app_theme.dart';
import 'data/database/database_provider.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuditLogger.instance.init();
  await OperationLog.instance.init();
  await DatabaseProvider().init();

  FlutterError.onError = (details) {
    OperationLog.instance.error('FlutterError', details.exception, details.stack);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    OperationLog.instance.error('PlatformDispatcher', error, stack);
    return true;
  };

  runApp(const TeacherApp());
}

class TeacherApp extends StatelessWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '章鱼智学 · 教师端',
      theme: AppTheme.light,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
