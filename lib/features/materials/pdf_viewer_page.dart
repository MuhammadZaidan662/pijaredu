import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/home_widgets.dart';
import '../tests/tests_repository.dart';
import 'materials_repository.dart';
import 'pdf_preview.dart';

/// Full-screen reader for a material's PDF.
class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({super.key, required this.material});

  final MaterialItem material;

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late Future<Uint8List> _future = _load();

  Future<Uint8List> _load() {
    return MaterialsRepository.instance.downloadBytes(widget.material.filePath!);
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.material.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return HomeLoadError(
              message: 'Could not open the PDF.\n${friendlyError(snapshot.error!)}',
              onRetry: _retry,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return PdfPreview(
            bytes: snapshot.data!,
            name: widget.material.fileName ?? 'material.pdf',
          );
        },
      ),
    );
  }
}