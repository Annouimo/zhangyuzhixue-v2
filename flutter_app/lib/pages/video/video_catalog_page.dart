import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../../data/daos/lecture_dao.dart';
import '../../data/daos/video_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/video_repository.dart';
import '../router.dart';

class VideoCatalogPage extends StatefulWidget {
  const VideoCatalogPage({
    super.key,
    this.videoRepository,
    this.catalogLoader,
    this.embedded = false,
  });

  final VideoRepository? videoRepository;
  final Future<List<VideoCategorySection>> Function()? catalogLoader;
  final bool embedded;

  @override
  State<VideoCatalogPage> createState() => _VideoCatalogPageState();
}

class _VideoCatalogPageState extends State<VideoCatalogPage> {
  late final Future<List<VideoCategorySection>> Function() _loadCatalog;
  List<VideoCategorySection>? _catalog;
  int? _selectedCategoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.catalogLoader case final loader?) {
      _loadCatalog = loader;
    } else {
      final provider = DatabaseProvider();
      final repository =
          widget.videoRepository ??
          VideoRepository(VideoDao(provider), LectureDao(provider));
      _loadCatalog = repository.getCatalog;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await _loadCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _selectedCategoryId ??= catalog.isEmpty ? null : catalog.first.id;
        _loading = false;
      });
    } catch (error) {
      OperationLog.instance.error('video_catalog_page_load', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('视频')),
      body: body,
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载视频目录…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final catalog = _catalog ?? const <VideoCategorySection>[];
    if (catalog.isEmpty) {
      return EmptyPlaceholder(
        icon: Icons.video_library_outlined,
        message: '视频目录暂时为空',
      );
    }
    final selected = catalog.firstWhere(
      (category) => category.id == _selectedCategoryId,
      orElse: () => catalog.first,
    );
    return AppContentContainer(
      maxWidth: AppContentWidth.dashboard,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final selectedId = _selectedCategoryId ?? catalog.first.id;
              if (constraints.maxWidth < AppBreakpoints.medium) {
                return Wrap(
                  key: const ValueKey('video-category-wrap'),
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: catalog
                      .map(
                        (category) => ChoiceChip(
                          label: Text(category.name),
                          selected: category.id == selectedId,
                          onSelected: (_) => setState(
                            () => _selectedCategoryId = category.id,
                          ),
                        ),
                      )
                      .toList(),
                );
              }
              return SingleChildScrollView(
                key: const ValueKey('video-category-segmented'),
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<int>(
                  segments: catalog
                      .map(
                        (category) => ButtonSegment<int>(
                          value: category.id,
                          label: Text(category.name),
                        ),
                      )
                      .toList(),
                  selected: {selectedId},
                  onSelectionChanged: (selection) =>
                      setState(() => _selectedCategoryId = selection.first),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: selected.name,
            subtitle: selected.description,
          ),
          const SizedBox(height: AppSpacing.md),
          if (selected.videos.isEmpty)
            EmptyPlaceholder(
              icon: Icons.video_library_outlined,
              message: '该分类暂无已发布视频',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 560
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - AppSpacing.md * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: selected.videos
                      .map(
                        (video) => SizedBox(
                          width: width,
                          child: _VideoCard(video: video),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});

  final VideoSummary video;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => RouterUtils.push(
      context,
      '${AppRoutes.videoDetail}?videoId=${video.id}',
    ),
    semanticLabel: video.title,
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (video.coverUrl.isNotEmpty)
          _VideoCover(url: video.coverUrl),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                size: AppControlSize.sm,
                color: context.colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video.platformName.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        video.platformName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _VideoCover extends StatefulWidget {
  const _VideoCover({required this.url});

  final String url;

  @override
  State<_VideoCover> createState() => _VideoCoverState();
}

class _VideoCoverState extends State<_VideoCover> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    return AspectRatio(
      key: const ValueKey('video-cover'),
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.medium),
        ),
        child: CachedNetworkImage(
          imageUrl: widget.url,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _failed = true);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
