import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/theme/app_tokens.dart';
import 'package:shared/widgets/loading_indicator.dart';
import 'package:shared/widgets/app_page_layout.dart';
import 'package:shared/widgets/app_card.dart';
import 'package:shared/widgets/app_button.dart';
import '../../data/api/api_client.dart';
import '../../data/api/user_api.dart';
import '../../data/daos/question_dao.dart';
import '../../data/daos/user_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/user_repository.dart';
import 'package:shared/debug/audit_logger.dart';
import 'package:shared/debug/operation_log.dart';

/// 编辑资料页
class ProfileEditPage extends StatefulWidget {
  final UserRepository? userRepository;
  const ProfileEditPage({super.key, this.userRepository});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final UserRepository _repo;
  final _nameCtrl = TextEditingController();
  UserInfo? _info;
  String? _avatarUrl;
  String? _gaokaoYear;
  bool _loading = true;
  bool _uploading = false;
  bool _saving = false;

  static const _gaokaoYears = ['2025', '2026', '2027', '2028'];

  @override
  void initState() {
    super.initState();
    _repo =
        widget.userRepository ??
        UserRepository(
          UserDao(DatabaseProvider()),
          UserApi(ApiClient()),
          QuestionDao(DatabaseProvider()),
        );
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await _repo.getUserInfo();
      if (!mounted) return;
      setState(() {
        _info = info;
        _nameCtrl.text = info.realName ?? info.name;
        _avatarUrl = info.avatar;
        _gaokaoYear = info.gaokaoYear;
        _loading = false;
      });
      AuditLogger.instance.page('ProfileEditPage', {
        'name': _nameCtrl.text,
        'gaokaoYear': _gaokaoYear,
        'loading': _loading,
      });
    } catch (e) {
      AuditLogger.instance.error('ProfileEditPage._load', e);
      OperationLog.instance.error('ProfileEditPage._load', e);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_info == null || _saving) return;
    setState(() => _saving = true);
    try {
      await _repo.saveProfile(
        UserInfo(
          id: _info!.id,
          name: _info!.name,
          realName: _nameCtrl.text,
          avatar: _avatarUrl,
          gaokaoYear: _gaokaoYear,
          phone: _info!.phone,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('个人信息已保存'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (error) {
      AuditLogger.instance.error('ProfileEditPage._save', error);
      OperationLog.instance.error('ProfileEditPage._save', error);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存失败，请稍后重试'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _saving = false);
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
      final url = await _repo.uploadAvatar(picked.path);
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _uploading = false;
      });
      // 上传成功后写回本地 user.db，保证离开再回来也能显示新头像
      if (_info != null) {
        await _repo.saveProfile(
          UserInfo(
            id: _info!.id,
            name: _info!.name,
            realName: _info!.realName,
            avatar: url,
            gaokaoYear: _gaokaoYear,
            phone: _info!.phone,
          ),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('头像更新成功'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      AuditLogger.instance.error('ProfileEditPage._pickAndUploadAvatar', e);
      OperationLog.instance.error('ProfileEditPage._pickAndUploadAvatar', e);
      if (mounted) {
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
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
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
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('个人信息')),
      body: _loading
          ? const LoadingIndicator(message: '正在加载个人信息…')
          : AppContentContainer(
              maxWidth: AppContentWidth.standard,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide =
                          constraints.maxWidth >= AppBreakpoints.medium;
                      final avatar = _buildAvatarCard();
                      final form = _buildProfileForm();
                      if (!wide) {
                        return Column(
                          children: [
                            avatar,
                            const SizedBox(height: AppSpacing.lg),
                            form,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 280, child: avatar),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(child: form),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: '保存修改',
                    icon: Icons.save_outlined,
                    onPressed: _info == null || _saving ? null : _save,
                    isLoading: _saving,
                    fullWidth: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarCard() {
    final colors = context.colors;
    return AppCard(
      onTap: _uploading ? null : _showAvatarPicker,
      semanticLabel: '更换头像',
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: colors.surfaceSubtle,
                backgroundImage: _avatarUrl == null
                    ? null
                    : NetworkImage(_avatarUrl!),
                child: _avatarUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 44,
                        color: colors.textMuted,
                      )
                    : null,
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 3),
                ),
                child: _uploading
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: colors.onPrimary,
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('头像', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '点击选择拍照或相册图片',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: '基本信息', subtitle: '可编辑字段会同步到你的学生端资料。'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '昵称',
              hintText: '输入昵称',
              prefixIcon: Icon(Icons.face_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _gaokaoYear,
            decoration: const InputDecoration(
              labelText: '高考年份',
              prefixIcon: Icon(Icons.calendar_month_outlined),
            ),
            items: _gaokaoYears
                .map(
                  (year) =>
                      DropdownMenuItem(value: year, child: Text('$year 年')),
                )
                .toList(),
            onChanged: (value) => setState(() => _gaokaoYear = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: context.colors.divider),
          const SizedBox(height: AppSpacing.md),
          _buildReadOnlyField(
            label: '真实姓名',
            value: _info?.realName ?? '—',
            icon: Icons.badge_outlined,
            helper: '如需修改，请联系管理员。',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildReadOnlyField(
            label: '学号',
            value: _info?.studentId ?? '—',
            icon: Icons.numbers_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildReadOnlyField(
            label: '手机号',
            value: _info?.phone ?? '—',
            icon: Icons.phone_outlined,
            helper: '如需修改，请联系管理员。',
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    String? helper,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        helperText: helper,
      ),
      child: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}
