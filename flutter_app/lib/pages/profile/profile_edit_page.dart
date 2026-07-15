import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../app_theme.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/user_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/user_repository.dart';
import '../../../data/debug/audit_logger.dart';

/// 编辑资料页 — 匹配 HTML 原型 profile_edit.html
class ProfileEditPage extends StatefulWidget {
  final UserRepository? userRepository;
  const ProfileEditPage({super.key, this.userRepository});

  @override State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final UserRepository _repo;
  final _nameCtrl = TextEditingController();
  UserInfo? _info;
  String? _avatarUrl;
  String? _gaokaoYear;
  bool _loading = true;
  bool _uploading = false;

  static const _gaokaoYears = ['2025', '2026', '2027', '2028'];

  @override
  void initState() {
    super.initState();
    _repo = widget.userRepository ?? UserRepository(
      UserDao(DatabaseProvider()), UserApi(ApiClient()), QuestionDao(DatabaseProvider()),
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
      AuditLogger.instance.page('ProfileEditPage', {'name': _nameCtrl.text, 'gaokaoYear': _gaokaoYear, 'loading': _loading});
    } catch (e) {
      AuditLogger.instance.error('ProfileEditPage._load', e);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_info == null) return;
    await _repo.saveProfile(UserInfo(
      id: _info!.id, name: _info!.name,
      realName: _nameCtrl.text,
      avatar: _avatarUrl,
      gaokaoYear: _gaokaoYear,
      phone: _info!.phone,
    ));
    if (!mounted) return;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功'), behavior: SnackBarBehavior.floating),
      );
      context.pop();
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final url = await _repo.uploadAvatar(picked.path);
      if (!mounted) return;
      setState(() { _avatarUrl = url; _uploading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像更新成功'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      AuditLogger.instance.error('ProfileEditPage._pickAndUploadAvatar', e);
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('头像上传失败: $e'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.error),
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

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('个人信息')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(16), children: [
      // 头像
      Card(
        child: InkWell(
          onTap: _uploading ? null : _showAvatarPicker,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.background,
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? const Icon(Icons.person, size: 36, color: AppColors.textSecondary)
                          : null,
                    ),
                    if (_uploading)
                      const SizedBox(
                        width: 28, height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('点击相机图标更换头像（建议 200×200 以内）',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      // 基本信息
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('基本信息',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              // 昵称（可编辑）
              _inputGroup('昵称',
                TextField(controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: '输入昵称',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 高考年份（select）
              _inputGroup('高考年份',
                DropdownButtonFormField<String>(
                  initialValue: _gaokaoYear,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _gaokaoYears.map((y) => DropdownMenuItem(
                    value: y, child: Text('$y 年'),
                  )).toList(),
                  onChanged: (v) { if (v != null) setState(() => _gaokaoYear = v); },
                ),
              ),
              const Divider(height: 24),
              // 真实姓名（只读）
              _inputGroup('真实姓名',
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.background,
                  ),
                  child: Text(
                    _info?.realName ?? '—',
                    style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
                  ),
                ),
                hint: '提交后不可修改，如需更改请联系管理员',
              ),
              const SizedBox(height: 12),
              // 学号（disabled）
              _inputGroup('学号',
                TextField(
                  controller: TextEditingController(text: _info?.studentId ?? ''),
                  enabled: false,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 手机号（disabled）
              _inputGroup('手机号',
                TextField(
                  controller: TextEditingController(text: _info?.phone ?? ''),
                  enabled: false,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
                hint: '提交后不可修改，如需更改请联系管理员',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _save,
          child: const Text('保存修改'),
        ),
      ),
      const SizedBox(height: 16),
    ]),
  );

  Widget _inputGroup(String label, Widget field, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        field,
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ],
    );
  }
}
