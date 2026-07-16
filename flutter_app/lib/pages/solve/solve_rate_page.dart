import 'package:flutter/material.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../widgets/shared/app_toast.dart';
import '../../widgets/shared/format_utils.dart';
import '../../app_theme.dart';
import '../../data/daos/rating_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/system_config_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/rating_repository.dart';
import '../../data/debug/audit_logger.dart';
import '../../../data/debug/operation_log.dart';

/// 评分页（3维×10星）
class SolveRatePage extends StatefulWidget {
  final int questionId;
  final RatingRepository? ratingRepository;

  const SolveRatePage({
    super.key,
    required this.questionId,
    this.ratingRepository,
  });
  @override
  State<SolveRatePage> createState() => _SolveRatePageState();
}

class _SolveRatePageState extends State<SolveRatePage> {
  int _difficulty = 0;
  int _calculation = 0;
  int _elegance = 0;
  double _algoDifficulty = 0;
  double _algoCalculation = 0;
  bool _submitted = false;
  bool _saving = false;
  bool _loading = true;
  String? _error;
  double _rewardPoints = 0.3;
  late final RatingRepository _ratingRepo;

  @override
  void initState() {
    super.initState();
    _ratingRepo = widget.ratingRepository ?? RatingRepository(
      RatingDao(DatabaseProvider()),
      QuestionDao(DatabaseProvider()),
    );
    _loadRating();
  }

  Future<void> _loadRating() async {
    try {
      // 加载奖励积分配置（独立 try-catch，失败不影响主流程）
      try {
        final cfg = SystemConfigDao(DatabaseProvider());
        _rewardPoints = await cfg.getDouble('question_rating_reward', 0.3);
      } catch (_) {} 

      final rating = await _ratingRepo.getRating(widget.questionId);
      setState(() {
        _algoDifficulty = rating.algorithmDifficulty;
        _algoCalculation = rating.algorithmCalculation;
        if (rating.userDifficulty != null) {
          _difficulty = rating.userDifficulty!.round();
          _calculation = rating.userCalculation?.round() ?? 5;
          _elegance = rating.userElegance?.round() ?? 5;
          _submitted = true;
        }
        _loading = false;
      });
      AuditLogger.instance.page('SolveRatePage', {'difficulty': _difficulty, 'calcScore': _calculation});
    } catch (e) { OperationLog.instance.error('solve_rate_page_load', e); 
      AuditLogger.instance.error('SolveRatePage._loadRating', e);
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await _ratingRepo.submitRating(
        questionId: widget.questionId,
        difficulty: _difficulty.toDouble(),
        calculation: _calculation.toDouble(),
        elegance: _elegance.toDouble(),
      );
      setState(() { _submitted = true; _saving = false; });
      OperationLog.instance.action('rate', 'submitted qid=${widget.questionId}');
      if (!mounted) return;
      AppToast.show(context,
        icon: Icons.check_circle, message: '评分已提交',
        backgroundColor: AppColors.success,
      );
    } catch (e) { OperationLog.instance.error('solve_rate_page_load', e); 
      AuditLogger.instance.error('SolveRatePage._submit', e);
      setState(() => _saving = false);
      if (!mounted) return;
      AppToast.show(context,
        icon: Icons.error, message: '评分提交失败，请重试',
        backgroundColor: AppColors.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('评分')),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('加载失败', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () { setState(() { _error = null; _loading = true; }); _loadRating(); }, child: const Text('重试')),
                ]))
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('请为这道题打分', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('你的评分帮助其他同学更好地了解题目难度', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  _StarRating(label: '难度', value: _difficulty, note: '', algorithmScore: _algoDifficulty > 0 ? _algoDifficulty : null, max: 10, onChanged: (v) => setState(() => _difficulty = v)),
                  const SizedBox(height: 20),
                  _StarRating(label: '计算量', value: _calculation, note: '', algorithmScore: _algoCalculation > 0 ? _algoCalculation : null, max: 10, onChanged: (v) => setState(() => _calculation = v)),
                  const SizedBox(height: 20),
                  _StarRating(label: '优雅度', value: _elegance, note: '你的主观感受', max: 10, onChanged: (v) => setState(() => _elegance = v)),
                  const SizedBox(height: 12),
                  const Text('可跳过，不影响学习记录 · 绿色为算法综合评估分',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (_submitted || _saving) ? null : _submit,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_submitted ? '已评分' : '提交评分（可获得 +$_rewardPoints 赠送积分）'),
                  ),
                  if (_submitted) ...[
                    const SizedBox(height: 12),
                    Center(child: TextButton(
                      onPressed: () => setState(() => _submitted = false),
                      child: const Text('修改评分'),
                    )),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final String label;
  final int value;
  final String note;
  final int max;
  final double? algorithmScore;
  final ValueChanged<int> onChanged;
  const _StarRating({required this.label, required this.value, required this.note, required this.max, this.algorithmScore, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          if (algorithmScore != null && algorithmScore! > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('算法: ${formatAmount(algorithmScore!)}',
                style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(note, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ]),
        const SizedBox(height: 10),
        Row(children: List.generate(max, (i) {
          final filled = i < value;
          return GestureDetector(
            onTap: () => onChanged(i + 1),
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(filled ? Icons.star : Icons.star_border,
                color: filled ? AppColors.warning : Colors.grey[300], size: 28),
            ),
          );
        })),
        const SizedBox(height: 4),
        Text(value > 0 ? '$value / $max' : '—', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }
}

