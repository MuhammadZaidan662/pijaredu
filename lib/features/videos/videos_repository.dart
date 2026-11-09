import 'package:supabase_flutter/supabase_flutter.dart';

final _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Returns the 11-character YouTube video id from a link, or null.
/// Accepts youtube.com/watch?v=..., youtu.be/..., /embed/, /shorts/, /live/
/// and a bare video id.
String? extractYoutubeId(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  if (_idPattern.hasMatch(text)) return text;

  final withScheme = text.contains('://') ? text : 'https://$text';
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  String? candidate;

  if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
    if (segments.isNotEmpty) candidate = segments.first;
  } else if (host.endsWith('youtube.com') ||
      host.endsWith('youtube-nocookie.com')) {
    candidate = uri.queryParameters['v'];
    if (candidate == null && segments.length >= 2) {
      const prefixes = {'embed', 'shorts', 'live', 'v'};
      if (prefixes.contains(segments.first)) candidate = segments[1];
    }
  }

  if (candidate != null && _idPattern.hasMatch(candidate)) return candidate;
  return null;
}

class VideoItem {
  const VideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.isPublished,
    required this.createdAt,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    String? text(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return VideoItem(
      id: (json['id'] as num).toInt(),
      title: text(json['title']) ?? 'Untitled',
      description: text(json['description']),
      youtubeUrl: text(json['youtube_url']) ?? '',
      isPublished: json['is_published'] != false,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal(),
    );
  }

  final int id;
  final String title;
  final String? description;
  final String youtubeUrl;
  final bool isPublished;
  final DateTime? createdAt;

  String? get videoId => extractYoutubeId(youtubeUrl);
}

class VideosRepository {
  VideosRepository._();

  static final VideosRepository instance = VideosRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Students only receive published videos (enforced by the database).
  Future<List<VideoItem>> loadVideos() async {
    final rows = await _client
        .from('videos')
        .select('id, title, description, youtube_url, is_published, created_at')
        .order('created_at', ascending: false);
    return [
      for (final row in rows)
        VideoItem.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  Future<void> save({
    VideoItem? existing,
    required String title,
    required String description,
    required String videoId,
    required bool published,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      // Always stored as a clean, standard link.
      'youtube_url': 'https://www.youtube.com/watch?v=$videoId',
      'is_published': published,
    };

    if (existing == null) {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Please log in again.');
      data['created_by'] = userId;
      await _client.from('videos').insert(data);
    } else {
      await _client.from('videos').update(data).eq('id', existing.id);
    }
  }

  Future<void> delete(int id) async {
    await _client.from('videos').delete().eq('id', id);
  }
}