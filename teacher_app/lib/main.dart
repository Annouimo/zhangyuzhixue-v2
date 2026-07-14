import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'data/database/database_provider.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseProvider().init();
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
