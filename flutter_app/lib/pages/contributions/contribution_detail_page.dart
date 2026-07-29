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
    final payload = Map<String, dynamic>.from(
      (status == 'approved_pending_release' || status == 'completed')
          ? detail['official_payload'] as Map? ??
                detail['payload'] as Map? ??
                const {}
          : detail['payload'] as Map? ?? const {},
    );
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
                  Text('已发布至题库 v${detail['published_qbank_version'] ?? '-'}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: isCorrection
                ? _buildCorrection(payload)
                : _buildQuestion(payload),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('处理记录', style: Theme.of(context).textTheme.titleMedium),
                  for (final event in history)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_actionLabel('${event['action']}')),
                      subtitle: (event['note'] as String?)?.isNotEmpty == true
                          ? Text(event['note'] as String)
                          : null,
                    ),
                ],
              ),
            ),
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
              label: '在题库中查看',
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
      MdLatexBody('问题说明：${payload['description'] ?? ''}'),
      const SizedBox(height: AppSpacing.sm),
      MdLatexBody('修改建议：${payload['suggestion'] ?? ''}'),
      const SizedBox(height: AppSpacing.sm),
      Text('依据：${payload['evidence'] ?? ''}'),
    ],
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
    'rejected' => '未采纳',
    'withdrawn' => '已撤回',
    _ => action,
  };
}
