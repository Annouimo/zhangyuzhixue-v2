import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app_theme.dart';
import '../../../widgets/shared/error_placeholder.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/user_dao.dart';
import '../../../data/daos/preference_dao.dart';
import '../../../data/daos/achievement_dao.dart';
import '../../../data/daos/statistics_dao.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/user_repository.dart';
import '../../../domain/auth_repository.dart';
import '../../../domain/preference_repository.dart';
import '../../../domain/achievement_repository.dart';
import '../../../domain/statistics_repository.dart';
import '../../../data/api/auth_api.dart';
import '../../data/debug/audit_logger.dart';

class ProfilePage extends StatefulWidget {
  final UserRepository? userRepository;
  final PreferenceRepository? preferenceRepository;
  final StatisticsRepository? statisticsRepository;
  final AchievementRepository? achievementRepository;
  const ProfilePage({
    super.key,
    this.userRepository,
    this.preferenceRepository,
    this.statisticsRepository,
    this.achievementRepository,
  });

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  late final UserRepository _repo;
  late final PreferenceRepository _prefRepo;
  late final StatisticsRepository _statsRepo;
  late final AchievementRepository _achieveRepo;
  UserInfo? _info;
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  int? _preferenceCount;
  int? _statsTotalQuestions;
  double? _statsAccuracy;
  int? _answerHistoryCount;
  int? _achievementUnlocked;
  double? _earnedPoints;
  double? _availablePoints;

  /// 供 MainShell 切 Tab 时调用，触发数据刷新
  void reload() => _load();

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.userRepository ?? UserRepository(
      UserDao(db.appDb), UserApi(ApiClient()), QuestionDao(db.assetsDb),
    );
    _prefRepo = widget.preferenceRepository ?? PreferenceRepository(PreferenceDao(db.appDb));
    _statsRepo = widget.statisticsRepository ?? StatisticsRepository(
      StatisticsDao(db.appDb),
      questionDao: QuestionDao(db.assetsDb),
    );
    _achieveRepo = widget.achievementRepository ?? AchievementRepository(
      AchievementDao(db.appDb), QuestionDao(db.assetsDb), ExamDao(db.appDb),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getUserInfo(),
        _prefRepo.getCount(),
        _statsRepo.getOverview(),
        _repo.getAnswerHistoryCount(),
        _achieveRepo.unlockedCount(),
        _repo.earnedPoints(),
        _repo.availablePoints(),
      ]);
      if (!mounted) return;
      final info = results[0] as UserInfo;
      setState(() {
        _info = info;
        _preferenceCount = results[1] as int;
        final overview = results[2] as StatsOverview;
        _statsTotalQuestions = overview.totalQuestions;
        _statsAccuracy = overview.accuracyPercent;
        _answerHistoryCount = results[3] as int;
        _achievementUnlocked = results[4] as int;
        _earnedPoints = results[5] as double;
        _availablePoints = results[6] as double;
        _loading = false;
      });
      AuditLogger.instance.page('ProfilePage', {'name': _info?.name, 'gaokaoYear': _info?.gaokaoYear, 'avatar': _info?.avatar});
    } catch (e) {
      AuditLogger.instance.error('ProfilePage._load', e);
      if (mounted) { debugPrint('_load error: $e'); setState(() { _error = e.toString(); _loading = false; }); }
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final avatarUrl = await _repo.uploadAvatar(picked.path);
      if (!mounted) return;
      setState(() {
        _info = _info != null
            ? UserInfo(
                id: _info!.id, name: _info!.name,
                realName: _info!.realName, studentId: _info!.studentId,
                avatar: avatarUrl,
                school: _info!.school, gaokaoYear: _info!.gaokaoYear,
                phone: _info!.phone,
              )
            : null;
        _uploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像更新成功'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      AuditLogger.instance.error('ProfilePage._pickAndUploadAvatar', e);
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('头像上传失败: $e'), behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error),
      );
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () { Navigator.pop(ctx); _pickAndUploadAvatar(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () { Navigator.pop(ctx); _pickAndUploadAvatar(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？\n未同步的数据将会丢失。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AuthRepository(AuthApi(ApiClient())).logout();
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      AuditLogger.instance.error('ProfilePage._logout', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('退出失败: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('我的')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? ErrorPlaceholder(message: _error!, onRetry: _load)
            : ListView(
            padding: const EdgeInsets.all(AppSizes.baseSpacing),
            children: [
              _buildUserHeader(),
              const SizedBox(height: 24),
              _buildMenuEntries(context),
            ],
          ),
  );

  Widget _buildUserHeader() {
    final info = _info;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/profile/edit'),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _uploading ? null : _showAvatarPicker,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: info?.avatar != null && info!.avatar!.isNotEmpty
                          ? (info.avatar!.startsWith('http')
                              ? CachedNetworkImageProvider(info.avatar!)
                              : NetworkImage(info.avatar!))
                          : null,
                      child: info?.avatar == null || info!.avatar!.isEmpty
                          ? Text(info?.realName?.isNotEmpty == true ? info!.realName![0] : '?',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary))
                          : null,
                    ),
                  ),
                  if (_uploading) ...[
                    const SizedBox(width: 8),
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info?.realName ?? info?.name ?? '未登录',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        if (info?.studentId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('学号 ${info!.studentId}',
                              style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: const Text(
                  '点击编辑个人信息 ✏️',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuEntries(BuildContext context) {
    final prefSubtitle = _preferenceCount != null
        ? '已设置 $_preferenceCount 个偏好'
        : null;
    final statsSubtitle = (_statsTotalQuestions != null && _statsAccuracy != null)
        ? '共 $_statsTotalQuestions 题 · 正确率 ${_statsAccuracy!.toStringAsFixed(0)}%'
        : null;
    final historySubtitle = _answerHistoryCount != null
        ? '共 $_answerHistoryCount 题'
        : null;
    final achieveSubtitle = _achievementUnlocked != null
        ? '已解锁 $_achievementUnlocked 个'
        : null;
    final pointsSubtitle = (_earnedPoints != null && _availablePoints != null)
        ? '学习积分 $_earnedPoints · 可用 $_availablePoints'
        : null;
    final sections = [
      ('学习', [
        (Icons.tune, '学习偏好', prefSubtitle,
          () => context.push('/profile/preferences')),
        (Icons.bar_chart, '学习统计', statsSubtitle, () => context.push('/statistics')),
        (Icons.replay, '做题历史', historySubtitle, () => context.push('/profile/history')),
      ]),
      ('成长', [
        (Icons.emoji_events_outlined, '成就', achieveSubtitle, () => context.push('/profile/achievements')),
        (Icons.trending_up, '等级进度', null, () => context.push('/profile/level')),
        (Icons.monetization_on_outlined, '积分流水', pointsSubtitle, () => context.push('/profile/points')),
      ]),
      ('系统', [
        (Icons.sync, '同步状态', null, () => context.push('/sync/queue')),
        (Icons.info_outline, '关于', null, () => context.push('/profile/about')),
        (Icons.logout, '退出登录', null, _logout),
      ]),
    ];
    return Column(
      children: sections.expand((section) {
        final entries = section.$2.map((e) {
          final icon = e.$1;
          final title = e.$2;
          final subtitle = e.$3;
          final onTap = e.$4 as VoidCallback?;
          return ListTile(
            leading: Icon(icon, color: AppColors.primary),
            title: Text(title),
            subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: onTap,
          );
        });
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 0, 4),
            child: Text(section.$1,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          ...entries,
        ];
      }).toList(),
    );
  }
}
