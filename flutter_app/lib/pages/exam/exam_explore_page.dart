import 'package:flutter/material.dart';
import '../router.dart';
import 'package:shared/theme/app_theme.dart';
import '../../../data/daos/exam_dao.dart';
import '../../../data/daos/question_dao.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/exam_repository.dart';
import 'package:shared/widgets/empty_placeholder.dart';
import '../../../widgets/shared/action_chip.dart';
import '../../../widgets/shared/async_load_widget.dart';
import '../../../data/helpers/pdf_helper.dart';
import 'widgets/paper_card.dart';
import 'package:shared/debug/audit_logger.dart';


/// 发现组卷 — 匹配 HTML 原型 paper_explore.html
class ExamExplorePage extends StatefulWidget {
  final ExamRepository? examRepository;
  ExamExplorePage({super.key, this.examRepository});

  @override
  State<ExamExplorePage> createState() => _ExamExplorePageState();
}

class _ExamExplorePageState extends State<ExamExplorePage> {
  late final ExamRepository _repo;
  final GlobalKey<AsyncLoadWidgetState<List<ExploreExamSummary>>> _loadKey = GlobalKey();
  String _sortBy = 'latest'; // latest / collectCount / likeCount

  static const _sortOptions = [
    ('latest', '最新'),
    ('collectCount', '收藏'),
    ('likeCount', '点赞'),
    ('diff', '热度'),
  ];

  @override
  void initState() {
    super.initState();
    _repo = widget.examRepository ?? ExamRepository(
      QuestionDao(DatabaseProvider()), ExamDao(DatabaseProvider()),
    );
  }

  Future<void> _toggleLike(int examId) async {
    // 乐观更新
    _loadKey.currentState?.optimisticUpdate((list) {
      final idx = list.indexWhere((e) => e.id == examId);
      if (idx >= 0) {
        final old = list[idx];
        list[idx] = ExploreExamSummary(
          id: old.id, name: old.name, authorInfo: old.authorInfo,
          summary: old.summary,
          likeCount: old.isLiked ? old.likeCount - 1 : old.likeCount + 1,
          collectCount: old.collectCount, createdAt: old.createdAt,
          isLiked: !old.isLiked, isCollected: old.isCollected,
        );
      }
      return list;
    });
    await _repo.toggleLike(examId);
  }

  Future<void> _toggleCollect(int examId) async {
    // 乐观更新
    _loadKey.currentState?.optimisticUpdate((list) {
      final idx = list.indexWhere((e) => e.id == examId);
      if (idx >= 0) {
        final old = list[idx];
        list[idx] = ExploreExamSummary(
          id: old.id, name: old.name, authorInfo: old.authorInfo,
          summary: old.summary,
          likeCount: old.likeCount,
          collectCount: old.isCollected ? old.collectCount - 1 : old.collectCount + 1,
          createdAt: old.createdAt,
          isLiked: old.isLiked, isCollected: !old.isCollected,
        );
      }
      return list;
    });
    await _repo.toggleCollect(examId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('发现组卷')),
    body: Column(
      children: [
        // 排序栏
        Container(
          width: double.infinity, color: context.colors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: _sortOptions.map((opt) => ChoiceChip(
              label: Text(opt.$2, style: TextStyle(fontSize: 12, color: _sortBy == opt.$1 ? context.colors.primary : context.colors.textPrimary)),
              selected: _sortBy == opt.$1,
              onSelected: (_) => setState(() => _sortBy = opt.$1),
              selectedColor: context.colors.primaryContainer,
              side: BorderSide.none,
            )).toList(),
          ),
        ),
        Expanded(
          child: AsyncLoadWidget<List<ExploreExamSummary>>(
            key: _loadKey,
            onLoad: () => _repo.getExploreList(),
            emptyWidget: EmptyPlaceholder(
              icon: Icons.search,
              message: '还没有人公开分享试卷，去首页试试快速练习吧',
            ),
            builder: (ctx, list) {
              // 排序
              final sorted = List<ExploreExamSummary>.from(list);
              switch (_sortBy) {
                case 'collectCount':
                  sorted.sort((a, b) => b.collectCount.compareTo(a.collectCount));
                  break;
                case 'likeCount':
                  sorted.sort((a, b) => b.likeCount.compareTo(a.likeCount));
                  break;
                case 'diff':
                  // 热度 = 点赞 + 收藏
                  sorted.sort((a, b) => (b.likeCount + b.collectCount).compareTo(a.likeCount + a.collectCount));
                  break;
                default: // 'latest' — 按 createdAt 倒序（DAO 默认）
                  break;
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AuditLogger.instance.page('ExamExplorePage', {'totalPapers': list.length});
              });
              return ListView.separated(
                padding: const EdgeInsets.all(AppSizes.baseSpacing),
                itemCount: sorted.length,
                separatorBuilder: (_, _) => SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final e = sorted[i];
                  return PaperCard(
                    title: e.name,
                    subtitle: e.summary.isNotEmpty ? e.summary : '${e.likeCount} 赞 · ${e.collectCount} 收藏',
                    onTap: () => RouterUtils.push(context,'${AppRoutes.examQuicklookOther}?id=${e.id}'),
                    actions: [
                      ActionChipWidget(
                        icon: e.isLiked ? Icons.favorite : Icons.favorite_border,
                        iconColor: e.isLiked ? context.colors.primary : null,
                        label: '${e.likeCount}',
                        onTap: () => _toggleLike(e.id),
                      ),
                      SizedBox(width: 8),
                      ActionChipWidget(
                        icon: e.isCollected ? Icons.bookmark : Icons.label_outline,
                        label: '${e.collectCount}',
                        onTap: () => _toggleCollect(e.id),
                      ),
                      SizedBox(width: 8),
                      ActionChipWidget(
                        icon: Icons.file_download,
                        label: 'PDF',
                        onTap: () => PdfHelper.downloadPdf(sourceId: e.id, sourceType: 'paper', context: context),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: () => RouterUtils.push(context,'${AppRoutes.examQuicklookOther}?id=${e.id}'),
                        child: Text('查看试卷', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
