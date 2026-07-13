import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_theme.dart';
import '../data/daos/preference_dao.dart';
import '../data/daos/question_dao.dart';
import '../data/daos/user_dao.dart';
import '../data/api/api_client.dart';
import '../data/api/user_api.dart';
import '../data/database/database_provider.dart';
import '../domain/preference_repository.dart';
import '../domain/user_repository.dart';
import 'exam/widgets/filter_panel.dart';
import 'router.dart';
import '../widgets/shared/loading_indicator.dart';
import '../data/debug/audit_logger.dart';

/// 首次引导流程 — 欢迎弹窗 → 偏好设置 → 跳首页
class PreferenceWelcomePage extends StatefulWidget {
  final PreferenceRepository? preferenceRepository;
  final QuestionDao? questionDao;
  final UserRepository? userRepository;
  const PreferenceWelcomePage({super.key, this.preferenceRepository, this.questionDao, this.userRepository});

  @override State<PreferenceWelcomePage> createState() => _PreferenceWelcomePageState();
}

class _PreferenceWelcomePageState extends State<PreferenceWelcomePage> {
  late final PreferenceRepository _repo;
  late final QuestionDao _qDao;
  late final UserRepository _userRepo;
  bool _saving = false;
  final _nameCtrl = TextEditingController(text: '我的偏好');

  Set<String> _years = {};
  Set<String> _regions = {};
  Set<String> _types = {};
  Set<String> _conceptTags = {};
  double _diffMin = 0, _diffMax = 10, _calcMin = 0, _calcMax = 10;

  // 筛选选项（内存缓存）
  List<String>? _yearOpts;
  List<String>? _regionOpts;
  List<String>? _tagOpts;

  // 积分值
  double _bonusPoints = 0;
  bool _bonusLoaded = false;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.preferenceRepository ?? PreferenceRepository(PreferenceDao(db.appDb));
    _qDao = widget.questionDao ?? QuestionDao(db.assetsDb);
    _userRepo = widget.userRepository ?? UserRepository(UserDao(db.appDb), UserApi(ApiClient()), _qDao);
    _loadOpts();
    _loadBonus();
    // 页面构建完成后弹出欢迎 Dialog
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcome(context));
  }

  Future<void> _loadOpts() async {
    try {
      final years = (await _qDao.getDistinctYears()).map((y) => y.toString()).toList();
      final regions = await _qDao.getDistinctRegions();
      final tags = (await _qDao.getAllConceptTags()).map((t) => t.name).toList();
      if (!mounted) return;
      setState(() { _yearOpts = years; _regionOpts = regions; _tagOpts = tags; });
      AuditLogger.instance.page('PreferenceWelcomePage', {'loaded': _yearOpts != null});
    } catch (_) {}
  }

  Future<void> _loadBonus() async {
    try {
      final pts = await _userRepo.bonusPoints();
      if (!mounted) return;
      setState(() { _bonusPoints = pts; _bonusLoaded = true; });
    } catch (e) {
      AuditLogger.instance.error('PreferenceWelcomePage._loadBonus', e);
      if (!mounted) return;
      setState(() => _bonusLoaded = true);
    }
  }

  void _showWelcome(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          // 遮罩点击或跳过 → 跳首页
          context.go(AppRoutes.mainShell);
        },
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('欢迎加入章鱼智学！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('首次注册赠送 ${_bonusLoaded ? _bonusPoints.toStringAsFixed(0) : '...'} 积分',
              style: const TextStyle(fontSize: 16, color: AppColors.success)),
            const SizedBox(height: 4),
            const Text('可用于组卷等消费功能', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () { Navigator.of(ctx).pop(); },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('👌 开始设置学习偏好'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go(AppRoutes.mainShell);
              },
              child: const Text('跳过', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ]),
        ),
      ),
    );
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
          types: _types.toList(),
          diffMin: _diffMin,
          diffMax: _diffMax,
          calcMin: _calcMin,
          calcMax: _calcMax,
        ),
      );
      if (!mounted) return;
      context.go(AppRoutes.mainShell);
    } catch (e) {
      AuditLogger.instance.error('PreferenceWelcomePage._save', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败，请重试'), behavior: SnackBarBehavior.floating),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onChanged: (y, r, t, ct, et, kc, dmn, dmx, cmn, cmx) {
                    _years = y; _regions = r; _types = t; _conceptTags = ct;
                    _diffMin = dmn; _diffMax = dmx; _calcMin = cmn; _calcMax = cmx;
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
}
