import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';

/// The only place that talks to the `pdfrx` package.
/// If a new package version changes its API, only this file needs editing.
class PdfPreview extends StatelessWidget {
  const PdfPreview({super.key, required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;

  @override
  Widget build(BuildContext context) {
    return PdfViewer.data(bytes, sourceName: name);
  }
}