import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/feedback_buttons.dart';
import '../widgets/knowledge_card_widget.dart';
import '../widgets/rating_widget.dart';

/// 解题模式（核心交互页面）
class SolvePage extends StatefulWidget {
  final int questionId;

  const SolvePage({super.key, required this.questionId});

  @override
  State<SolvePage> createState() => _SolvePageState();
}

class _SolvePageState extends State<SolvePage> {
  int _currentStep = 0;       // -1 = 尚未开始, 0..3 = 步骤索引
  bool _showAnalysis = false;
  bool _completed = false;

  // mock 数据
  final List<Map<String, String>> _steps = [
    {'title': '第 1 步', 'analysis': '在三角形 ABC 中，（解析略）'},
    {'title': '第 2 步', 'analysis': '（解析略）'},
    {'title': '第 3 步', 'analysis': '（解析略）'},
    {'title': '第 4 步', 'analysis': '（解析略）'},
  ];

  final List<List<String>> _stepCards = [
    ['三角恒等变形'],
    ['正弦定理', '化简'],
    ['余弦定理'],
    ['面积公式'],
  ];

  final List<Map<String, String>> _cardDetails = [
    {'三角恒等变形': '三角恒等变形是利用三角函数的基本恒等式进行变换的方法。\n常用公式：sin²α + cos²α = 1，sin(α±β) = sinαcosβ ± cosαsinβ'},
    {'正弦定理': '正弦定理：在任意三角形中，各边与其对角的正弦之比相等。\na/sin A = b/sin B = c/sin C = 2R'},
    {'化简': '通过代数运算简化表达式。\n常用策略：提取公因式、合并同类项、通分。'},
    {'余弦定理': '余弦定理：a² = b² + c² - 2bc·cos A\n用于已知两边及其夹角求第三边。'},
    {'面积公式': '三角形面积：S = (1/2)·ab·sin C\n也可以使用海伦公式：S = √[s(s-a)(s-b)(s-c)]'},
  ];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _showAnalysis = false;
      });
    } else {
      setState(() => _completed = true);
    }
  }

  void _onStepTapped() {
    if (!_showAnalysis) {
      setState(() => _showAnalysis = true);
    }
  }

  void _onFeedback(String feedback) {
    // Toast via repository already handled by the caller
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _showAnalysis = false;
      });
    } else {
      setState(() => _completed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('解题模式 第 3 题 导数第 1 讲课后练习')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 题目元信息 + 题干（无白色卡片容器）
            const Text('相关概念：体积，平面',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontSizeSmall)),
            const SizedBox(height: 12),
            const Text('在三角形 ABC 中，（题目略）\n\n(1) 求 c 的值;',
              style: TextStyle(fontSize: AppTheme.fontSizeBody, height: 1.6)),
            const SizedBox(height: 24),

            // 解题区
            ...List.generate(_steps.length, (i) {
              if (i > _currentStep) return const SizedBox.shrink();
              final isCurrent = i == _currentStep;
              return _buildStep(i, isCurrent);
            }),

            // 完成状态
            if (_completed) ...[
              const SizedBox(height: 16),
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
              const Text('评价这道题', style: TextStyle(fontSize: AppTheme.fontSizeTitle, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RatingWidget(onSubmit: (d, c, e) {
                // 调用 repository submitRating via callback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('正在进行提交评分操作，需要写入评分数据')),
                );
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
        ),
      ),
    );
  }

  Widget _buildStep(int index, bool isCurrent) {
    final step = _steps[index];
    final cards = _stepCards[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题 + 知识卡片（右侧对齐）
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontSizeTitle)),
              const Spacer(),
              // 知识卡片标签（右侧）
              ...cards.map((c) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: KnowledgeCardWidget(
                  title: c,
                  content: _cardDetails.firstWhere(
                    (d) => d.containsKey(c),
                    orElse: () => {c: '（知识卡片详细内容略）'},
                  )[c] ?? '（知识卡片详细内容略）',
                ),
              )),
            ],
          ),
          const SizedBox(height: 8),

          // 解析文本 + 反馈按钮（条件显示）
          if (isCurrent && _showAnalysis) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(step['analysis'] ?? '', style: const TextStyle(height: 1.6)),
            ),
            const SizedBox(height: 8),
            FeedbackButtons(onFeedback: _onFeedback),
          ],

          // 右箭头（当前步骤未展开解析时显示）
          if (isCurrent && !_showAnalysis)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryColor),
                onPressed: _onStepTapped,
              ),
            ),
        ],
      ),
    );
  }
}
