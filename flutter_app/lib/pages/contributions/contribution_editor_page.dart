import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api/api_client.dart';
import '../../data/api/contribution_api.dart';
import '../../data/helpers/contribution_json_parser.dart';
import '../router.dart';

class ContributionEditorPage extends StatefulWidget {
  const ContributionEditorPage({
    super.key,
    this.questionId,
    this.contributionId,
  });

  final int? questionId;
  final int? contributionId;

  @override
  State<ContributionEditorPage> createState() => _ContributionEditorPageState();
}

class _ContributionEditorPageState extends State<ContributionEditorPage> {
  late final ContributionApi _api = ContributionApi(ApiClient());
  final _jsonController = TextEditingController();
  final _stemController = TextEditingController();
  final _tagSearchController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _suggestionController = TextEditingController();
  final _evidenceController = TextEditingController();
  final _newTagController = TextEditingController();
  final _newTagReasonController = TextEditingController();
  final _sourceYearController = TextEditingController();
  final _sourceRegionController = TextEditingController();
  final _sourceExamController = TextEditingController();
  final _sourceNumberController = TextEditingController();
  final _verificationKey = GlobalKey();

  ContributionConfig? _config;
  Map<String, dynamic>? _payload;
  List<String> _repairs = const [];
  final List<_OptionEditor> _options = [];
  final List<_SubQuestionEditor> _subQuestions = [];
  final Set<int> _tagIds = {};
  final List<Map<String, dynamic>> _newTags = [];
  final Set<String> _correctionCategories = {};
  bool _loading = true;
  bool _submitting = false;
  bool _uncertaintiesConfirmed = false;
  String? _error;
  int? _questionId;
  String _contributionType = 'new_question';
  String _reviewNote = '';
  String? _verificationError;

  bool get _isCorrection => _contributionType == 'question_correction';

  @override
  void initState() {
    super.initState();
    _questionId = widget.questionId;
    if (_questionId != null) _contributionType = 'question_correction';
    _loadConfig();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    _stemController.dispose();
    _tagSearchController.dispose();
    _descriptionController.dispose();
    _suggestionController.dispose();
    _evidenceController.dispose();
    _newTagController.dispose();
    _newTagReasonController.dispose();
    _sourceYearController.dispose();
    _sourceRegionController.dispose();
    _sourceExamController.dispose();
    _sourceNumberController.dispose();
    for (final option in _options) {
      option.dispose();
    }
    for (final sub in _subQuestions) {
      sub.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = ContributionConfig.fromJson(await _api.getConfig());
      final detail = widget.contributionId == null
          ? null
          : await _api.getDetail(widget.contributionId!);
      final questionContext =
          widget.contributionId == null && _questionId != null
          ? await _api.getQuestionContext(_questionId!)
          : null;
      if (!mounted) return;
      setState(() {
        _config = config;
        _loading = false;
      });
      if (detail != null) _applyExistingContribution(detail);
      if (questionContext != null) {
        setState(() {
          _tagIds
            ..clear()
            ..addAll(
              (questionContext['tag_ids'] as List? ?? const []).cast<int>(),
            );
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '投稿配置加载失败，请检查网络后重试';
        _loading = false;
      });
    }
  }

  void _applyExistingContribution(Map<String, dynamic> detail) {
    _contributionType = detail['contribution_type'] as String;
    _questionId = detail['question_id'] as int?;
    _reviewNote = detail['review_note'] as String? ?? '';
    final payload = Map<String, dynamic>.from(detail['payload'] as Map);
    if (_isCorrection) {
      _correctionCategories
        ..clear()
        ..addAll((payload['categories'] as List? ?? const []).cast<String>());
      _descriptionController.text = payload['description'] as String? ?? '';
      _suggestionController.text = payload['suggestion'] as String? ?? '';
      _evidenceController.text = payload['evidence'] as String? ?? '';
    } else {
      _jsonController.text = detail['raw_json'] as String? ?? '';
      _payload = payload;
      _applyPayload(payload);
    }
    _tagIds
      ..clear()
      ..addAll((detail['tag_ids'] as List? ?? const []).cast<int>());
    _newTags
      ..clear()
      ..addAll(
        (detail['tag_suggestions'] as List? ?? const [])
            .where((item) => (item as Map)['status'] == 'pending')
            .map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return <String, dynamic>{
                'name': map['name'],
                'parent_id': map['parent_id'],
                'reason': map['reason'] ?? '',
              };
            }),
      );
    setState(() {});
  }

  void _parseJson() {
    try {
      final result = ContributionJsonParser.parse(_jsonController.text);
      _applyPayload(result.payload);
      setState(() {
        _payload = result.payload;
        _repairs = result.repairs;
        _error = null;
        _verificationError = null;
      });
    } on ContributionJsonException catch (error) {
      setState(() => _error = error.message);
    }
  }

  void _applyPayload(Map<String, dynamic> payload) {
    _stemController.text = payload['stem'] as String? ?? '';
    final source = Map<String, dynamic>.from(
      payload['source'] as Map? ?? const {},
    );
    _sourceYearController.text = source['year']?.toString() ?? '';
    _sourceRegionController.text = source['region'] as String? ?? '';
    _sourceExamController.text =
        source['source_name'] as String? ??
        source['exam_name'] as String? ??
        '';
    _sourceNumberController.text =
        source['question_number'] as String? ??
        source['number'] as String? ??
        '';
    for (final option in _options) {
      option.dispose();
    }
    _options
      ..clear()
      ..addAll(
        (payload['options'] as List? ?? const []).map(
          (item) => _OptionEditor(Map<String, dynamic>.from(item as Map)),
        ),
      );
    for (final sub in _subQuestions) {
      sub.dispose();
    }
    _subQuestions
      ..clear()
      ..addAll(
        (payload['sub_questions'] as List? ?? const []).map(
          (item) => _SubQuestionEditor(Map<String, dynamic>.from(item as Map)),
        ),
      );
    _tagIds.clear();
    _newTags.clear();
    final config = _config;
    for (final rawName in payload['suggested_tags'] as List? ?? const []) {
      final name = '$rawName'.trim();
      final matches =
          config?.tags.where((tag) => tag.name == name).toList() ?? [];
      if (matches.isNotEmpty) {
        _tagIds.add(matches.first.id);
      } else if (name.isNotEmpty) {
        _newTags.add({'name': name, 'parent_id': null, 'reason': 'AI 建议标签'});
      }
    }
    _uncertaintiesConfirmed = false;
  }

  Map<String, dynamic> _editedPayload() {
    final payload = Map<String, dynamic>.from(_payload!);
    payload['stem'] = _stemController.text.trim();
    payload['options'] = _options.map((option) => option.toJson()).toList();
    payload['sub_questions'] = _subQuestions
        .map((sub) => sub.toJson())
        .toList();
    payload['suggested_tags'] = [
      for (final id in _tagIds)
        _config!.tags.firstWhere((tag) => tag.id == id).name,
      for (final tag in _newTags) tag['name'],
    ];
    final source = Map<String, dynamic>.from(
      payload['source'] as Map? ?? const {},
    );
    source['year'] = int.tryParse(_sourceYearController.text.trim());
    source['region'] = _sourceRegionController.text.trim();
    source['source_name'] = _sourceExamController.text.trim();
    source['question_number'] = _sourceNumberController.text.trim();
    source.remove('exam_name');
    source.remove('number');
    payload['source'] = source;
    return payload;
  }

  Future<void> _submit() async {
    if (_isCorrection) {
      if (_correctionCategories.isEmpty) {
        setState(() => _error = '请至少选择一个错误类型');
        return;
      }
      if (_descriptionController.text.trim().length < 10) {
        setState(() => _error = '问题说明至少需要 10 个字符');
        return;
      }
    } else {
      if (_payload == null) {
        setState(() => _error = '请先解析题目 JSON');
        return;
      }
      if (_stemController.text.trim().isEmpty || _subQuestions.isEmpty) {
        setState(() => _error = '题干和答案不能为空');
        return;
      }
      if (_subQuestions.any((sub) => sub.answer.text.trim().isEmpty)) {
        setState(() => _error = '每个小题都需要答案');
        return;
      }
      final uncertainties = _payload!['uncertainties'] as List? ?? const [];
      if (uncertainties.isNotEmpty && !_uncertaintiesConfirmed) {
        setState(() => _verificationError = '完成原题核对后才能提交');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final verificationContext = _verificationKey.currentContext;
          if (verificationContext != null) {
            Scrollable.ensureVisible(
              verificationContext,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              alignment: 0.25,
            );
          }
        });
        return;
      }
    }
    if (_tagIds.isEmpty && _newTags.isEmpty) {
      setState(() => _error = '请至少选择或建议一个知识点标签');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _verificationError = null;
    });
    try {
      final body = <String, dynamic>{
        'contribution_type': _isCorrection
            ? 'question_correction'
            : 'new_question',
        if (_isCorrection) 'question_id': _questionId,
        'raw_json': _isCorrection ? '' : _jsonController.text,
        'payload': _isCorrection
            ? {
                'categories': _correctionCategories.toList(),
                'description': _descriptionController.text.trim(),
                'suggestion': _suggestionController.text.trim(),
                'evidence': _evidenceController.text.trim(),
              }
            : _editedPayload(),
        'tag_ids': _tagIds.toList(),
        'tag_suggestions': _newTags,
      };
      if (widget.contributionId == null) {
        await _api.create(body);
      } else {
        await _api.resubmit(widget.contributionId!, body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已提交审核')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '提交失败，请检查内容后重试';
      });
    }
  }

  Future<void> _copyPrompt() async {
    await Clipboard.setData(ClipboardData(text: _config?.aiPrompt ?? ''));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI 转写提示词已复制')));
    }
  }

  Future<void> _openLatexLive() async {
    final uri = Uri.parse(
      _config?.latexEditorUrl ?? 'https://www.latexlive.com/',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      setState(() => _error = '无法打开 LaTeXLive');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_isCorrection ? '反馈题目错误' : '投稿新题'),
      actions: [
        IconButton(
          tooltip: '编辑格式说明',
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: () =>
              RouterUtils.push(context, AppRoutes.contributionHelp),
        ),
      ],
    ),
    body: _loading
        ? const LoadingIndicator(message: '正在加载投稿配置')
        : _config == null
        ? ErrorPlaceholder(message: _error ?? '加载失败', onRetry: _loadConfig)
        : AppContentContainer(
            maxWidth: AppContentWidth.reading,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                if (_error != null) _ErrorBanner(message: _error!),
                if (_reviewNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(child: Text('审核意见：$_reviewNote')),
                  ),
                if (_isCorrection) ...[
                  _buildCorrectionForm(),
                  const SizedBox(height: AppSpacing.md),
                  _buildTags(),
                ] else
                  _buildNewQuestionForm(),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: _submitting ? '正在提交' : '提交审核',
                  icon: Icons.send_outlined,
                  fullWidth: true,
                  onPressed: _submitting ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
  );

  Widget _buildNewQuestionForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('AI JSON 导入', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '使用 AI 转写后粘贴 JSON。解析完成后请对照原题检查公式与条件。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(
                  label: '复制提示词',
                  icon: Icons.copy_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: _copyPrompt,
                ),
                AppButton(
                  label: 'LaTeXLive',
                  icon: Icons.open_in_new_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: _openLatexLive,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _jsonController,
              minLines: 8,
              maxLines: 18,
              decoration: const InputDecoration(
                labelText: '题目 JSON',
                hintText: '在这里粘贴 AI 生成的 JSON',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: '解析并预览',
              icon: Icons.data_object_rounded,
              onPressed: _parseJson,
            ),
          ],
        ),
      ),
      if (_payload != null) ...[
        const SizedBox(height: AppSpacing.md),
        if (_repairs.isNotEmpty) _buildRepairs(),
        _buildStructuredEditor(),
        const SizedBox(height: AppSpacing.md),
        _buildTags(),
      ],
    ],
  );

  Widget _buildRepairs() => AppCard(
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('已自动修复 ${_repairs.length} 处格式问题'),
      children: [
        for (final repair in _repairs)
          ListTile(
            dense: true,
            leading: const Icon(Icons.auto_fix_high_outlined, size: 18),
            title: Text(repair),
          ),
      ],
    ),
  );

  Widget _buildStructuredEditor() {
    final type = _payload!['question_type'] as String;
    final uncertainties = _payload!['uncertainties'] as List? ?? const [];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('题目内容', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(labelText: '题型'),
            items: const [
              DropdownMenuItem(value: 'choice', child: Text('选择题')),
              DropdownMenuItem(value: 'fill', child: Text('填空题')),
              DropdownMenuItem(value: 'solution', child: Text('解答题')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _payload!['question_type'] = value;
                if (value == 'choice' && _options.isEmpty) {
                  _options.addAll(
                    [
                      'A',
                      'B',
                      'C',
                      'D',
                    ].map((key) => _OptionEditor({'key': key, 'content': ''})),
                  );
                } else if (value != 'choice') {
                  for (final option in _options) {
                    option.dispose();
                  }
                  _options.clear();
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _LatexField(label: '题干', controller: _stemController, minLines: 4),
          if (_options.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('选项', style: Theme.of(context).textTheme.titleSmall),
            for (final option in List<_OptionEditor>.of(_options))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _LatexField(
                        label: '选项 ${option.key.text}',
                        controller: option.content,
                      ),
                    ),
                    IconButton(
                      tooltip: '删除选项',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: _options.length <= 2
                          ? null
                          : () => setState(() {
                              _options.remove(option);
                              option.dispose();
                            }),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _options.length >= 8
                    ? null
                    : () => setState(() {
                        final key = String.fromCharCode(65 + _options.length);
                        _options.add(
                          _OptionEditor({'key': key, 'content': ''}),
                        );
                      }),
                icon: const Icon(Icons.add_rounded),
                label: const Text('增加选项'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('答案与解析', style: Theme.of(context).textTheme.titleSmall),
          for (var index = 0; index < _subQuestions.length; index++)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (_subQuestions.length > 1)
                        Expanded(child: Text('第 ${index + 1} 小题'))
                      else
                        const Spacer(),
                      IconButton(
                        tooltip: '删除小题',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: _subQuestions.length <= 1
                            ? null
                            : () => setState(() {
                                final removed = _subQuestions.removeAt(index);
                                removed.dispose();
                              }),
                      ),
                    ],
                  ),
                  if (_subQuestions[index].stem.text.isNotEmpty)
                    _LatexField(
                      label: '小题题干',
                      controller: _subQuestions[index].stem,
                    ),
                  _LatexField(
                    label: '答案',
                    controller: _subQuestions[index].answer,
                  ),
                  _LatexField(
                    label: '解析',
                    controller: _subQuestions[index].explanation,
                    minLines: 3,
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(
                () => _subQuestions.add(
                  _SubQuestionEditor({
                    'stem': '',
                    'answer': '',
                    'explanation': '',
                  }),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('增加小题'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('来源与难度', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue:
                (_payload!['source'] as Map?)?['source_type'] as String? ??
                'other',
            decoration: const InputDecoration(labelText: '来源类型'),
            items: const [
              DropdownMenuItem(value: 'gaokao', child: Text('高考真题')),
              DropdownMenuItem(value: 'mock_exam', child: Text('模拟考试')),
              DropdownMenuItem(value: 'school_exam', child: Text('学校试题')),
              DropdownMenuItem(value: 'textbook', child: Text('教辅资料')),
              DropdownMenuItem(value: 'self_created', child: Text('自拟题')),
              DropdownMenuItem(value: 'other', child: Text('其他')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                final source = Map<String, dynamic>.from(
                  _payload!['source'] as Map? ?? const {},
                );
                source['source_type'] = value;
                _payload!['source'] = source;
              });
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sourceYearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '年份'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _sourceRegionController,
                  decoration: const InputDecoration(labelText: '地区'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _sourceExamController,
            decoration: const InputDecoration(labelText: '试卷或资料名称'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _sourceNumberController,
            decoration: const InputDecoration(labelText: '原题题号'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _payload!['difficulty'] as String? ?? 'medium',
                  decoration: const InputDecoration(labelText: '难度建议'),
                  items: const [
                    DropdownMenuItem(value: 'basic', child: Text('基础')),
                    DropdownMenuItem(value: 'easy', child: Text('较易')),
                    DropdownMenuItem(value: 'medium', child: Text('中等')),
                    DropdownMenuItem(value: 'hard', child: Text('较难')),
                    DropdownMenuItem(value: 'very_hard', child: Text('困难')),
                  ],
                  onChanged: (value) =>
                      setState(() => _payload!['difficulty'] = value),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _payload!['calculation'] as String? ?? 'low',
                  decoration: const InputDecoration(labelText: '计算量建议'),
                  items: const [
                    DropdownMenuItem(value: 'very_low', child: Text('很少')),
                    DropdownMenuItem(value: 'low', child: Text('较少')),
                    DropdownMenuItem(value: 'high', child: Text('较多')),
                    DropdownMenuItem(value: 'very_high', child: Text('很大')),
                  ],
                  onChanged: (value) =>
                      setState(() => _payload!['calculation'] = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('题目预览', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          MdLatexBody(_stemController.text, fontSize: 16),
          for (final option in _options)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 28, child: Text(option.key.text)),
                  Expanded(child: MdLatexBody(option.content.text)),
                ],
              ),
            ),
          if (uncertainties.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              key: _verificationKey,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.warningContainer,
                border: Border.all(
                  color: _verificationError == null
                      ? context.colors.warning
                      : context.colors.error,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        color: context.colors.warning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '提交前必须对照原题核对',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final item in uncertainties) Text('• $item'),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _uncertaintiesConfirmed,
                    title: const Text('我已对照原题检查题干、公式、选项、答案和题号'),
                    onChanged: (value) => setState(() {
                      _uncertaintiesConfirmed = value ?? false;
                      if (_uncertaintiesConfirmed) _verificationError = null;
                    }),
                  ),
                  if (_verificationError != null)
                    Text(
                      _verificationError!,
                      style: TextStyle(color: context.colors.error),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTags() {
    final query = _tagSearchController.text.trim().toLowerCase();
    final visible = _config!.tags
        .where((tag) => query.isEmpty || tag.name.toLowerCase().contains(query))
        .take(40)
        .toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('知识点标签', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _tagSearchController,
            decoration: const InputDecoration(
              labelText: '搜索现有标签',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in visible)
                FilterChip(
                  label: Text(tag.name),
                  selected: _tagIds.contains(tag.id),
                  onSelected: (selected) => setState(
                    () =>
                        selected ? _tagIds.add(tag.id) : _tagIds.remove(tag.id),
                  ),
                ),
            ],
          ),
          if (_newTags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('待审核的新标签建议', style: Theme.of(context).textTheme.titleSmall),
            for (final tag in _newTags)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tag['name'] as String),
                subtitle: Text(tag['reason'] as String? ?? ''),
                trailing: IconButton(
                  tooltip: '删除建议',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => setState(() => _newTags.remove(tag)),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: '建议新标签',
            icon: Icons.add_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: _showNewTagDialog,
          ),
        ],
      ),
    );
  }

  Future<void> _showNewTagDialog() async {
    _newTagController.clear();
    _newTagReasonController.clear();
    int? parentId;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('建议新标签'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _newTagController,
                  decoration: const InputDecoration(labelText: '标签名称'),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int?>(
                  initialValue: parentId,
                  decoration: const InputDecoration(labelText: '上级标签'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('顶级标签'),
                    ),
                    for (final tag in _config!.tags)
                      DropdownMenuItem<int?>(
                        value: tag.id,
                        child: Text(tag.name),
                      ),
                  ],
                  onChanged: (value) => setDialogState(() => parentId = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _newTagReasonController,
                  decoration: const InputDecoration(labelText: '建议理由'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = _newTagController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogContext, {
                  'name': name,
                  'parent_id': parentId,
                  'reason': _newTagReasonController.text.trim(),
                });
              },
              child: const Text('添加建议'),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _newTags.add(result));
  }

  Widget _buildCorrectionForm() {
    const categories = {
      'stem': '题干错误',
      'options': '选项错误',
      'answer': '答案错误',
      'explanation': '解析错误',
      'tags': '标签错误',
      'source': '来源错误',
      'formatting': '公式或排版',
      'duplicate': '重复题目',
      'other': '其他',
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '题目 #$_questionId',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '请选择具体错误并说明位置。只有“答案错了”之类的描述无法有效核对。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final entry in categories.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: _correctionCategories.contains(entry.key),
                  onSelected: (selected) => setState(
                    () => selected
                        ? _correctionCategories.add(entry.key)
                        : _correctionCategories.remove(entry.key),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _LatexField(
            label: '问题说明',
            controller: _descriptionController,
            minLines: 4,
            initialPreview: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          _LatexField(
            label: '建议修改',
            controller: _suggestionController,
            minLines: 3,
            initialPreview: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          _LatexField(
            label: '验算或依据（选填）',
            controller: _evidenceController,
            minLines: 3,
            initialPreview: false,
          ),
        ],
      ),
    );
  }
}

class _LatexField extends StatefulWidget {
  const _LatexField({
    required this.label,
    required this.controller,
    this.minLines = 1,
    this.initialPreview = true,
  });
  final String label;
  final TextEditingController controller;
  final int minLines;
  final bool initialPreview;

  @override
  State<_LatexField> createState() => _LatexFieldState();
}

class _LatexFieldState extends State<_LatexField> {
  late bool preview;

  @override
  void initState() {
    super.initState();
    preview = widget.initialPreview;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: Text(widget.label)),
          IconButton(
            tooltip: preview ? '编辑原文' : '查看渲染效果',
            icon: Icon(
              preview ? Icons.edit_outlined : Icons.visibility_outlined,
            ),
            onPressed: () => setState(() => preview = !preview),
          ),
        ],
      ),
      if (preview)
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.divider),
            borderRadius: BorderRadius.circular(6),
          ),
          child: MdLatexBody(widget.controller.text),
        )
      else
        TextField(
          controller: widget.controller,
          minLines: widget.minLines,
          maxLines: widget.minLines + 6,
          decoration: InputDecoration(hintText: widget.label),
        ),
    ],
  );
}

class _OptionEditor {
  _OptionEditor(Map<String, dynamic> json)
    : key = TextEditingController(text: '${json['key'] ?? ''}'),
      content = TextEditingController(text: '${json['content'] ?? ''}');
  final TextEditingController key;
  final TextEditingController content;
  Map<String, dynamic> toJson() => {
    'key': key.text.trim(),
    'content': content.text.trim(),
  };
  void dispose() {
    key.dispose();
    content.dispose();
  }
}

class _SubQuestionEditor {
  _SubQuestionEditor(Map<String, dynamic> json)
    : stem = TextEditingController(text: '${json['stem'] ?? ''}'),
      answer = TextEditingController(text: '${json['answer'] ?? ''}'),
      explanation = TextEditingController(text: '${json['explanation'] ?? ''}');
  final TextEditingController stem;
  final TextEditingController answer;
  final TextEditingController explanation;
  Map<String, dynamic> toJson() => {
    'stem': stem.text.trim(),
    'answer': answer.text.trim(),
    'explanation': explanation.text.trim(),
  };
  void dispose() {
    stem.dispose();
    answer.dispose();
    explanation.dispose();
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Material(
      color: context.colors.errorContainer,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: context.colors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
}
