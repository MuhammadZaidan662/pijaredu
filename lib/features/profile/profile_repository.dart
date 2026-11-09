import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository._();

  static final ProfileRepository instance = ProfileRepository._();

  static const _bucket = 'avatars';
  static const maxPhotoBytes = 2 * 1024 * 1024;

  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Please log in again.');
    return id;
  }

  /// A user can only change these columns (the role is protected by the
  /// database): full_name, student_number and avatar_url.
  Future<void> updateProfile({
    required String fullName,
    String? studentNumber,
  }) async {
    final data = <String, dynamic>{'full_name': fullName};
    if (studentNumber != null) {
      data['student_number'] = studentNumber.isEmpty ? null : studentNumber;
    }
    await _client.from('profiles').update(data).eq('id', _userId);
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Uploads a new photo, saves its public link and deletes older photos.
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String extension,
  }) async {
    if (bytes.length > maxPhotoBytes) {
      throw Exception('The photo is larger than 2 MB.');
    }

    final userId = _userId;
    final ext = (extension == 'png' || extension == 'webp') ? extension : 'jpg';
    final contentType = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
        ? 'image/webp'
        : 'image/jpeg';

    final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from(_bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );

    final url = _client.storage.from(_bucket).getPublicUrl(path);
    await _client.from('profiles').update({'avatar_url': url}).eq('id', userId);
    await _removeOldAvatars(userId, keep: path);
    return url;
  }

  Future<void> removeAvatar() async {
    final userId = _userId;
    await _client.from('profiles').update({'avatar_url': null}).eq('id', userId);
    await _removeOldAvatars(userId);
  }

  Future<void> _removeOldAvatars(String userId, {String? keep}) async {
    try {
      final files = await _client.storage.from(_bucket).list(path: userId);
      final paths = [
        for (final file in files) '$userId/${file.name}',
      ].where((path) => path != keep).toList();
      if (paths.isNotEmpty) {
        await _client.storage.from(_bucket).remove(paths);
      }
    } catch (_) {
      // Old photos are only clutter: failing to delete them is not an error.
    }
  }
}