import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../data/daos/preference_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/database/database_provider.dart';
import '../domain/preference_repository.dart';
import 'exam/widgets/filter_panel.dart';
import 'router.dart';
import '../widgets/shared/loading_indicator.dart';

/// 首次引导流程 — 欢迎弹窗 → 偏好设置 → 跳首页
class PreferenceWelcomePage extends StatefulWidget {
  final PreferenceRepository? preferenceRepository;
  final QuestionDao? questionDao;
  const PreferenceWelcomePage({super.key, this.preferenceRepository, this.questionDao});

  @override State<PreferenceWelcomePage> createState() => _PreferenceWelcomePageState();
}

class _PreferenceWelcomePageState extends State<PreferenceWelcomePage> {
  late final PreferenceRepository _repo;
  late final QuestionDao _qDao;
  bool _showWelcome = true;
  bool _saving = false;
  final _nameCtrl = TextEditingController(text: '我的偏好');

  Set<String> _years = {};
  Set<String> _regions = {};
  Set<String> _conceptTags = {};

  // 筛选选项（内存缓存）
  List<String>? _yearOpts;
  List<String>? _regionOpts;
  List<String>? _tagOpts;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.preferenceRepository ?? PreferenceRepository(PreferenceDao(db.appDb));
    _qDao = widget.questionDao ?? QuestionDao(db.assetsDb);
    _loadOpts();
  }

  Future<void> _loadOpts() async {
    try {
      final years = (await _qDao.getDistinctYears()).map((y) => y.toString()).toList();
      final regions = await _qDao.getDistinctRegions();
      final tags = (await _qDao.getAllConceptTags()).map((t) => t.name).toList();
      if (!mounted) return;
      setState(() { _yearOpts = years; _regionOpts = regions; _tagOpts = tags; });
    } catch (_) {}
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入偏好名称'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.save(
        name: _nameCtrl.text.trim(),
        filter: PreferenceFilter(
          years: _years.toList(),
          regions: _regions.toList(),
          conceptTags: _conceptTags.toList(),
        ),
      );
      if (!mounted) return;
      context.go(AppRoutes.mainShell);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请重试'), behavior: SnackBarBehavior.floating),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) return _buildWelcome();

    return Scaffold(
      appBar: AppBar(title: const Text('设置学习偏好')),
      body: _yearOpts == null
          ? const LoadingIndicator()
          : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '偏好名称',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  enabled: !_saving,
                ),
                const SizedBox(height: 20),
                FilterPanel(
                  yearOptions: _yearOpts!,
                  regionOptions: _regionOpts!,
                  conceptTagOptions: _tagOpts ?? [],
                  onChanged: (y, r, t, ct, _, _, _, _) {
                    _years = y; _regions = r; _conceptTags = ct;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('💾 保存偏好'),
                  ),
                ),
              ],
            )),
    );
  }

  Widget _buildWelcome() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            const Text('欢迎加入章鱼智学！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('首次注册赠送 +10 积分', style: TextStyle(fontSize: 16, color: AppColors.success)),
            const SizedBox(height: 4),
            const Text('可用于组卷等消费功能', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => setState(() => _showWelcome = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('👌 开始设置学习偏好'),
            ),
          ]),
        ),
      ),
    );
  }
}
