import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// YouTube preview image (16:9) with a play button on top.
class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({super.key, required this.videoId, this.showPlay = true});

  final String? videoId;
  final bool showPlay;

  Widget _placeholder() {
    return Container(
      color: AppColors.tilePurple,
      alignment: Alignment.center,
      child: const Icon(
        Icons.smart_display_rounded,
        size: 40,
        color: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = videoId;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (id == null)
            _placeholder()
          else
            Image.network(
              'https://img.youtube.com/vi/$id/hqdefault.jpg',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stack) => _placeholder(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(color: AppColors.tilePurple);
              },
            ),
          if (showPlay && id != null)
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}