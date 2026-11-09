import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

enum PhotoSource { gallery, camera }

class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.extension});

  final Uint8List bytes;
  final String extension;
}

/// The only place that talks to the `image_picker` package.
/// The photo is shrunk to at most 600 x 600 pixels so it stays small.
Future<PickedPhoto?> pickPhoto(PhotoSource source) async {
  final file = await ImagePicker().pickImage(
    source: source == PhotoSource.camera
        ? ImageSource.camera
        : ImageSource.gallery,
    maxWidth: 600,
    maxHeight: 600,
    imageQuality: 85,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  final name = file.name;
  final dot = name.lastIndexOf('.');
  final extension = dot >= 0 ? name.substring(dot + 1).toLowerCase() : 'jpg';

  return PickedPhoto(bytes: bytes, extension: extension);
}