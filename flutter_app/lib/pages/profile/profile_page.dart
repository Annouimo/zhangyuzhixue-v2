import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app_theme.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/user_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/user_repository.dart';

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

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.userRepository ?? UserRepository(UserDao(db.appDb), UserApi(ApiClient()), QuestionDao(db.assetsDb));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final info = await _repo.getUserInfo();
      if (!mounted) return;
      setState(() { _info = info; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
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
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.primaryLight,
          child: Text(info?.realName?.isNotEmpty == true ? info!.realName![0] : '?',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info?.realName ?? info?.name ?? '未登录', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            if (info?.studentId != null) Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: Text('学号 ${info!.studentId}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuEntries(BuildContext context) {
    final entries = [
      (Icons.edit, '编辑资料', () => context.push('/profile/edit')),
      (Icons.emoji_events_outlined, '成就', () => context.push('/profile/achievements')),
      (Icons.trending_up, '等级进度', () => context.push('/profile/level')),
      (Icons.monetization_on_outlined, '积分流水', () => context.push('/profile/points')),
      (Icons.replay, '做题历史', () => context.push('/profile/history')),
      (Icons.sync, '同步状态', () => context.push('/sync/queue')),
      (Icons.info_outline, '关于', () => context.push('/profile/about')),
    ];
    return Column(children: entries.map((e) => ListTile(
      leading: Icon(e.$1, color: AppColors.primary),
      title: Text(e.$2),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: e.$3,
    )).toList());
  }
}
