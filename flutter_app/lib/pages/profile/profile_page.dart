import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared/shared.dart';
import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/daos/preference_dao.dart';
import '../../data/daos/achievement_dao.dart';
import '../../data/daos/statistics_dao.dart';
import '../../data/daos/exam_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/user_repository.dart';
import '../../domain/auth_repository.dart';
import '../../domain/preference_repository.dart';
import '../../domain/achievement_repository.dart';
import '../../domain/statistics_repository.dart';
import '../../data/api/auth_api.dart';
import '../../data/daos/sync_queue_dao.dart';
import '../../widgets/shared/format_utils.dart';
import '../router.dart';

class ProfilePage extends StatefulWidget {
  final UserRepository? userRepository;
  final PreferenceRepository? preferenceRepository;
  final StatisticsRepository? statisticsRepository;
  final AchievementRepository? achievementRepository;
  ProfilePage({
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
  late UserRepository _repo;
  late PreferenceRepository _prefRepo;
  late StatisticsRepository _statsRepo;
  late AchievementRepository _achieveRepo;
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
  int? _currentLevel;
  String? _syncSubtitle;

  /// 供 MainShell 切 Tab 时调用，触发数据刷新
  void reload() => _load();

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 每次 _load 时新鲜创建 Repository，确保拿到 DatabaseProvider 的最新连接引用
  void _initRepos() {
    _repo =
        widget.userRepository ??
        UserRepository(
          UserDao(DatabaseProvider()),
          UserApi(ApiClient()),
          QuestionDao(DatabaseProvider()),
        );
    _prefRepo =
        widget.preferenceRepository ??
        PreferenceRepository(PreferenceDao(DatabaseProvider()));
    _statsRepo =
        widget.statisticsRepository ??
        StatisticsRepository(
          StatisticsDao(DatabaseProvider()),
          questionDao: QuestionDao(DatabaseProvider()),
        );
    _achieveRepo =
        widget.achievementRepository ??
        AchievementRepository(
          AchievementDao(DatabaseProvider()),
          QuestionDao(DatabaseProvider()),
          ExamDao(DatabaseProvider()),
        );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _initRepos();
    try {
      final results = await Future.wait([
        _repo.getUserInfo(),
        _prefRepo.getCount(),
        _statsRepo.getOverview(),
        _repo.getAnswerHistoryCount(),
        _achieveRepo.unlockedCount(),
        _repo.getPointsSummary(),
        _repo.currentLevel(),
      ]);
      if (!mounted) return;
      final info = results[0] as UserInfo;
      final ps =
          results[5]
              as ({
                double earned,
                double bonus,
                double spent,
                double available,
              });
      _earnedPoints = ps.earned;
      _availablePoints = ps.available;
      _currentLevel = results[6] as int;

      // 查询同步队列状态
      String? syncSubtitle;
      try {
        final dao = SyncQueueDao(DatabaseProvider());
        final pending = await dao.getPendingCount();
        syncSubtitle = pending > 0 ? '$pending 条待同步' : null;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _info = info;
        _preferenceCount = results[1] as int;
        final overview = results[2] as StatsOverview;
        _statsTotalQuestions = overview.totalQuestions;
        _statsAccuracy = overview.accuracyPercent;
        _answerHistoryCount = results[3] as int;
        _achievementUnlocked = results[4] as int;
        _syncSubtitle = syncSubtitle;
        _loading = false;
      });
      AuditLogger.instance.page('ProfilePage', {
        'name': _info?.name,
        'gaokaoYear': _info?.gaokaoYear,
        'avatar': _info?.avatar,
      });
    } catch (e) {
      OperationLog.instance.error('profile_page_load', e);
      AuditLogger.instance.error('ProfilePage._load', e);
      if (mounted) {
        setState(() {
          _error = '加载失败，请稍后重试';
          _loading = false;
        });
      }
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
                id: _info!.id,
                name: _info!.name,
                realName: _info!.realName,
                studentId: _info!.studentId,
                avatar: avatarUrl,
                school: _info!.school,
                gaokaoYear: _info!.gaokaoYear,
                phone: _info!.phone,
              )
            : null;
        _uploading = false;
      });
      // 上传成功后写回本地 user.db
      if (_info != null) {
        await _repo.saveProfile(
          UserInfo(
            id: _info!.id,
            name: _info!.name,
            realName: _info!.realName,
            avatar: avatarUrl,
            gaokaoYear: _info!.gaokaoYear,
            phone: _info!.phone,
          ),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('头像更新成功'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      OperationLog.instance.error('profile_page_load', e);
      AuditLogger.instance.error('ProfilePage._pickAndUploadAvatar', e);
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('头像上传失败: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.error,
        ),
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
              leading: Icon(Icons.camera_alt),
              title: Text('拍照'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('从相册选择'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    // 查询待同步条目数
    int pendingCount = 0;
    try {
      pendingCount = await SyncQueueDao(DatabaseProvider()).getPendingCount();
    } catch (_) {}

    final msg = pendingCount > 0
        ? '确定要退出当前账号吗？\n有 $pendingCount 条数据尚未同步，退出后将丢失。建议先同步再退出。'
        : '确定要退出当前账号吗？';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('退出登录'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('退出', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AuthRepository(AuthApi(ApiClient())).logout();
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (e) {
      OperationLog.instance.error('profile_page_load', e);
      AuditLogger.instance.error('ProfilePage._logout', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('退出失败: $e'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('我的')),
    body: _loading
        ? const LoadingIndicator(message: '加载个人信息…')
        : _error != null
        ? ErrorPlaceholder(message: _error!, onRetry: _load)
        : AppContentContainer(
            maxWidth: AppContentWidth.dashboard,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                _buildUserHeader(),
                const SizedBox(height: AppSpacing.lg),
                _buildGrowthOverview(),
                const SizedBox(height: AppSpacing.xl),
                _buildMenuEntries(context),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
  );

  Widget _buildUserHeader() {
    final info = _info;
    final displayName = info?.realName ?? info?.name ?? '未登录';
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < AppBreakpoints.medium;
          final avatar = Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _uploading ? null : _showAvatarPicker,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: colors.primaryContainer,
                  backgroundImage:
                      info?.avatar != null && info!.avatar!.isNotEmpty
                      ? CachedNetworkImageProvider(info.avatar!)
                      : null,
                  child: info?.avatar == null || info!.avatar!.isEmpty
                      ? Text(
                          info?.realName?.isNotEmpty == true
                              ? info!.realName![0]
                              : displayName.isNotEmpty
                              ? displayName[0]
                              : '?',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: colors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _uploading ? null : _showAvatarPicker,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: _uploading
                          ? Padding(
                              padding: const EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : Icon(
                              Icons.camera_alt_outlined,
                              size: 16,
                              color: colors.onPrimary,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (info?.studentId != null)
                    AppStatusBadge(
                      label: '学号 ${info!.studentId}',
                      tone: AppStatusTone.info,
                      icon: Icons.badge_outlined,
                      compact: true,
                    ),
                  if (info?.school?.isNotEmpty == true)
                    AppStatusBadge(
                      label: info!.school!,
                      tone: AppStatusTone.neutral,
                      icon: Icons.school_outlined,
                      compact: true,
                    ),
                  if (info?.gaokaoYear != null)
                    AppStatusBadge(
                      label: '${info!.gaokaoYear} 届',
                      tone: AppStatusTone.recommendation,
                      icon: Icons.flag_outlined,
                      compact: true,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '保持学习偏好和个人资料准确，可以获得更合适的推荐内容。',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          );

          final editButton = AppButton(
            label: '编辑资料',
            icon: AppIcons.edit,
            variant: AppButtonVariant.secondary,
            fullWidth: compact,
            onPressed: () async {
              await RouterUtils.push(context, AppRoutes.profileEdit);
              if (mounted) _load();
            },
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: copy),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                editButton,
              ],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: copy),
              const SizedBox(width: AppSpacing.lg),
              editButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrowthOverview() {
    final cards = <Widget>[
      AppMetricCard(
        label: '当前等级',
        value: _currentLevel == null ? '—' : 'Lv.$_currentLevel',
        icon: Icons.trending_up_rounded,
        tone: AppStatusTone.primary,
      ),
      AppMetricCard(
        label: '可用积分',
        value: _availablePoints == null ? '—' : formatAmount(_availablePoints!),
        icon: Icons.toll_rounded,
        tone: AppStatusTone.recommendation,
      ),
      AppMetricCard(
        label: '累计做题',
        value: _statsTotalQuestions == null ? '—' : '$_statsTotalQuestions',
        icon: Icons.checklist_rounded,
        tone: AppStatusTone.info,
      ),
      AppMetricCard(
        label: '整体正确率',
        value: _statsAccuracy == null
            ? '—'
            : '${_statsAccuracy!.toStringAsFixed(0)}%',
        icon: Icons.track_changes_rounded,
        tone: AppStatusTone.success,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: '成长概览', subtitle: '学习数据与积分会在同步后自动更新。'),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= AppBreakpoints.expanded
                ? 4
                : constraints.maxWidth >= AppBreakpoints.compact
                ? 2
                : 1;
            const gap = AppSpacing.sm;
            final width = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: cards
                  .map((card) => SizedBox(width: width, child: card))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuEntries(BuildContext context) {
    final preferenceSubtitle = _preferenceCount != null
        ? '已设置 $_preferenceCount 个偏好'
        : '管理推荐范围与难度';
    final statisticsSubtitle =
        (_statsTotalQuestions != null && _statsAccuracy != null)
        ? '共 $_statsTotalQuestions 题 · 正确率 ${_statsAccuracy!.toStringAsFixed(0)}%'
        : '查看学习趋势和题型分布';
    final historySubtitle = _answerHistoryCount != null
        ? '共 $_answerHistoryCount 题'
        : '回顾近期做题记录';
    final achievementSubtitle = _achievementUnlocked != null
        ? '已解锁 $_achievementUnlocked 个'
        : '查看已经达成的学习里程碑';
    final pointsSubtitle = (_earnedPoints != null && _availablePoints != null)
        ? '累计 ${formatAmount(_earnedPoints!)} · 可用 ${formatAmount(_availablePoints!)}'
        : '查看积分获取和使用记录';

    final sections = [
      _ProfileSection(
        title: '学习工具',
        subtitle: '管理学习方式并回顾历史数据。',
        entries: [
          _ProfileEntry(
            icon: Icons.tune_rounded,
            title: '学习偏好',
            subtitle: preferenceSubtitle,
            onTap: () =>
                RouterUtils.push(context, AppRoutes.profilePreferences),
          ),
          _ProfileEntry(
            icon: Icons.insights_rounded,
            title: '学习统计',
            subtitle: statisticsSubtitle,
            onTap: () => RouterUtils.push(context, AppRoutes.statistics),
          ),
          _ProfileEntry(
            icon: Icons.history_rounded,
            title: '做题历史',
            subtitle: historySubtitle,
            onTap: () => RouterUtils.push(context, AppRoutes.profileHistory),
          ),
        ],
      ),
      _ProfileSection(
        title: '成长与奖励',
        subtitle: '查看等级、成就和积分变化。',
        entries: [
          _ProfileEntry(
            icon: Icons.emoji_events_outlined,
            title: '成就',
            subtitle: achievementSubtitle,
            onTap: () =>
                RouterUtils.push(context, AppRoutes.profileAchievements),
          ),
          _ProfileEntry(
            icon: Icons.trending_up_rounded,
            title: '等级详情',
            subtitle: _currentLevel != null
                ? '当前 Lv.$_currentLevel'
                : '查看等级规则与升级进度',
            onTap: () => RouterUtils.push(context, AppRoutes.profileLevel),
          ),
          _ProfileEntry(
            icon: Icons.toll_rounded,
            title: '积分流水',
            subtitle: pointsSubtitle,
            onTap: () => RouterUtils.push(context, AppRoutes.profilePoints),
          ),
        ],
      ),
      _ProfileSection(
        title: '应用与账号',
        subtitle: '检查同步状态、版本信息和账号安全。',
        entries: [
          _ProfileEntry(
            icon: Icons.sync_rounded,
            title: '同步状态',
            subtitle: _buildSyncSubtitle() ?? '数据已同步',
            tone: _syncSubtitle == null
                ? AppStatusTone.success
                : AppStatusTone.warning,
            onTap: () => RouterUtils.push(context, AppRoutes.syncQueue),
          ),
          _ProfileEntry(
            icon: Icons.info_outline_rounded,
            title: '关于章鱼智学',
            subtitle: '版本、隐私与开源许可',
            onTap: () => RouterUtils.push(context, AppRoutes.profileAbout),
          ),
          _ProfileEntry(
            icon: Icons.logout_rounded,
            title: '退出登录',
            subtitle: '退出当前账号并返回登录页',
            tone: AppStatusTone.error,
            onTap: _logout,
          ),
        ],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= AppBreakpoints.expanded ? 2 : 1;
        const gap = AppSpacing.md;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: sections
              .map(
                (section) => SizedBox(
                  width: width,
                  child: _ProfileSectionCard(section: section),
                ),
              )
              .toList(),
        );
      },
    );
  }

  String? _buildSyncSubtitle() => _syncSubtitle;
}

class _ProfileSection {
  const _ProfileSection({
    required this.title,
    required this.subtitle,
    required this.entries,
  });

  final String title;
  final String subtitle;
  final List<_ProfileEntry> entries;
}

class _ProfileEntry {
  const _ProfileEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tone = AppStatusTone.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final AppStatusTone tone;
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({required this.section});

  final _ProfileSection section;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppSectionHeader(
                title: section.title,
                subtitle: section.subtitle,
              ),
            ),
            Divider(height: 1, color: colors.divider),
            for (var index = 0; index < section.entries.length; index++) ...[
              _ProfileEntryTile(entry: section.entries[index]),
              if (index < section.entries.length - 1)
                Divider(height: 1, indent: 64, color: colors.divider),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileEntryTile extends StatelessWidget {
  const _ProfileEntryTile({required this.entry});

  final _ProfileEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = entry.tone == AppStatusTone.error
        ? colors.error
        : colors.primary;
    final background = entry.tone == AppStatusTone.error
        ? colors.errorContainer
        : colors.primaryContainer;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Icon(entry.icon, color: foreground, size: 21),
      ),
      title: Text(
        entry.title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: entry.tone == AppStatusTone.error ? colors.error : null,
        ),
      ),
      subtitle: Text(entry.subtitle),
      trailing: Icon(AppIcons.chevronRight, color: colors.textMuted),
      onTap: entry.onTap,
    );
  }
}
