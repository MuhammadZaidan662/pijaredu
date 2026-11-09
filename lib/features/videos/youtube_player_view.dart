import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// The only place that talks to the `youtube_player_iframe` package.
/// If a new package version changes its API, only this file needs editing.
///
/// [builder] receives the ready-made player widget. It is rendered inside a
/// scaffold that also handles the fullscreen / landscape mode of the player.
class YoutubeScaffold extends StatefulWidget {
  const YoutubeScaffold({
    super.key,
    required this.videoId,
    required this.builder,
  });

  final String videoId;
  final Widget Function(BuildContext context, Widget player) builder;

  @override
  State<YoutubeScaffold> createState() => _YoutubeScaffoldState();
}

class _YoutubeScaffoldState extends State<YoutubeScaffold> {
  late final YoutubePlayerController _controller =
  YoutubePlayerController.fromVideoId(
    videoId: widget.videoId,
    autoPlay: false,
    params: const YoutubePlayerParams(showFullscreenButton: true),
  );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      builder: widget.builder,
    );
  }
}