import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../tests/tests_repository.dart' show friendlyError;
import 'video_thumbnail.dart';
import 'videos_repository.dart';

/// Lecturer/Admin: add or edit a YouTube video.
class VideoEditorPage extends StatefulWidget {
  const VideoEditorPage({super.key, this.video});

  /// Null when adding a new video.
  final VideoItem? video;

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();

  bool _published = true;
  bool _busy = false;

  bool get _isEditing => widget.video != null;

  @override
  void initState() {
    super.initState();
    final v = widget.video;
    if (v == null) return;
    _titleController.text = v.title;
    _descriptionController.text = v.description ?? '';
    _urlController.text = v.youtubeUrl;
    _published = v.isPublished;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final videoId = extractYoutubeId(_urlController.text)!;

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await VideosRepository.instance.save(
        existing: widget.video,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        videoId: videoId,
        published: _published,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = extractYoutubeId(_urlController.text);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit video' : 'New video')),
      body: Form(
        key: _formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'YouTube link',
                    hintText: 'https://www.youtube.com/watch?v=...',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Paste a YouTube link';
                    }
                    if (extractYoutubeId(value) == null) {
                      return 'This is not a valid YouTube link';
                    }
                    return null;
                  },
                ),
                if (videoId != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: VideoThumbnail(videoId: videoId, showPlay: false),
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a title'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _published,
                  onChanged: _busy ? null : (v) => setState(() => _published = v),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  title: const Text('Published'),
                  subtitle: const Text(
                    'Students can only see published videos.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(_isEditing ? 'Save changes' : 'Add video'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}