import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'pdf_picker.dart';

class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
    required this.isPublished,
    required this.filePath,
    required this.fileName,
    required this.createdAt,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    String? text(Object? v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return MaterialItem(
      id: (json['id'] as num).toInt(),
      title: text(json['title']) ?? 'Untitled',
      description: text(json['description']),
      content: text(json['content']),
      category: text(json['category']),
      isPublished: json['is_published'] == true,
      filePath: text(json['file_path']),
      fileName: text(json['file_name']),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal(),
    );
  }

  final int id;
  final String title;
  final String? description;
  final String? content;
  final String? category;
  final bool isPublished;
  final String? filePath;
  final String? fileName;
  final DateTime? createdAt;

  bool get hasFile => filePath != null;
}

class MaterialsRepository {
  MaterialsRepository._();

  static final MaterialsRepository instance = MaterialsRepository._();

  static const bucket = 'materials';
  static const maxPdfBytes = 20 * 1024 * 1024;
  static const _columns =
      'id, title, description, content, category, is_published, '
      'file_path, file_name, created_at';

  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Please log in again.');
    return id;
  }

  /// Students only receive published materials (enforced by the database).
  Future<List<MaterialItem>> loadMaterials() async {
    final rows = await _client
        .from('materials')
        .select(_columns)
        .order('created_at', ascending: false);
    return [
      for (final row in rows)
        MaterialItem.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  Future<Set<int>> loadCompletedIds() async {
    final rows = await _client
        .from('student_progress')
        .select('material_id')
        .eq('user_id', _userId);
    return {for (final row in rows) (row['material_id'] as num).toInt()};
  }

  Future<void> setCompleted(int materialId, bool completed) async {
    final userId = _userId;
    if (completed) {
      await _client.from('student_progress').upsert(
        {
          'user_id': userId,
          'material_id': materialId,
          'completed': true,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,material_id',
      );
    } else {
      await _client
          .from('student_progress')
          .delete()
          .eq('user_id', userId)
          .eq('material_id', materialId);
    }
  }

  Future<Uint8List> downloadBytes(String path) {
    return _client.storage.from(bucket).download(path);
  }

  Future<String> signedUrl(String path) {
    return _client.storage.from(bucket).createSignedUrl(path, 60 * 60);
  }

  /// Creates ([existing] null) or updates a material. A new PDF is uploaded
  /// first; if saving the row fails, the uploaded file is removed again.
  Future<void> save({
    MaterialItem? existing,
    required String title,
    required String description,
    required String category,
    required String content,
    required bool published,
    PickedPdf? newPdf,
    bool removeFile = false,
  }) async {
    final userId = _userId;
    String? uploadedPath;

    try {
      if (newPdf != null) {
        if (newPdf.size > maxPdfBytes) {
          throw Exception('The PDF is larger than 20 MB.');
        }
        uploadedPath = _newPath(newPdf.name);
        await _client.storage.from(bucket).uploadBinary(
          uploadedPath,
          newPdf.bytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: false,
          ),
        );
      }

      final data = <String, dynamic>{
        'title': title,
        'description': description,
        'content': content,
        'category': category.isEmpty ? null : category,
        'is_published': published,
      };

      if (newPdf != null) {
        data['file_path'] = uploadedPath;
        data['file_name'] = newPdf.name;
        data['file_type'] = 'pdf';
      } else if (removeFile) {
        data['file_path'] = null;
        data['file_name'] = null;
      }

      if (existing == null) {
        data['created_by'] = userId;
        await _client.from('materials').insert(data);
      } else {
        await _client.from('materials').update(data).eq('id', existing.id);
      }
    } catch (_) {
      if (uploadedPath != null) {
        try {
          await _client.storage.from(bucket).remove([uploadedPath]);
        } catch (_) {}
      }
      rethrow;
    }

    // The row is saved: the old file is no longer needed.
    final oldPath = existing?.filePath;
    if (oldPath != null && (newPdf != null || removeFile)) {
      try {
        await _client.storage.from(bucket).remove([oldPath]);
      } catch (_) {}
    }
  }

  Future<void> delete(MaterialItem material) async {
    await _client.from('materials').delete().eq('id', material.id);
    final path = material.filePath;
    if (path != null) {
      try {
        await _client.storage.from(bucket).remove([path]);
      } catch (_) {}
    }
  }

  static String _newPath(String originalName) {
    var name = originalName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (!name.toLowerCase().endsWith('.pdf')) name = '$name.pdf';
    return '${DateTime.now().millisecondsSinceEpoch}_$name';
  }
}