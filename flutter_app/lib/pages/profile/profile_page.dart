import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app_theme.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/user_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/user_repository.dart';
import '../../../domain/auth_repository.dart';
import '../../../data/api/auth_api.dart';

class ProfilePage extends StatefulWidget {
  final UserRepository? userRepository;
  const ProfilePage({super.key, this.userRepository});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final UserRepository _repo;
  UserInfo? _info;
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.userRepository ?? UserRepository(
      UserDao(db.appDb), UserApi(ApiClient()), QuestionDao(db.assetsDb),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final info = await _repo.getUserInfo();
      if (!mounted) return;
      setState(() { _info = info; _loading = false; });
    } catch (e) {
      if (mounted) { debugPrint('_load error: $e'); setState(() => _loading = false); }
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
    return Row(
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
              const SizedBox(height: 4),
              const Text('点击头像更换', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuEntries(BuildContext context) {
    final sections = [
      ('学习', [
        (Icons.tune, '学习偏好', () => context.push('/profile/preferences')),
        (Icons.edit, '编辑资料', () => context.push('/profile/edit')),
        (Icons.bar_chart, '学习统计', () => context.push('/statistics')),
        (Icons.replay, '做题历史', () => context.push('/profile/history')),
      ]),
      ('成长', [
        (Icons.emoji_events_outlined, '成就', () => context.push('/profile/achievements')),
        (Icons.trending_up, '等级进度', () => context.push('/profile/level')),
        (Icons.monetization_on_outlined, '积分流水', () => context.push('/profile/points')),
      ]),
      ('系统', [
        (Icons.sync, '同步状态', () => context.push('/sync/queue')),
        (Icons.info_outline, '关于', () => context.push('/profile/about')),
        (Icons.logout, '退出登录', _logout),
      ]),
    ];
    return Column(
      children: sections.expand((section) {
        final entries = section.$2.map((e) => ListTile(
          leading: Icon(e.$1, color: AppColors.primary),
          title: Text(e.$2),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onTap: e.$3,
        ));
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
