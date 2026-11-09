import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../tests/tests_repository.dart' show friendlyError;
import 'video_editor_page.dart';
import 'video_player_page.dart';
import 'video_thumbnail.dart';
import 'videos_repository.dart';

/// Video lessons (YouTube). Opened from the Home menu.
/// Lecturers/admins can add, edit and delete videos.
class VideosPage extends StatefulWidget {
  const VideosPage({super.key, required this.role});

  final String role;

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  List<VideoItem> _videos = [];
  bool _loading = true;
  String? _error;

  bool get _canManage => widget.role == 'lecturer' || widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final videos = await VideosRepository.instance.loadVideos();
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _open(VideoItem video) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(video: video, role: widget.role),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _add() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const VideoEditorPage()),
    );
    if (changed == true && mounted) _load();
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.textGrey),
              const SizedBox(height: 12),
              const Text(
                'Could not load videos.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: _load,
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_videos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.smart_display_outlined,
                size: 48, color: AppColors.textGrey),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _canManage
                    ? 'No videos yet. Tap "Add video".'
                    : 'No videos yet.',
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 8, 20, _canManage ? 96 : 24),
            itemCount: _videos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final video = _videos[index];
              return _VideoCard(
                video: video,
                showStatus: _canManage,
                onTap: () => _open(video),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add video'),
      )
          : null,
      body: _body(),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.video,
    required this.showStatus,
    required this.onTap,
  });

  final VideoItem video;
  final bool showStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VideoThumbnail(videoId: video.videoId),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  if (video.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textGrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (showStatus) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: video.isPublished
                            ? AppColors.tileGreen
                            : AppColors.tileYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        video.isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: video.isPublished
                              ? const Color(0xFF15803D)
                              : const Color(0xFFA16207),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}