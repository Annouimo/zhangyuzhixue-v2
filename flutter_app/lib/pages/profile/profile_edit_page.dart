import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/api/api_client.dart';
import '../../../data/api/user_api.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/daos/user_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/user_repository.dart';
import '../../../data/debug/audit_logger.dart';

class ProfileEditPage extends StatefulWidget {
  final UserRepository? userRepository;
  const ProfileEditPage({super.key, this.userRepository});

  @override State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final UserRepository _repo;
  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _gaokaoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final db = DatabaseProvider();
    _repo = widget.userRepository ?? UserRepository(UserDao(db.appDb), UserApi(ApiClient()), QuestionDao(db.assetsDb));
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await _repo.getUserInfo();
      if (!mounted) return;
      _nameCtrl.text = info.realName ?? info.name;
      _schoolCtrl.text = info.school ?? '';
      _gaokaoCtrl.text = info.gaokaoYear ?? '';
      _phoneCtrl.text = info.phone ?? '';
      setState(() => _loading = false);
      AuditLogger.instance.page('ProfileEditPage', {'name': _nameCtrl.text, 'gaokaoYear': _gaokaoCtrl.text, 'loading': _loading});
    } catch (e) { AuditLogger.instance.error('ProfileEditPage._load', e); if (mounted) setState(() => _loading = false); }
  }

  Future<void> _save() async {
    final info = await _repo.getUserInfo();
    await _repo.saveProfile(UserInfo(id: info.id, name: info.name, realName: _nameCtrl.text,
      school: _schoolCtrl.text, gaokaoYear: _gaokaoCtrl.text, phone: _phoneCtrl.text));
    if (!mounted) return;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功'), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _schoolCtrl.dispose(); _gaokaoCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('编辑资料'), actions: [
      TextButton(onPressed: _save, child: const Text('保存', style: TextStyle(color: AppColors.primary))),
    ]),
    body: _loading ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(16), children: [
      _field('姓名', _nameCtrl, hint: '请输入姓名'),
      const SizedBox(height: 12),
      _field('手机号', _phoneCtrl, hint: '请输入手机号', keyboardType: TextInputType.phone),
      const SizedBox(height: 12),
      _field('学校', _schoolCtrl, hint: '请输入学校'),
      const SizedBox(height: 12),
      _field('高考年份', _gaokaoCtrl, hint: '如 2025', keyboardType: TextInputType.number),
    ]),
  );

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()), keyboardType: keyboardType),
    ]);
  }
}
