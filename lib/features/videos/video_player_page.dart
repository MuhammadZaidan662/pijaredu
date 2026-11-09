import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../tests/tests_repository.dart' show friendlyError;
import 'video_editor_page.dart';
import 'videos_repository.dart';
import 'youtube_player_view.dart';

/// Plays one video inside the app. If the owner of a YouTube video has
/// disabled embedding, "Open in YouTube" is always available as a fallback.
class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key, required this.video, required this.role});

  final VideoItem video;
  final String role;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  bool _busy = false;

  bool get _isStaff => widget.role != 'student';

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openInYoutube() async {
    final id = widget.video.videoId;
    final url = id == null
        ? widget.video.youtubeUrl
        : 'https://www.youtube.com/watch?v=$id';
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _message('Could not open YouTube.');
    } catch (_) {
      if (mounted) _message('Could not open YouTube.');
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VideoEditorPage(video: widget.video)),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this video?'),
        content: const Text('Students will no longer see it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await VideosRepository.instance.delete(widget.video.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _message(friendlyError(e));
    }
  }

  Widget _details() {
    final video = widget.video;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            video.title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (video.description != null) ...[
            const SizedBox(height: 10),
            Text(
              video.description!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
                height: 1.55,
              ),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _openInYoutube,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open in YouTube'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      title: const Text('Video'),
      actions: [
        if (_isStaff) ...[
          IconButton(
            tooltip: 'Edit video',
            onPressed: _busy ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete video',
            onPressed: _busy ? null : _delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.video.videoId;

    if (id == null) {
      return Scaffold(
        appBar: _appBar(),
        body: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'This video link is not a valid YouTube link.',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
            _details(),
          ],
        ),
      );
    }

    return YoutubeScaffold(
      videoId: id,
      builder: (context, player) => Scaffold(
        appBar: _appBar(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              player,
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _details(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}