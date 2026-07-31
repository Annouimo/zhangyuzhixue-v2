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
    return AppContentContainer(
      maxWidth: AppContentWidth.standard,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          AppNavigationList(
            children: catalog
                .map(
                  (category) => AppNavigationListItem(
                    icon: Icons.video_library_outlined,
                    title: category.name,
                    subtitle: [
                      category.description,
                      '共 ${category.videos.length} 个视频',
                    ].where((value) => value.isNotEmpty).join(' · '),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _VideoCategoryPage(
                          category: category,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

}

class _VideoCategoryPage extends StatelessWidget {
  const _VideoCategoryPage({required this.category});

  final VideoCategorySection category;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(category.name)),
    body: category.videos.isEmpty
        ? EmptyPlaceholder(
            icon: Icons.video_library_outlined,
            message: '该分类暂无已发布视频',
          )
        : AppContentContainer(
            maxWidth: AppContentWidth.standard,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                if (category.description.isNotEmpty) ...[
                  AppPageHint(message: category.description),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppNavigationList(
                  children: category.videos
                      .map(
                        (video) => AppNavigationListItem(
                          icon: Icons.play_circle_outline_rounded,
                          title: video.title,
                          subtitle: video.description.isNotEmpty
                              ? video.description
                              : video.platformName,
                          onTap: () => RouterUtils.push(
                            context,
                            '${AppRoutes.videoDetail}?videoId=${video.id}',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
  );
}
