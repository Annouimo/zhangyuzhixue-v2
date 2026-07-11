import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../data/daos/rating_dao.dart';
import '../../data/daos/question_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/rating_repository.dart';

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
  int _difficulty = 5;
  int _calculation = 5;
  int _elegance = 5;
  double _algoDifficulty = 0;
  double _algoCalculation = 0;
  bool _submitted = false;
  bool _saving = false;
  bool _loading = true;
  late final RatingRepository _ratingRepo;

  @override
  void initState() {
    super.initState();
    _ratingRepo = widget.ratingRepository ?? RatingRepository(
      RatingDao(DatabaseProvider().appDb),
      QuestionDao(DatabaseProvider().assetsDb),
    );
    _loadRating();
  }

  Future<void> _loadRating() async {
    try {
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
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _algoNote(String label, double algoScore) {
    if (algoScore <= 0) return '';
    return '$label · 算法评分: ${algoScore.toStringAsFixed(1)}';
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('评分已提交'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('评分提交失败，请重试'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('评分')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('请为这道题打分', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('你的评分帮助其他同学更好地了解题目难度', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  _StarRating(label: '难度', value: _difficulty, note: _algoNote('难度', _algoDifficulty), max: 10, onChanged: (v) => setState(() => _difficulty = v)),
                  const SizedBox(height: 20),
                  _StarRating(label: '计算量', value: _calculation, note: _algoNote('计算量', _algoCalculation), max: 10, onChanged: (v) => setState(() => _calculation = v)),
                  const SizedBox(height: 20),
                  _StarRating(label: '优雅度', value: _elegance, note: '你的主观感受', max: 10, onChanged: (v) => setState(() => _elegance = v)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: (_submitted || _saving) ? null : _submit,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_submitted ? '已评分' : '提交评分'),
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
  final ValueChanged<int> onChanged;
  const _StarRating({required this.label, required this.value, required this.note, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
        Text('$value / $max', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }
}
