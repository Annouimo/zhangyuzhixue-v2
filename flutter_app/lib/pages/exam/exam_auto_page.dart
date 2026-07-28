import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/exam_repository.dart';
import '../../domain/preference_repository.dart';
import '../../domain/user_repository.dart';
import '../router.dart';

/// Compatibility entry for callers that still open the former smart-paper page.
class ExamAutoPage extends StatefulWidget {
  final ExamRepository? examRepository;
  final PreferenceRepository? preferenceRepository;
  final UserRepository? userRepository;

  const ExamAutoPage({
    super.key,
    this.examRepository,
    this.preferenceRepository,
    this.userRepository,
  });

  @override
  State<ExamAutoPage> createState() => _ExamAutoPageState();
}

class _ExamAutoPageState extends State<ExamAutoPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.questionBank);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
