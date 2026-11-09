import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class PickedPdf {
  const PickedPdf({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get size => bytes.length;
}

Future<PickedPdf?> pickPdf() async {
  // 1. Gunakan FilePicker.pickFile() untuk memilih 1 file (kembalian langsung PlatformFile?)
  final PlatformFile? file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );

  if (file == null) return null;

  // 2. Gunakan readAsBytes() secara asynchronous untuk mendapatkan biner file
  final Uint8List bytes = await file.readAsBytes();

  return PickedPdf(name: file.name, bytes: bytes);
}