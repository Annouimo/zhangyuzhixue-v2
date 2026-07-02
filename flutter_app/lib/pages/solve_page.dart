import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/progress_repository.dart';
import '../repositories/rating_repository.dart';
import '../widgets/step_card.dart';
import '../widgets/feedback_buttons.dart';
import '../widgets/rating_widget.dart';

/// 解题模式（核心交互页面）
class SolvePage extends StatefulWidget {
  final int questionId;

  const SolvePage({super.key, required this.questionId});

  @override
  State<SolvePage> createState() => _SolvePageState();
}

class _SolvePageState extends State<SolvePage> {
  bool _started = false;
  int _currentStep = 0;
  bool _showAnalysis = false;
  bool _completed = false;

  // mock 数据
  final List<Map<String, dynamic>> _steps = [
    {'title': '第 1 步', 'analysis': '在三角形 ABC 中，（解析略）', 'cards': ['三角恒等变形']},
    {'title': '第 2 步', 'analysis': '（解析略）', 'cards': ['正弦定理', '化简']},
    {'title': '第 3 步', 'analysis': '（解析略）', 'cards': ['余弦定理']},
    {'title': '第 4 步', 'analysis': '（解析略）', 'cards': ['面积公式']},
  ];

  /// 点击步骤空白区 → 显示解析和按钮
  void _onStepTapped() {
    if (!_showAnalysis) {
      setState(() => _showAnalysis = true);
    }
  }

  /// 点击反馈 → 记录 + 进入下一步
  void _onFeedback(String feedback) async {
    await ProgressRepository.submitStepFeedback(
      context, widget.questionId, _currentStep + 1, feedback,
    );
    if (_currentStep + 1 >= _steps.length) {
      setState(() {
        _completed = true;
        _showAnalysis = false;
      });
    } else {
      setState(() {
        _currentStep++;
        _showAnalysis = false;
      });
    }
  }

  /// "开始"按钮 → 显示第 1 步
  void _startSolving() {
    setState(() {
      _started = true;
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('解题模式')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 题目元信息
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('第 3 题  导数第 1 讲课后练习',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: AppTheme.fontSizeTitle)),
                  const SizedBox(height: 4),
                  const Text('相关概念：体积，平面',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
                  const SizedBox(height: 12),
                  const Text('在三角形 ABC 中，（题目略）\n\n(1) 求 c 的值;',
                    style: TextStyle(fontSize: AppTheme.fontSizeBody, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // 解题区
            if (!_started)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startSolving,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('开始解题', style: TextStyle(fontSize: 16)),
                ),
              ),

            if (_started) ...[
              // 当前及已完成的步骤
              ...List.generate(_steps.length, (i) {
                if (i > _currentStep) return const SizedBox.shrink();
                final step = _steps[i];
                final isCurrent = i == _currentStep;
                return StepCard(
                  stepNumber: i + 1,
                  analysis: step['analysis'] ?? '',
                  knowledgeCards: List<String>.from(step['cards'] ?? []),
                  showAnalysis: isCurrent && _showAnalysis,
                  onTap: isCurrent ? _onStepTapped : () {},
                  feedbackWidget: isCurrent && _showAnalysis
                      ? FeedbackButtons(onFeedback: _onFeedback)
                      : null,
                );
              }),

              // 完成状态
              if (_completed) ...[
                const SizedBox(height: 8),
                Card(
                  color: AppTheme.statusGreen.withAlpha(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.cardRadius)),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('🎉 恭喜完成本题！',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.statusGreen)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 题目评价区
                const Text('题目评价', style: TextStyle(fontSize: AppTheme.fontSizeTitle, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RatingWidget(onSubmit: (d, c, e) {
                  RatingRepository.submitRating(context, widget.questionId, difficulty: d, calculation: c, elegance: e);
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('下一题'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
