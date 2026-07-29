import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/api/api_client.dart';
import '../../data/api/contribution_api.dart';
import '../question_bank/question_detail_page.dart';
import '../router.dart';

class ContributionDetailPage extends StatefulWidget {
  const ContributionDetailPage({super.key, required this.contributionId});

  final int contributionId;

  @override
  State<ContributionDetailPage> createState() => _ContributionDetailPageState();
}

class _ContributionDetailPageState extends State<ContributionDetailPage> {
  late final ContributionApi _api = ContributionApi(ApiClient());
  Map<String, dynamic>? _detail;
  String? _error;
  bool _loading = true;
  bool _showAllHistory = false;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _api.getDetail(widget.contributionId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '贡献详情加载失败';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('贡献详情'),
      actions: [
        IconButton(
          tooltip: '刷新',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: _loading
        ? const LoadingIndicator(message: '正在加载贡献详情')
        : _error != null
        ? ErrorPlaceholder(message: _error!, onRetry: _load)
        : _buildContent(),
  );

  Widget _buildContent() {
    final detail = _detail!;
    final status = detail['status'] as String? ?? 'pending';
    final isCorrection = detail['contribution_type'] == 'question_correction';
    final submissionPayload = Map<String, dynamic>.from(
      detail['payload'] as Map? ?? const {},
    );
    final officialPayload = detail['official_payload'] == null
        ? null
        : Map<String, dynamic>.from(detail['official_payload'] as Map);
    final history = (detail['history'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isCorrection ? '题目纠错' : '新题投稿',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    AppStatusBadge(
                      label: _statusLabel(status),
                      tone: _statusTone(status),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('第 ${detail['revision_number'] ?? 1} 版'),
                if ((detail['review_note'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('审核意见：${detail['review_note']}'),
                ],
                if (status == 'approved_pending_release') ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text('题目已经审核入库，将在下一版题库数据发布后出现在题库中。'),
                ],
                if (status == 'completed') ...[
                  const SizedBox(height: AppSpacing.sm),
                  if (detail['published_qbank_version'] != null)
                    Text('首次发布于题库 v${detail['published_qbank_version']}')
                  else
                    const Text('已发布至题库'),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: isCorrection
                ? _buildCorrection(submissionPayload)
                : _buildQuestion(officialPayload ?? submissionPayload),
          ),
          if (isCorrection) ...[
            const SizedBox(height: AppSpacing.md),
            _buildCorrectionQuestionComparison(
              Map<String, dynamic>.from(
                detail['question_snapshot'] as Map? ?? const {},
              ),
              officialPayload,
            ),
          ],
          if ((detail['selected_tags'] as List? ?? const []).isNotEmpty ||
              (detail['tag_suggestions'] as List? ?? const []).isNotEmpty ||
              (detail['official_tags'] as List? ?? const []).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildTagsCard(detail),
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildHistory(history),
          ],
          if (status == 'needs_revision') ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: '修改并重新提交',
              icon: Icons.edit_outlined,
              fullWidth: true,
              onPressed: () async {
                final changed = await RouterUtils.push<bool>(
                  context,
                  '${AppRoutes.contributionEdit}?id=${widget.contributionId}',
                );
                if (changed == true) _load();
              },
            ),
          ],
          if (status == 'completed' &&
              detail['completed_question_id'] != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: isCorrection ? '查看处理后的题目' : '在题库中查看',
              icon: Icons.menu_book_outlined,
              fullWidth: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudentQuestionDetailPage(
                    questionId: detail['completed_question_id'] as int,
                  ),
                ),
              ),
            ),
          ],
          if (isCorrection &&
              status != 'completed' &&
              detail['question_id'] != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: status == 'completed' ? '查看原题' : '返回关联题目',
              icon: Icons.find_in_page_outlined,
              variant: AppButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => StudentQuestionDetailPage(
                    questionId: detail['question_id'] as int,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> payload) {
    final options = payload['options'] as List? ?? const [];
    final subs = payload['sub_questions'] as List? ?? const [];
    final source = Map<String, dynamic>.from(
      payload['source'] as Map? ?? const {},
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _detail!['official_payload'] == null ? '投稿内容' : '审核录入结果',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        MdLatexBody('${payload['stem'] ?? ''}', fontSize: 16),
        for (final raw in options)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: MdLatexBody('${(raw as Map)['key']}. ${raw['content']}'),
          ),
        for (final raw in subs) ...[
          const SizedBox(height: AppSpacing.md),
          MdLatexBody('答案：${(raw as Map)['answer'] ?? ''}'),
          MdLatexBody('解析：${raw['explanation'] ?? ''}'),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(_sourceLabel(source)),
      ],
    );
  }

  Widget _buildCorrection(Map<String, dynamic> payload) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('纠错内容', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.md),
      if ((payload['categories'] as List? ?? const []).isNotEmpty) ...[
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final category in payload['categories'] as List)
              Chip(label: Text(_categoryLabel('$category'))),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      Text('问题说明', style: Theme.of(context).textTheme.titleSmall),
      MdLatexBody('${payload['description'] ?? ''}'),
      const SizedBox(height: AppSpacing.sm),
      Text('修改建议', style: Theme.of(context).textTheme.titleSmall),
      MdLatexBody('${payload['suggestion'] ?? '-'}'),
      const SizedBox(height: AppSpacing.sm),
      Text('依据', style: Theme.of(context).textTheme.titleSmall),
      MdLatexBody('${payload['evidence'] ?? '-'}'),
    ],
  );

  Widget _buildCorrectionQuestionComparison(
    Map<String, dynamic> snapshot,
    Map<String, dynamic>? official,
  ) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          official == null ? '提交时的原题' : '原题与审核录入结果',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('提交时原题', style: Theme.of(context).textTheme.titleSmall),
        _buildSnapshotQuestion(snapshot),
        if (official != null) ...[
          const Divider(height: AppSpacing.xl),
          Text('审核录入结果', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _buildQuestionBody(official),
        ],
      ],
    ),
  );

  Widget _buildSnapshotQuestion(Map<String, dynamic> snapshot) {
    final options = Map<String, dynamic>.from(
      snapshot['options'] as Map? ?? const {},
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        MdLatexBody('${snapshot['stem'] ?? ''}'),
        for (final entry in options.entries)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: MdLatexBody('${entry.key}. ${entry.value}'),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          [
            snapshot['year'],
            snapshot['region'],
            snapshot['source_name'],
            snapshot['number'],
          ].where((value) => value != null && '$value'.isNotEmpty).join(' · '),
        ),
      ],
    );
  }

  Widget _buildQuestionBody(Map<String, dynamic> payload) {
    final options = payload['options'] as List? ?? const [];
    final subs = payload['sub_questions'] as List? ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MdLatexBody('${payload['stem'] ?? ''}'),
        for (final raw in options)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: MdLatexBody('${(raw as Map)['key']}. ${raw['content']}'),
          ),
        for (final raw in subs) ...[
          const SizedBox(height: AppSpacing.sm),
          MdLatexBody('答案：${(raw as Map)['answer'] ?? ''}'),
          MdLatexBody('解析：${raw['explanation'] ?? ''}'),
        ],
      ],
    );
  }

  Widget _buildTagsCard(Map<String, dynamic> detail) {
    final selected = detail['selected_tags'] as List? ?? const [];
    final suggestions = detail['tag_suggestions'] as List? ?? const [];
    final official = detail['official_tags'] as List? ?? const [];
    Widget tagWrap(List items) => Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final raw in items)
          Chip(label: Text('${(raw as Map)['name'] ?? '-'}')),
      ],
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('标签', style: Theme.of(context).textTheme.titleMedium),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text('投稿选择'),
            tagWrap(selected),
          ],
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text('新标签建议'),
            tagWrap(suggestions),
          ],
          if (official.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text('最终正式标签'),
            tagWrap(official),
          ],
        ],
      ),
    );
  }

  Widget _buildHistory(List<Map<String, dynamic>> history) {
    final visible = _showAllHistory || history.length <= 3
        ? history
        : history.sublist(history.length - 3);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('处理记录', style: Theme.of(context).textTheme.titleMedium),
          if (!_showAllHistory && history.length > 3)
            TextButton(
              onPressed: () => setState(() => _showAllHistory = true),
              child: Text('查看更早的 ${history.length - 3} 条记录'),
            ),
          for (var index = 0; index < visible.length; index++)
            _historyItem(visible[index], index < visible.length - 1),
        ],
      ),
    );
  }

  Widget _historyItem(
    Map<String, dynamic> event,
    bool hasNext,
  ) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Icon(_actionIcon('${event['action']}'), size: 18),
              if (hasNext)
                Expanded(
                  child: Container(width: 1, color: context.colors.divider),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _actionLabel('${event['action']}'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${_actorLabel('${event['actor_role']}')} · ${_formatTime('${event['created_at']}')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                if ((event['note'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(event['note'] as String),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );

  String _sourceLabel(Map<String, dynamic> source) => [
    source['year'],
    source['region'],
    source['source_name'] ?? source['exam_name'],
    source['question_number'] ?? source['number'],
  ].where((value) => value != null && '$value'.trim().isNotEmpty).join(' · ');

  String _statusLabel(String status) => switch (status) {
    'pending' => '待首次审核',
    'resubmitted' => '修改后待复审',
    'needs_revision' => '待修改',
    'processing' => '处理中',
    'approved_pending_release' => '已通过，待发布',
    'completed' => '已发布',
    'rejected' => '未采纳',
    'withdrawn' => '已撤回',
    _ => status,
  };

  AppStatusTone _statusTone(String status) => switch (status) {
    'completed' => AppStatusTone.success,
    'needs_revision' => AppStatusTone.warning,
    'processing' || 'approved_pending_release' => AppStatusTone.info,
    'rejected' || 'withdrawn' => AppStatusTone.neutral,
    _ => AppStatusTone.primary,
  };

  String _actionLabel(String action) => switch (action) {
    'submitted' => '已提交',
    'resubmitted' => '修改后重新提交',
    'processing' => '开始处理',
    'needs_revision' => '打回修改',
    'completed' => '审核通过',
    'published' => '已发布到题库',
    'publication_rolled_back' => '题库发布已回滚',
    'rejected' => '未采纳',
    'withdrawn' => '已撤回',
    _ => action,
  };

  IconData _actionIcon(String action) => switch (action) {
    'submitted' || 'resubmitted' => Icons.upload_file_outlined,
    'processing' => Icons.manage_search_outlined,
    'needs_revision' => Icons.reply_outlined,
    'completed' => Icons.task_alt_outlined,
    'published' => Icons.cloud_done_outlined,
    'publication_rolled_back' => Icons.settings_backup_restore_outlined,
    'rejected' => Icons.block_outlined,
    'withdrawn' => Icons.undo_outlined,
    _ => Icons.circle_outlined,
  };

  String _actorLabel(String role) => switch (role) {
    'student' => '投稿人',
    'reviewer' => '审核员',
    _ => '系统',
  };

  String _formatTime(String raw) {
    final value = DateTime.tryParse(raw)?.toLocal();
    if (value == null) return raw;
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  String _categoryLabel(String category) => switch (category) {
    'stem' => '题干错误',
    'options' => '选项错误',
    'answer' => '答案错误',
    'explanation' => '解析错误',
    'tags' => '标签错误',
    'source' => '来源错误',
    'formatting' => '公式或排版',
    'duplicate' => '重复题目',
    'other' => '其他',
    _ => category,
  };
}
