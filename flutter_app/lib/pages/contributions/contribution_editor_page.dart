import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api/api_client.dart';
import '../../data/api/contribution_api.dart';
import '../../data/helpers/contribution_json_parser.dart';
import '../../data/prefs/contribution_draft_store.dart';
import '../router.dart';

class ContributionEditorPage extends StatefulWidget {
  const ContributionEditorPage({
    super.key,
    this.questionId,
    this.contributionId,
    this.mode,
  });

  final int? questionId;
  final int? contributionId;
  final String? mode;

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
  final _targetQuestionController = TextEditingController();
  final _methodNameController = TextEditingController();
  final _methodSourceController = TextEditingController();
  final _methodSummaryController = TextEditingController();
  final _verificationKey = GlobalKey();

  ContributionConfig? _config;
  Map<String, dynamic>? _payload;
  List<String> _repairs = const [];
  final List<_OptionEditor> _options = [];
  final List<_SubQuestionEditor> _subQuestions = [];
  final List<_SolutionStepEditor> _solutionSteps = [];
  final Set<int> _tagIds = {};
  final List<Map<String, dynamic>> _newTags = [];
  final Set<String> _correctionCategories = {};
  bool _loading = true;
  bool _submitting = false;
  bool _uncertaintiesConfirmed = false;
  bool _provideCorrection = false;
  String? _error;
  int? _questionId;
  String _contributionType = 'new_question';
  late String _mode;
  int _currentStep = 0;
  int? _targetSubQuestionId;
  Map<String, dynamic>? _questionContext;
  Map<String, dynamic>? _originalQuestionPayload;
  late final String _draftId;
  final _draftStore = ContributionDraftStore();
  Timer? _draftTimer;
  String _reviewNote = '';
  String? _verificationError;

  bool get _isCorrection => _contributionType == 'question_correction';
  bool get _isSolution => _contributionType == 'new_solution';
  bool get _isOriginal =>
      _mode == 'original' ||
      _mode == 'solution_original' ||
      (!_isSolution &&
          (_payload?['source'] as Map?)?['source_type'] == 'self_created');

  @override
  void initState() {
    super.initState();
    _mode = widget.mode ?? 'existing';
    _draftId = widget.contributionId == null
        ? '${DateTime.now().microsecondsSinceEpoch}'
        : 'resubmit-${widget.contributionId}';
    _questionId = widget.questionId;
    if (_mode == 'solution' || _mode.startsWith('solution_')) {
      _contributionType = 'new_solution';
    } else if (_questionId != null || _mode == 'correction') {
      _contributionType = 'question_correction';
    }
    _solutionSteps.add(_SolutionStepEditor());
    for (final controller in [
      _jsonController,
      _stemController,
      _descriptionController,
      _suggestionController,
      _evidenceController,
      _sourceYearController,
      _sourceRegionController,
      _sourceExamController,
      _sourceNumberController,
      _targetQuestionController,
      _methodNameController,
      _methodSourceController,
      _methodSummaryController,
    ]) {
      controller.addListener(_queueDraftSave);
    }
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
    _targetQuestionController.dispose();
    _methodNameController.dispose();
    _methodSourceController.dispose();
    _methodSummaryController.dispose();
    _draftTimer?.cancel();
    for (final option in _options) {
      option.dispose();
    }
    for (final sub in _subQuestions) {
      sub.dispose();
    }
    for (final step in _solutionSteps) {
      step.dispose();
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
      if (detail == null && !_isCorrection && !_isSolution) {
        _applyPayload(_emptyQuestionPayload());
        _payload = _emptyQuestionPayload();
      }
      if (questionContext != null) {
        setState(() {
          _questionContext = questionContext;
          _originalQuestionPayload = Map<String, dynamic>.from(questionContext);
          _targetQuestionController.text = '${_questionId!}';
          if (!_isCorrection || !_provideCorrection) {
            _tagIds
              ..clear()
              ..addAll(
                (questionContext['tag_ids'] as List? ?? const []).cast<int>(),
              );
          }
        });
      }
      if (widget.contributionId == null) await _offerDraftRestore();
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
      final proposed = payload['proposed_question'];
      if (proposed is Map) {
        _provideCorrection = true;
        _payload = Map<String, dynamic>.from(proposed);
        _applyPayload(_payload!);
      }
    } else if (_isSolution) {
      _targetSubQuestionId = detail['target_sub_question_id'] as int?;
      _methodNameController.text = payload['method_name'] as String? ?? '';
      _methodSourceController.text = payload['source'] as String? ?? '';
      _methodSummaryController.text = payload['summary'] as String? ?? '';
      for (final step in _solutionSteps) {
        step.dispose();
      }
      _solutionSteps
        ..clear()
        ..addAll(
          (payload['steps'] as List? ?? const []).map(
            (item) => _SolutionStepEditor.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
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

  Future<void> _loadQuestionContext() async {
    final id =
        _questionId ?? int.tryParse(_targetQuestionController.text.trim());
    if (id == null) {
      setState(() => _error = '请输入有效的题目编号');
      return;
    }
    try {
      final context = await _api.getQuestionContext(id);
      if (!mounted) return;
      setState(() {
        _questionId = id;
        _questionContext = context;
        _originalQuestionPayload = Map<String, dynamic>.from(context);
        _tagIds
          ..clear()
          ..addAll((context['tag_ids'] as List? ?? const []).cast<int>());
        final subs = context['sub_questions'] as List? ?? const [];
        _targetSubQuestionId = subs.length == 1
            ? (subs.first as Map)['id'] as int?
            : null;
        _error = null;
      });
      _queueDraftSave();
    } catch (_) {
      if (mounted) setState(() => _error = '没有找到该题目，请核对题目编号');
    }
  }

  void _queueDraftSave() {
    if (_loading || _submitting) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 350), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final draft = <String, dynamic>{
      'mode': _mode,
      'step': _currentStep,
      'question_id': _questionId,
      'target_sub_question_id': _targetSubQuestionId,
      'raw_json': _jsonController.text,
      if (_payload != null) 'payload': _editedPayload(),
      'description': _descriptionController.text,
      'suggestion': _suggestionController.text,
      'evidence': _evidenceController.text,
      'method_name': _methodNameController.text,
      'method_source': _methodSourceController.text,
      'method_summary': _methodSummaryController.text,
      'solution_steps': _solutionSteps.map((step) => step.toJson()).toList(),
      'correction_categories': _correctionCategories.toList(),
      'provide_correction': _provideCorrection,
      'tag_ids': _tagIds.toList(),
      'tag_suggestions': _newTags,
      'summary': _isSolution
          ? _methodNameController.text
          : _isCorrection
          ? _descriptionController.text
          : _stemController.text,
    };
    await _draftStore.save(_draftId, draft);
  }

  Future<void> _saveDraftNow() async {
    await _saveDraft();
    if (!mounted) return;
    AppToast.success(context, '草稿已保存到本机');
  }

  Future<void> _offerDraftRestore() async {
    final drafts = _draftStore
        .list()
        .where((item) => item['mode'] == _mode && item['draft_id'] != _draftId)
        .toList();
    if (drafts.isEmpty || !mounted) return;
    final latest = drafts.first;
    final restore = await AppDialog.confirm(
      context,
      title: '继续本地草稿？',
      message:
          '${latest['summary']?.toString().trim().isNotEmpty == true ? latest['summary'] : '未命名投稿'}\n\n草稿只保存在本机。',
      cancelLabel: '新建',
      confirmLabel: '继续编辑',
      icon: Icons.drafts_outlined,
    );
    if (!restore) return;
    final draft = _draftStore.read('${latest['draft_id']}');
    if (draft == null || !mounted) return;
    final savedStep = draft['step'] as int? ?? 0;
    _currentStep = savedStep > 0 ? 1 : 0;
    _questionId = draft['question_id'] as int?;
    _targetSubQuestionId = draft['target_sub_question_id'] as int?;
    _jsonController.text = draft['raw_json'] as String? ?? '';
    final savedPayload = draft['payload'];
    if (savedPayload is Map) {
      _payload = Map<String, dynamic>.from(savedPayload);
      _applyPayload(_payload!);
    }
    _descriptionController.text = draft['description'] as String? ?? '';
    _suggestionController.text = draft['suggestion'] as String? ?? '';
    _evidenceController.text = draft['evidence'] as String? ?? '';
    _methodNameController.text = draft['method_name'] as String? ?? '';
    _methodSourceController.text = draft['method_source'] as String? ?? '';
    _methodSummaryController.text = draft['method_summary'] as String? ?? '';
    _correctionCategories
      ..clear()
      ..addAll(
        (draft['correction_categories'] as List? ?? const []).cast<String>(),
      );
    _provideCorrection = draft['provide_correction'] as bool? ?? false;
    for (final step in _solutionSteps) {
      step.dispose();
    }
    _solutionSteps
      ..clear()
      ..addAll(
        (draft['solution_steps'] as List? ?? const []).map(
          (item) => _SolutionStepEditor.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      );
    if (_solutionSteps.isEmpty) _solutionSteps.add(_SolutionStepEditor());
    _tagIds
      ..clear()
      ..addAll((draft['tag_ids'] as List? ?? const []).cast<int>());
    _newTags
      ..clear()
      ..addAll(
        (draft['tag_suggestions'] as List? ?? const []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
    if (savedPayload == null &&
        _jsonController.text.trim().isNotEmpty &&
        !_isCorrection &&
        !_isSolution) {
      _parseJson();
    }
    if (_questionId != null && (_isSolution || _isCorrection)) {
      _targetQuestionController.text = '${_questionId!}';
      await _loadQuestionContext();
      if (_isCorrection && _provideCorrection && savedPayload != null) {
        _tagIds
          ..clear()
          ..addAll((draft['tag_ids'] as List? ?? const []).cast<int>());
      }
    }
    await _draftStore.remove('${latest['draft_id']}');
    if (!mounted) return;
    setState(() {});
  }

  Map<String, dynamic> _emptyQuestionPayload() => {
    'question_type': 'choice',
    'stem': '',
    'options': [
      for (final key in const ['A', 'B', 'C', 'D']) {'key': key, 'content': ''},
    ],
    'sub_questions': [
      {'stem': '', 'answer': '', 'explanation': '', 'methods': <dynamic>[]},
    ],
    'source': {'source_type': 'other'},
    'difficulty': 'medium',
    'calculation': 'low',
    'uncertainties': <dynamic>[],
    'suggested_tags': <dynamic>[],
  };

  void _parseJson({bool onlyFillBlanks = false}) {
    try {
      final result = ContributionJsonParser.parse(_jsonController.text);
      if (onlyFillBlanks) {
        _fillBlankFields(result.payload);
      } else {
        _applyPayload(result.payload);
      }
      setState(() {
        if (!onlyFillBlanks) _payload = result.payload;
        _repairs = result.repairs;
        _error = null;
        _verificationError = null;
      });
    } on ContributionJsonException catch (error) {
      setState(() => _error = error.message);
    }
  }

  void _fillBlankFields(Map<String, dynamic> payload) {
    final formWasBlank =
        _stemController.text.trim().isEmpty &&
        _subQuestions.every(
          (item) =>
              item.stem.text.trim().isEmpty &&
              item.answer.text.trim().isEmpty &&
              item.explanation.text.trim().isEmpty,
        );
    final source = Map<String, dynamic>.from(
      payload['source'] as Map? ?? const {},
    );
    if (_stemController.text.trim().isEmpty) {
      _stemController.text = payload['stem'] as String? ?? '';
    }
    final importedOptions = payload['options'] as List? ?? const [];
    if (_options.every((item) => item.content.text.trim().isEmpty) &&
        importedOptions.isNotEmpty) {
      for (final option in _options) {
        option.dispose();
      }
      _options
        ..clear()
        ..addAll(
          importedOptions.map(
            (item) => _OptionEditor(Map<String, dynamic>.from(item as Map)),
          ),
        );
    }
    final importedSubs = payload['sub_questions'] as List? ?? const [];
    if (_subQuestions.every(
          (item) =>
              item.stem.text.trim().isEmpty &&
              item.answer.text.trim().isEmpty &&
              item.explanation.text.trim().isEmpty,
        ) &&
        importedSubs.isNotEmpty) {
      for (final sub in _subQuestions) {
        sub.dispose();
      }
      _subQuestions
        ..clear()
        ..addAll(
          importedSubs.map(
            (item) =>
                _SubQuestionEditor(Map<String, dynamic>.from(item as Map)),
          ),
        );
    }
    void fill(TextEditingController controller, Object? value) {
      if (controller.text.trim().isEmpty) controller.text = '${value ?? ''}';
    }

    fill(_sourceYearController, source['year']);
    fill(_sourceRegionController, source['region']);
    fill(_sourceExamController, source['source_name'] ?? source['exam_name']);
    fill(
      _sourceNumberController,
      source['question_number'] ?? source['number'],
    );
    _payload = formWasBlank
        ? {...?_payload, ...payload}
        : {...payload, ...?_payload};
  }

  void _setCorrectionProposalMode(bool enabled) {
    setState(() {
      _provideCorrection = enabled;
      if (enabled && _payload == null && _questionContext != null) {
        _originalQuestionPayload = Map<String, dynamic>.from(_questionContext!);
        _payload = Map<String, dynamic>.from(_questionContext!);
        _applyPayload(_payload!);
        _tagIds
          ..clear()
          ..addAll(
            (_questionContext!['tag_ids'] as List? ?? const []).cast<int>(),
          );
      }
    });
    _queueDraftSave();
  }

  Future<void> _showJsonImportDialog() async {
    var onlyFillBlanks = true;
    final imported = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('从 AI 结果导入'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('将 AI 生成的 JSON 粘贴到这里，系统会自动填写题目表单。'),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      TextButton.icon(
                        onPressed: _copyPrompt,
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('复制 AI 提示词'),
                      ),
                      TextButton.icon(
                        onPressed: _openLatexLive,
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('打开 LaTeXLive'),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _jsonController,
                    minLines: 9,
                    maxLines: 18,
                    decoration: const InputDecoration(
                      labelText: 'AI 生成内容',
                      hintText: '在这里粘贴 JSON',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RadioGroup<bool>(
                    groupValue: onlyFillBlanks,
                    onChanged: (value) =>
                        setDialogState(() => onlyFillBlanks = value ?? true),
                    child: const Column(
                      children: [
                        RadioListTile<bool>(
                          value: true,
                          title: Text('仅填充空白字段'),
                          subtitle: Text('保留已经手动编辑的内容'),
                        ),
                        RadioListTile<bool>(
                          value: false,
                          title: Text('覆盖 AI 结果包含的字段'),
                          subtitle: Text('相关手动编辑内容会被替换'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('导入并填写'),
            ),
          ],
        ),
      ),
    );
    if (imported == true && mounted) {
      _parseJson(onlyFillBlanks: onlyFillBlanks);
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
    if (_isOriginal) {
      source
        ..['source_type'] = 'self_created'
        ..['year'] = null
        ..['region'] = ''
        ..['source_name'] = ''
        ..['question_number'] = '';
    }
    source.remove('exam_name');
    source.remove('number');
    payload['source'] = source;
    return payload;
  }

  Widget _buildQuestionTarget() {
    final subs = _questionContext?['sub_questions'] as List? ?? const [];
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('选择题目和小题', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _targetQuestionController,
                enabled: widget.questionId == null,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '题目编号'),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: _questionContext == null ? '加载题目' : '重新加载',
                icon: Icons.search_rounded,
                onPressed: _loadQuestionContext,
              ),
              if (_questionContext != null) ...[
                const SizedBox(height: AppSpacing.md),
                MdLatexBody('${_questionContext!['stem'] ?? ''}'),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<int>(
                  initialValue: _targetSubQuestionId,
                  decoration: const InputDecoration(labelText: '目标小题'),
                  items: [
                    for (var index = 0; index < subs.length; index++)
                      DropdownMenuItem(
                        value: (subs[index] as Map)['id'] as int,
                        child: Text(
                          '第 ${index + 1} 小题 · ${(subs[index] as Map)['answer'] ?? ''}',
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _targetSubQuestionId = value);
                    _queueDraftSave();
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSolutionForm() => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('解法内容', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _methodNameController,
          decoration: const InputDecoration(labelText: '解法名称'),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('本人原创')),
            ButtonSegment(value: false, label: Text('外部资料')),
          ],
          selected: {_isOriginal},
          onSelectionChanged: (selection) {
            setState(() {
              _mode = selection.first
                  ? 'solution_original'
                  : 'solution_external';
            });
            _queueDraftSave();
          },
        ),
        if (!_isOriginal) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _methodSourceController,
            decoration: const InputDecoration(
              labelText: '解法来源',
              hintText: '填写资料、试卷或作者信息',
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        _LatexField(
          label: '思路概述（选填）',
          controller: _methodSummaryController,
          minLines: 2,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('分步过程', style: Theme.of(context).textTheme.titleSmall),
        for (var index = 0; index < _solutionSteps.length; index++)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('第 ${index + 1} 步')),
                    IconButton(
                      tooltip: '删除步骤',
                      onPressed: _solutionSteps.length == 1
                          ? null
                          : () {
                              setState(
                                () => _solutionSteps.removeAt(index).dispose(),
                              );
                              _queueDraftSave();
                            },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                TextField(
                  controller: _solutionSteps[index].title,
                  decoration: const InputDecoration(labelText: '步骤标题'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _LatexField(
                  label: '步骤内容',
                  controller: _solutionSteps[index].content,
                  minLines: 3,
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () => setState(() {
            final step = _SolutionStepEditor();
            step.title.addListener(_queueDraftSave);
            step.content.addListener(_queueDraftSave);
            _solutionSteps.add(step);
          }),
          icon: const Icon(Icons.add_rounded),
          label: const Text('增加步骤'),
        ),
      ],
    ),
  );

  Widget _buildReview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isCorrection
                        ? _provideCorrection
                              ? '修改方案差异'
                              : '问题报告预览'
                        : '最终内容预览',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _currentStep = 0),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('修改内容'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_isSolution) ...[
              Text(
                '当前题目 · 第 ${_targetSubQuestionIndexLabel()} 小题',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              MdLatexBody('${_questionContext?['stem'] ?? ''}'),
              const Divider(height: AppSpacing.xl),
              Text(
                _methodNameController.text.isEmpty
                    ? '未填写解法名称'
                    : _methodNameController.text,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (_methodSummaryController.text.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                MdLatexBody(_methodSummaryController.text),
              ],
              for (var index = 0; index < _solutionSteps.length; index++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 13,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(_solutionSteps[index].title.text),
                  subtitle: MdLatexBody(_solutionSteps[index].content.text),
                ),
            ] else if (_isCorrection) ...[
              if (_provideCorrection)
                _buildQuestionDiff()
              else ...[
                Text('问题报告', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _correctionCategories.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text('问题说明', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              MdLatexBody(_descriptionController.text),
              if (_evidenceController.text.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('验算或依据', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                MdLatexBody(_evidenceController.text),
              ],
            ] else if (_payload != null) ...[
              MdLatexBody(_stemController.text, fontSize: 16),
              for (final option in _options)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: QuestionOptionRow(
                    label: option.key.text,
                    content: option.content.text,
                  ),
                ),
              const Divider(height: AppSpacing.xl),
              for (var index = 0; index < _subQuestions.length; index++) ...[
                Text(
                  _subQuestions.length == 1 ? '参考答案' : '第 ${index + 1} 小题',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                MdLatexBody(_subQuestions[index].answer.text),
                if (_subQuestions[index].explanation.text.trim().isNotEmpty)
                  MdLatexBody(_subQuestions[index].explanation.text),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                '将新增 1 道题目 · ${_subQuestions.length} 个答案 · '
                '${_tagIds.length + _newTags.length} 个知识点标签',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _buildSubmissionChecks(),
      const SizedBox(height: AppSpacing.md),
      const AppCard(child: Text('提交后将进入人工审核；需要修改时，审核意见会显示在贡献详情中。')),
    ],
  );

  String _targetSubQuestionIndexLabel() {
    final subs = _questionContext?['sub_questions'] as List? ?? const [];
    final index = subs.indexWhere(
      (item) => (item as Map)['id'] == _targetSubQuestionId,
    );
    return index < 0 ? '-' : '${index + 1}';
  }

  Widget _buildQuestionDiff() {
    final original = _originalQuestionPayload ?? _questionContext ?? const {};
    final changes = <({String label, String before, String after})>[];

    void add(String label, String before, String after) {
      if (before.trim() != after.trim()) {
        changes.add((label: label, before: before, after: after));
      }
    }

    String typeLabel(Object? value) => switch ('$value') {
      'choice' => '选择题',
      'fill' => '填空题',
      'solution' => '解答题',
      _ => '$value',
    };

    String optionText(Iterable<Map<String, dynamic>> items) => items
        .map((item) => '${item['key'] ?? ''}. ${item['content'] ?? ''}')
        .join('\n');

    String subQuestionText(Iterable<Map<String, dynamic>> items) {
      var index = 0;
      return items
          .map((item) {
            index++;
            final stem = '${item['stem'] ?? ''}'.trim();
            final answer = '${item['answer'] ?? ''}'.trim();
            final explanation = '${item['explanation'] ?? ''}'.trim();
            final methods = (item['solution_methods'] as List? ?? const [])
                .map((rawMethod) {
                  final method = rawMethod as Map;
                  final steps = (method['steps'] as List? ?? const [])
                      .map((rawStep) {
                        final step = rawStep as Map;
                        return '${step['title'] ?? ''}：${step['content'] ?? ''}';
                      })
                      .join('\n');
                  final source = '${method['source'] ?? ''}'.trim();
                  return [
                    '解法：${method['method_name'] ?? ''}',
                    if (source.isNotEmpty) '来源：$source',
                    steps,
                  ].where((item) => item.isNotEmpty).join('\n');
                })
                .join('\n');
            return [
              '第 $index 小题',
              if (stem.isNotEmpty) '题干：$stem',
              '答案：$answer',
              if (explanation.isNotEmpty) '解析：$explanation',
              if (methods.isNotEmpty) methods,
            ].join('\n');
          })
          .join('\n\n');
    }

    String sourceText(Map<String, dynamic> source) => [
      '${source['source_type'] ?? ''}',
      '${source['year'] ?? ''}',
      '${source['region'] ?? ''}',
      '${source['source_name'] ?? source['exam_name'] ?? ''}',
      '${source['question_number'] ?? source['number'] ?? ''}',
    ].where((item) => item.isNotEmpty).join(' · ');

    final originalOptions = (original['options'] as List? ?? const []).map(
      (item) => Map<String, dynamic>.from(item as Map),
    );
    final originalSubs = (original['sub_questions'] as List? ?? const []).map(
      (item) => Map<String, dynamic>.from(item as Map),
    );
    final currentSubs = _subQuestions.map((item) => item.toJson());
    final originalSource = Map<String, dynamic>.from(
      original['source'] as Map? ?? const {},
    );
    final currentSource = Map<String, dynamic>.from(
      _editedPayload()['source'] as Map? ?? const {},
    );
    final originalTags =
        (original['tags'] as List? ??
                original['suggested_tags'] as List? ??
                const [])
            .map((item) => '$item')
            .toList()
          ..sort();
    final originalTagText = originalTags.join('、');
    final currentTagNames = [
      for (final id in _tagIds)
        _config!.tags.firstWhere((tag) => tag.id == id).name,
      for (final tag in _newTags) '${tag['name']}',
    ]..sort();
    final currentTags = currentTagNames.join('、');

    add(
      '题型',
      typeLabel(original['question_type']),
      typeLabel(_payload?['question_type']),
    );
    add('题干', '${original['stem'] ?? ''}', _stemController.text);
    add(
      '选项',
      optionText(originalOptions),
      optionText(_options.map((item) => item.toJson())),
    );
    add('答案与解析', subQuestionText(originalSubs), subQuestionText(currentSubs));
    add('来源', sourceText(originalSource), sourceText(currentSource));
    add(
      '难度',
      '${original['difficulty'] ?? ''}',
      '${_payload?['difficulty'] ?? ''}',
    );
    add(
      '计算量',
      '${original['calculation'] ?? ''}',
      '${_payload?['calculation'] ?? ''}',
    );
    add('知识点标签', originalTagText, currentTags);

    if (changes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.warningContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('尚未修改任何题目字段，请返回编辑后再提交。'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < changes.length; index++) ...[
          _DiffBlock(
            label: changes[index].label,
            before: changes[index].before,
            after: changes[index].after,
          ),
          if (index < changes.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _buildSubmissionChecks() {
    final checks = <({String label, bool passed, bool warning})>[];
    if (_isSolution) {
      checks.add((
        label: '已选择具体小题',
        passed: _targetSubQuestionId != null,
        warning: false,
      ));
      checks.add((
        label: '解法名称和步骤完整',
        passed:
            _methodNameController.text.trim().isNotEmpty &&
            _solutionSteps.every(
              (step) =>
                  step.title.text.trim().isNotEmpty &&
                  step.content.text.trim().isNotEmpty,
            ),
        warning: false,
      ));
    } else if (_isCorrection) {
      checks.add((
        label: '已选择问题类型',
        passed: _correctionCategories.isNotEmpty,
        warning: false,
      ));
      checks.add((
        label: '问题说明不少于 10 个字符',
        passed: _descriptionController.text.trim().length >= 10,
        warning: false,
      ));
      if (_provideCorrection) {
        checks.add((
          label: '修改方案至少包含一项字段变更',
          passed: _hasQuestionChanges(),
          warning: false,
        ));
      }
    } else {
      checks.add((
        label: '题干完整',
        passed: _stemController.text.trim().isNotEmpty,
        warning: false,
      ));
      checks.add((
        label: '每个小题均填写参考答案',
        passed:
            _subQuestions.isNotEmpty &&
            _subQuestions.every((sub) => sub.answer.text.trim().isNotEmpty),
        warning: false,
      ));
      checks.add((
        label: '已选择或建议知识点标签',
        passed: _tagIds.isNotEmpty || _newTags.isNotEmpty,
        warning: false,
      ));
      checks.add((
        label: '来源信息不完整，审核人员可能要求补充',
        passed: _isOriginal || _sourceExamController.text.trim().isNotEmpty,
        warning: true,
      ));
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('提交检查', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final check in checks)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                check.passed
                    ? Icons.check_circle_outline_rounded
                    : check.warning
                    ? Icons.warning_amber_rounded
                    : Icons.error_outline_rounded,
                color: check.passed
                    ? context.colors.success
                    : check.warning
                    ? context.colors.warning
                    : context.colors.error,
              ),
              title: Text(check.label),
              subtitle: check.passed
                  ? null
                  : Text(check.warning ? '警告：允许提交' : '错误：提交前必须修改'),
            ),
        ],
      ),
    );
  }

  bool _hasQuestionChanges() {
    final original = _originalQuestionPayload ?? _questionContext;
    if (original == null || _payload == null) return false;
    if ('${original['question_type'] ?? ''}' !=
            '${_payload!['question_type'] ?? ''}' ||
        '${original['stem'] ?? ''}'.trim() != _stemController.text.trim() ||
        '${original['difficulty'] ?? ''}' !=
            '${_payload!['difficulty'] ?? ''}' ||
        '${original['calculation'] ?? ''}' !=
            '${_payload!['calculation'] ?? ''}') {
      return true;
    }
    final originalOptions = (original['options'] as List? ?? const [])
        .map((item) {
          final map = item as Map;
          return '${map['key'] ?? ''}|${map['content'] ?? ''}';
        })
        .join('\n');
    final currentOptions = _options
        .map((item) => '${item.key.text.trim()}|${item.content.text.trim()}')
        .join('\n');
    if (originalOptions != currentOptions) return true;

    String subText(Iterable<Map<String, dynamic>> items) => items
        .map((item) {
          final methods = (item['solution_methods'] as List? ?? const [])
              .map((raw) {
                final method = raw as Map;
                final steps = (method['steps'] as List? ?? const [])
                    .map((rawStep) {
                      final step = rawStep as Map;
                      return '${step['title'] ?? ''}|${step['content'] ?? ''}';
                    })
                    .join('||');
                return '${method['method_name'] ?? ''}|${method['source'] ?? ''}|$steps';
              })
              .join('|||');
          return '${item['stem'] ?? ''}|${item['answer'] ?? ''}|'
              '${item['explanation'] ?? ''}|$methods';
        })
        .join('\n');

    final originalSubs = (original['sub_questions'] as List? ?? const []).map(
      (item) => Map<String, dynamic>.from(item as Map),
    );
    if (subText(originalSubs) !=
        subText(_subQuestions.map((item) => item.toJson()))) {
      return true;
    }
    final originalTagIds = (original['tag_ids'] as List? ?? const [])
        .cast<int>();
    final originalTagSet = originalTagIds.toSet();
    if (originalTagSet.difference(_tagIds).isNotEmpty ||
        _tagIds.difference(originalTagSet).isNotEmpty ||
        _newTags.isNotEmpty) {
      return true;
    }
    final originalSource = Map<String, dynamic>.from(
      original['source'] as Map? ?? const {},
    );
    final currentSource = Map<String, dynamic>.from(
      _editedPayload()['source'] as Map? ?? const {},
    );
    for (final key in const [
      'source_type',
      'year',
      'region',
      'source_name',
      'question_number',
    ]) {
      if ('${originalSource[key] ?? ''}' != '${currentSource[key] ?? ''}') {
        return true;
      }
    }
    return false;
  }

  Future<void> _submit() async {
    if (_isSolution) {
      if (_questionId == null || _targetSubQuestionId == null) {
        setState(() => _error = '请先选择题目和具体小题');
        return;
      }
      if (_methodNameController.text.trim().isEmpty ||
          _solutionSteps.isEmpty ||
          _solutionSteps.any(
            (step) =>
                step.title.text.trim().isEmpty ||
                step.content.text.trim().isEmpty,
          )) {
        setState(() => _error = '请填写解法名称以及每一步的标题和内容');
        return;
      }
    } else if (_isCorrection) {
      if (_correctionCategories.isEmpty) {
        setState(() => _error = '请至少选择一个错误类型');
        return;
      }
      if (_descriptionController.text.trim().length < 10) {
        setState(() => _error = '问题说明至少需要 10 个字符');
        return;
      }
      if (_provideCorrection &&
          (_payload == null ||
              _stemController.text.trim().isEmpty ||
              _subQuestions.isEmpty ||
              _subQuestions.any((sub) => sub.answer.text.trim().isEmpty))) {
        setState(() => _error = '修改方案中的题干和答案不能为空');
        return;
      }
      if (_provideCorrection && !_hasQuestionChanges()) {
        setState(() => _error = '请至少修改一个题目字段');
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
    if (!_isCorrection && !_isSolution && _tagIds.isEmpty && _newTags.isEmpty) {
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
        'contribution_type': _isSolution
            ? 'new_solution'
            : _isCorrection
            ? 'question_correction'
            : 'new_question',
        if (!_isCorrection)
          'content_origin': _isOriginal ? 'original' : 'external',
        if (_isCorrection || _isSolution) 'question_id': _questionId,
        if (_isSolution) 'target_sub_question_id': _targetSubQuestionId,
        'raw_json': _isCorrection || _isSolution ? '' : _jsonController.text,
        'payload': _isSolution
            ? {
                'method_name': _methodNameController.text.trim(),
                'source': _methodSourceController.text.trim(),
                'summary': _methodSummaryController.text.trim(),
                if (_isOriginal) 'originality_confirmed': true,
                'steps': _solutionSteps.map((step) => step.toJson()).toList(),
              }
            : _isCorrection
            ? {
                'categories': _correctionCategories.toList(),
                'description': _descriptionController.text.trim(),
                'suggestion': '',
                'evidence': _evidenceController.text.trim(),
                if (_provideCorrection) ...{
                  'proposed_question': _editedPayload(),
                  'base_updated_at':
                      _originalQuestionPayload?['base_updated_at'],
                },
              }
            : {
                ..._editedPayload(),
                if (_isOriginal) 'originality_confirmed': true,
              },
        'tag_ids': _tagIds.toList(),
        'tag_suggestions': _newTags,
      };
      if (widget.contributionId == null) {
        await _api.create(body);
      } else {
        await _api.resubmit(widget.contributionId!, body);
      }
      if (!mounted) return;
      await _draftStore.remove(_draftId);
      if (!mounted) return;
      AppToast.success(context, '已提交审核');
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
      AppToast.success(context, 'AI 转写提示词已复制');
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
      title: Text(
        _isSolution
            ? '投稿题目解法'
            : _isCorrection
            ? '反馈题目错误'
            : _isOriginal
            ? '投稿原创题目'
            : '投稿新题',
      ),
      actions: [
        if (!_isCorrection && !_isSolution && _currentStep == 0)
          TextButton.icon(
            onPressed: _showJsonImportDialog,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('AI 结果导入'),
          ),
        IconButton(
          tooltip: '编辑格式说明',
          onPressed: () =>
              RouterUtils.push(context, AppRoutes.contributionHelp),
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
      bottom: _loading
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: _buildProgress(),
              ),
            ),
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
                _buildCurrentStep(),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: AppButton(
                          label: '上一步',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => setState(() => _currentStep--),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: AppSpacing.sm),
                    if (_currentStep > 0) ...[
                      Expanded(
                        child: AppButton(
                          label: '保存草稿',
                          icon: Icons.save_outlined,
                          variant: AppButtonVariant.secondary,
                          onPressed: _saveDraftNow,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: AppButton(
                        label: _currentStep == _stepTitles.length - 1
                            ? _submitting
                                  ? '正在提交'
                                  : '提交审核'
                            : '下一步：预览并提交',
                        icon: _currentStep == _stepTitles.length - 1
                            ? Icons.send_outlined
                            : Icons.arrow_forward_rounded,
                        onPressed: _submitting
                            ? null
                            : _currentStep == _stepTitles.length - 1
                            ? _submit
                            : () {
                                setState(() => _currentStep++);
                                _queueDraftSave();
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
  );

  List<String> get _stepTitles => const ['编辑内容', '预览并提交'];

  Widget _buildProgress() => Row(
    children: [
      for (var index = 0; index < _stepTitles.length; index++) ...[
        Expanded(
          child: InkWell(
            onTap: index <= _currentStep
                ? () => setState(() => _currentStep = index)
                : null,
            child: Column(
              children: [
                LinearProgressIndicator(value: index <= _currentStep ? 1 : 0),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _stepTitles[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: index == _currentStep
                        ? context.colors.primary
                        : context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (index < _stepTitles.length - 1)
          const SizedBox(width: AppSpacing.xs),
      ],
    ],
  );

  Widget _buildCurrentStep() {
    if (_isSolution) {
      return _currentStep == 0
          ? Column(
              children: [
                _buildQuestionTarget(),
                const SizedBox(height: AppSpacing.md),
                _buildSolutionForm(),
                const SizedBox(height: AppSpacing.md),
                _buildTags(),
              ],
            )
          : _buildReview();
    }
    if (_isCorrection) {
      return _currentStep == 0 ? _buildCorrectionForm() : _buildReview();
    }
    return _currentStep == 0
        ? Column(
            children: [
              if (_repairs.isNotEmpty) ...[
                _buildRepairs(),
                const SizedBox(height: AppSpacing.md),
              ],
              _buildStructuredEditor(),
              const SizedBox(height: AppSpacing.md),
              _buildTags(),
            ],
          )
        : _buildReview();
  }

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
                  for (
                    var methodIndex = 0;
                    methodIndex < _subQuestions[index].methods.length;
                    methodIndex++
                  )
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: _buildQuestionMethodEditor(index, methodIndex),
                    ),
                  TextButton.icon(
                    onPressed: () => setState(
                      () => _subQuestions[index].methods.add(
                        _QuestionMethodEditor(const {}),
                      ),
                    ),
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text('增加完整分步解法（选填）'),
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
              child: QuestionOptionRow(
                label: option.key.text,
                content: option.content.text,
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

  Widget _buildQuestionMethodEditor(int subIndex, int methodIndex) {
    final method = _subQuestions[subIndex].methods[methodIndex];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('解法 ${methodIndex + 1}')),
                IconButton(
                  tooltip: '删除解法',
                  onPressed: () => setState(
                    () => _subQuestions[subIndex].methods
                        .removeAt(methodIndex)
                        .dispose(),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            TextField(
              controller: method.name,
              decoration: const InputDecoration(labelText: '解法名称'),
            ),
            for (
              var stepIndex = 0;
              stepIndex < method.steps.length;
              stepIndex++
            )
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Column(
                  children: [
                    TextField(
                      controller: method.steps[stepIndex].title,
                      decoration: InputDecoration(
                        labelText: '第 ${stepIndex + 1} 步标题',
                      ),
                    ),
                    _LatexField(
                      label: '步骤内容',
                      controller: method.steps[stepIndex].content,
                      minLines: 2,
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () =>
                  setState(() => method.steps.add(_SolutionStepEditor())),
              icon: const Icon(Icons.add_rounded),
              label: const Text('增加步骤'),
            ),
          ],
        ),
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
    return Column(
      children: [
        AppCard(
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
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('只报告问题')),
                  ButtonSegment(value: true, label: Text('提供修改方案')),
                ],
                selected: {_provideCorrection},
                onSelectionChanged: (selection) =>
                    _setCorrectionProposalMode(selection.first),
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
                label: '验算或依据（选填）',
                controller: _evidenceController,
                minLines: 3,
                initialPreview: false,
              ),
            ],
          ),
        ),
        if (_provideCorrection && _payload != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildStructuredEditor(),
          const SizedBox(height: AppSpacing.md),
          _buildTags(),
        ],
      ],
    );
  }
}

class _DiffBlock extends StatelessWidget {
  const _DiffBlock({
    required this.label,
    required this.before,
    required this.after,
  });

  final String label;
  final String before;
  final String after;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: AppSpacing.xs),
      Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.colors.errorContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('- ', style: TextStyle(color: context.colors.error)),
            Expanded(child: MdLatexBody(before.isEmpty ? '未加载原内容' : before)),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.colors.successContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('+ ', style: TextStyle(color: context.colors.success)),
            Expanded(child: MdLatexBody(after.isEmpty ? '未提供修改方案' : after)),
          ],
        ),
      ),
    ],
  );
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
      explanation = TextEditingController(text: '${json['explanation'] ?? ''}'),
      methods = (json['solution_methods'] as List? ?? const [])
          .map(
            (item) =>
                _QuestionMethodEditor(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
  final TextEditingController stem;
  final TextEditingController answer;
  final TextEditingController explanation;
  final List<_QuestionMethodEditor> methods;
  Map<String, dynamic> toJson() => {
    'stem': stem.text.trim(),
    'answer': answer.text.trim(),
    'explanation': explanation.text.trim(),
    'solution_methods': methods.map((method) => method.toJson()).toList(),
  };
  void dispose() {
    stem.dispose();
    answer.dispose();
    explanation.dispose();
    for (final method in methods) {
      method.dispose();
    }
  }
}

class _QuestionMethodEditor {
  _QuestionMethodEditor(Map<String, dynamic> json)
    : name = TextEditingController(text: '${json['method_name'] ?? ''}'),
      source = TextEditingController(text: '${json['source'] ?? ''}'),
      steps = (json['steps'] as List? ?? const [])
          .map(
            (item) => _SolutionStepEditor.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList() {
    if (steps.isEmpty) steps.add(_SolutionStepEditor());
  }

  final TextEditingController name;
  final TextEditingController source;
  final List<_SolutionStepEditor> steps;

  Map<String, dynamic> toJson() => {
    'method_name': name.text.trim(),
    'source': source.text.trim(),
    'steps': steps.map((step) => step.toJson()).toList(),
  };

  void dispose() {
    name.dispose();
    source.dispose();
    for (final step in steps) {
      step.dispose();
    }
  }
}

class _SolutionStepEditor {
  _SolutionStepEditor({String title = '', String content = ''})
    : title = TextEditingController(text: title),
      content = TextEditingController(text: content);

  factory _SolutionStepEditor.fromJson(Map<String, dynamic> json) =>
      _SolutionStepEditor(
        title: '${json['title'] ?? ''}',
        content: '${json['content'] ?? ''}',
      );

  final TextEditingController title;
  final TextEditingController content;

  Map<String, dynamic> toJson() => {
    'title': title.text.trim(),
    'content': content.text.trim(),
    'card_titles': <String>[],
  };

  void dispose() {
    title.dispose();
    content.dispose();
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
