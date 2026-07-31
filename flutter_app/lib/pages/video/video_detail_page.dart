import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/daos/lecture_dao.dart';
import '../../data/daos/video_dao.dart';
import '../../data/database/database_provider.dart';
import '../../domain/video_repository.dart';
import '../router.dart';

class VideoDetailPage extends StatefulWidget {
  const VideoDetailPage({
    super.key,
    required this.videoId,
    this.videoRepository,
  });

  final int videoId;
  final VideoRepository? videoRepository;

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  late final VideoRepository _repository;
  VideoDetail? _video;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final provider = DatabaseProvider();
    _repository = widget.videoRepository ??
        VideoRepository(VideoDao(provider), LectureDao(provider));
    _load();
  }

  Future<void> _load() async {
    try {
      final video = await _repository.getDetail(widget.videoId);
      if (!mounted) return;
      setState(() {
        _video = video;
        _loading = false;
      });
    } catch (error) {
      OperationLog.instance.error('video_detail_page_load', error);
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  Future<void> _openVideo() async {
    final uri = Uri.tryParse(_video?.videoUrl ?? '');
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开视频链接')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_video?.title ?? '视频详情')),
        body: _buildBody(),
      );

  Widget _buildBody() {
    if (_loading) return const LoadingIndicator(message: '加载视频…');
    if (_error != null) {
      return ErrorPlaceholder(message: _error!, onRetry: _load);
    }
    final video = _video!;
    return AppContentContainer(
      maxWidth: AppContentWidth.reading,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: video.coverUrl.isEmpty
                  ? ColoredBox(
                      color: context.colors.surfaceSubtle,
                      child: const Icon(Icons.play_circle_outline_rounded,
                          size: 64),
                    )
                  : CachedNetworkImage(
                      imageUrl: video.coverUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(video.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label: video.categoryName,
                tone: AppStatusTone.info,
                compact: true,
              ),
              if (video.platformName.isNotEmpty)
                AppStatusBadge(
                  label: video.platformName,
                  tone: AppStatusTone.neutral,
                  compact: true,
                ),
            ],
          ),
          if (video.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(video.description),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: _openVideo,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(video.platformName.isEmpty
                ? '前往观看'
                : '前往${video.platformName}观看'),
          ),
          if (video.relatedLectures.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(title: '相关讲义', compact: true),
            const SizedBox(height: AppSpacing.sm),
            for (final lecture in video.relatedLectures) ...[
              AppCard(
                onTap: () => RouterUtils.push(
                  context,
                  '${AppRoutes.lectureContent}?chapterId=${lecture.chapterId}&page=1',
                ),
                semanticLabel: lecture.title,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(lecture.title),
                  subtitle: Text([
                    lecture.courseName,
                    lecture.relationLabel,
                  ].where((value) => value.isNotEmpty).join(' · ')),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}
