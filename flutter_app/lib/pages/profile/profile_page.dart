import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared/shared.dart';
import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/daos/achievement_dao.dart';
import '../../data/daos/statistics_dao.dart';
import '../../data/daos/exam_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/user_repository.dart';
import '../../domain/achievement_repository.dart';
import '../../domain/statistics_repository.dart';
import '../../data/daos/sync_queue_dao.dart';
import '../../widgets/shared/format_utils.dart';
import '../router.dart';

class ProfilePage extends StatefulWidget {
  final UserRepository? userRepository;
  final StatisticsRepository? statisticsRepository;
  final AchievementRepository? achievementRepository;
  const ProfilePage({
    super.key,
    this.userRepository,
    this.statisticsRepository,
    this.achievementRepository,
  });

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  late UserRepository _repo;
  late StatisticsRepository _statsRepo;
  late AchievementRepository _achieveRepo;
  UserInfo? _info;
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  int? _statsTotalQuestions;
  double? _statsAccuracy;
  int? _achievementUnlocked;
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
      final info = await _repo.getUserInfo();
      final summaries = await Future.wait<Object?>([
        _optional(_statsRepo.getOverview()),
        _optional(_achieveRepo.unlockedCount()),
        _optional(_repo.getPointsSummary()),
        _optional(_repo.currentLevel()),
      ]);
      if (!mounted) return;
      final ps =
          summaries[2]
              as ({
                double earned,
                double bonus,
                double spent,
                double available,
              })?;

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
        final overview = summaries[0] as StatsOverview?;
        _statsTotalQuestions = overview?.totalQuestions;
        _statsAccuracy = overview?.accuracyPercent;
        _achievementUnlocked = summaries[1] as int?;
        _availablePoints = ps?.available;
        _currentLevel = summaries[3] as int?;
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

  Future<T?> _optional<T>(Future<T> future) async {
    try {
      return await future;
    } catch (error) {
      OperationLog.instance.error('profile_summary_load', error);
      return null;
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
                _buildPrimaryEntries(context),
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
                '学习记录会帮助系统安排更合适的推荐内容。',
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

  Widget _buildPrimaryEntries(BuildContext context) {
    final archiveSubtitle = _statsTotalQuestions == null
        ? '复盘、统计与做题记录'
        : '累计 $_statsTotalQuestions 题 · 正确率 ${_statsAccuracy?.toStringAsFixed(0) ?? '—'}%';
    final growthParts = <String>[
      if (_currentLevel != null) 'Lv.$_currentLevel',
      if (_availablePoints != null) '${formatAmount(_availablePoints!)} 积分',
      if (_achievementUnlocked != null) '$_achievementUnlocked 项成就',
    ];
    final growthSubtitle = growthParts.isEmpty
        ? '等级、积分与成就'
        : growthParts.join(' · ');

    final entries = [
      AppNavigationCard(
        icon: Icons.folder_copy_outlined,
        title: '学习档案',
        subtitle: archiveSubtitle,
        onTap: () => RouterUtils.push(context, AppRoutes.studyArchive),
      ),
      AppNavigationCard(
        icon: Icons.workspace_premium_outlined,
        title: '成长中心',
        subtitle: growthSubtitle,
        tone: AppStatusTone.recommendation,
        onTap: () => RouterUtils.push(context, AppRoutes.growthCenter),
      ),
      AppNavigationCard(
        icon: Icons.rate_review_outlined,
        title: '内容贡献',
        subtitle: '投稿新题、查看审核进度',
        tone: AppStatusTone.info,
        onTap: () => RouterUtils.push(context, AppRoutes.contributions),
      ),
      AppNavigationCard(
        icon: Icons.settings_outlined,
        title: '设置',
        subtitle: _syncSubtitle == null ? '常用范围、同步与账号管理' : _syncSubtitle!,
        tone: _syncSubtitle == null
            ? AppStatusTone.primary
            : AppStatusTone.warning,
        onTap: () => RouterUtils.push(context, AppRoutes.settings),
      ),
    ];

    return AppResponsiveCardGrid(children: entries);
  }
}
