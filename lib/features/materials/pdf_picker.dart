import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A PDF the lecturer chose on the phone.
class PickedPdf {
  const PickedPdf({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get size => bytes.length;
}

/// The only place that talks to the `file_picker` package.
/// If a new package version changes its API, only this file needs editing.
Future<PickedPdf?> pickPdf() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) return null;

  return PickedPdf(name: file.name, bytes: bytes);
}