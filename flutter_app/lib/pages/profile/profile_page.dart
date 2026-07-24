import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/error_placeholder.dart';
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
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';
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
    _repo = widget.userRepository ?? UserRepository(
      UserDao(DatabaseProvider()), UserApi(ApiClient()), QuestionDao(DatabaseProvider()),
    );
    _prefRepo = widget.preferenceRepository ?? PreferenceRepository(PreferenceDao(DatabaseProvider()));
    _statsRepo = widget.statisticsRepository ?? StatisticsRepository(
      StatisticsDao(DatabaseProvider()),
      questionDao: QuestionDao(DatabaseProvider()),
    );
    _achieveRepo = widget.achievementRepository ?? AchievementRepository(
      AchievementDao(DatabaseProvider()), QuestionDao(DatabaseProvider()), ExamDao(DatabaseProvider()),
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
      final ps = results[5] as ({double earned, double bonus, double spent, double available});
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
        AuditLogger.instance.page('ProfilePage', {'name': _info?.name, 'gaokaoYear': _info?.gaokaoYear, 'avatar': _info?.avatar});
    } catch (e) { OperationLog.instance.error('profile_page_load', e); 
      AuditLogger.instance.error('ProfilePage._load', e);
      if (mounted) { setState(() { _error = '加载失败，请稍后重试'; _loading = false; }); }
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
      // 上传成功后写回本地 user.db
      if (_info != null) {
        await _repo.saveProfile(UserInfo(
          id: _info!.id, name: _info!.name,
          realName: _info!.realName,
          avatar: avatarUrl,
          gaokaoYear: _info!.gaokaoYear,
          phone: _info!.phone,
        ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('头像更新成功'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) { OperationLog.instance.error('profile_page_load', e); 
      AuditLogger.instance.error('ProfilePage._pickAndUploadAvatar', e);
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('头像上传失败: $e'), behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.error),
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
              onTap: () { Navigator.pop(ctx); _pickAndUploadAvatar(ImageSource.camera); },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('从相册选择'),
              onTap: () { Navigator.pop(ctx); _pickAndUploadAvatar(ImageSource.gallery); },
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消')),
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
    } catch (e) { OperationLog.instance.error('profile_page_load', e); 
      AuditLogger.instance.error('ProfilePage._logout', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('退出失败: $e'), backgroundColor: context.colors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('我的')),
    body: _loading
        ? Center(child: CircularProgressIndicator())
        : _error != null
            ? ErrorPlaceholder(message: _error!, onRetry: _load)
            : ListView(
            padding: EdgeInsets.all(AppSizes.baseSpacing),
            children: [
              _buildUserHeader(),
              SizedBox(height: 24),
              _buildMenuEntries(context),
            ],
          ),
  );

  Widget _buildUserHeader() {
    final info = _info;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () async {
          await RouterUtils.push(context,AppRoutes.profileEdit);
          if (mounted) _load();
        },
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _uploading ? null : _showAvatarPicker,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: context.colors.primaryContainer,
                      backgroundImage: info?.avatar != null && info!.avatar!.isNotEmpty
                          ? CachedNetworkImageProvider(info.avatar!)
                          : null,
                      child: info?.avatar == null || info!.avatar!.isEmpty
                          ? Text(info?.realName?.isNotEmpty == true ? info!.realName![0] : '?',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.colors.primary))
                          : null,
                    ),
                  ),
                  if (_uploading) ...[
                    SizedBox(width: 8),
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info?.realName ?? info?.name ?? '未登录',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        if (info?.studentId != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('学号 ${info!.studentId}',
                              style: TextStyle(fontSize: 11, color: context.colors.primary)),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.colors.textSecondary),
                ],
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: context.colors.border)),
                ),
                child: Text(
                  '点击编辑个人信息',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: context.colors.textMuted),
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
        ? '学习积分 ${formatAmount(_earnedPoints!)} · 可用 ${formatAmount(_availablePoints!)}'
        : null;
    final sections = [
      ('学习', [
        (Icons.tune, '学习偏好', prefSubtitle,
          () => RouterUtils.push(context,AppRoutes.profilePreferences)),
        (Icons.bar_chart, '学习统计', statsSubtitle, () => RouterUtils.push(context,AppRoutes.statistics)),
        (Icons.replay, '做题历史', historySubtitle, () => RouterUtils.push(context,AppRoutes.profileHistory)),
      ]),
      ('成长', [
        (Icons.emoji_events_outlined, '成就', achieveSubtitle, () => RouterUtils.push(context,AppRoutes.profileAchievements)),
        (Icons.trending_up, '等级', _currentLevel != null && _availablePoints != null ? 'Lv.$_currentLevel · 可用积分 ${formatAmount(_availablePoints!)}' : null, () => RouterUtils.push(context,AppRoutes.profileLevel)),
        (Icons.monetization_on_outlined, '积分流水', pointsSubtitle, () => RouterUtils.push(context,AppRoutes.profilePoints)),
      ]),
      ('系统', [
        (Icons.sync, '同步状态', _buildSyncSubtitle(), () => RouterUtils.push(context,AppRoutes.syncQueue)),
        (Icons.info_outline, '关于', null, () => RouterUtils.push(context,AppRoutes.profileAbout)),
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
            leading: Icon(icon, color: context.colors.primary),
            title: Text(title),
            subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12)) : null,
            trailing: Icon(Icons.chevron_right, color: context.colors.textSecondary),
            onTap: onTap,
          );
        });
        return [
          Padding(
            padding: EdgeInsets.fromLTRB(4, 16, 0, 4),
            child: Text(section.$1,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textSecondary),
            ),
          ),
          ...entries,
        ];
      }).toList(),
    );
  }

  String? _buildSyncSubtitle() => _syncSubtitle;
}

