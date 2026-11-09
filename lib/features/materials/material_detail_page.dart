import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../students/students_repository.dart' show formatDate;
import '../tests/tests_repository.dart' show friendlyError;
import 'material_editor_page.dart';
import 'materials_repository.dart';
import 'pdf_viewer_page.dart';

/// One material: description, PDF (read or download) and optional notes.
/// Students can mark it as completed. Lecturers can edit or delete it.
class MaterialDetailPage extends StatefulWidget {
  const MaterialDetailPage({
    super.key,
    required this.material,
    required this.role,
  });

  final MaterialItem material;
  final String role;

  @override
  State<MaterialDetailPage> createState() => _MaterialDetailPageState();
}

class _MaterialDetailPageState extends State<MaterialDetailPage> {
  final _repo = MaterialsRepository.instance;

  bool? _completed; // null while loading (students only)
  bool _busy = false;

  bool get _isStaff => widget.role != 'student';

  @override
  void initState() {
    super.initState();
    if (!_isStaff) _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final ids = await _repo.loadCompletedIds();
      if (!mounted) return;
      setState(() => _completed = ids.contains(widget.material.id));
    } catch (_) {
      if (!mounted) return;
      setState(() => _completed = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggleCompleted() async {
    final next = !(_completed ?? false);
    setState(() => _busy = true);
    try {
      await _repo.setCompleted(widget.material.id, next);
      if (!mounted) return;
      setState(() {
        _completed = next;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _message(friendlyError(e));
    }
  }

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      final url = await _repo.signedUrl(widget.material.filePath!);
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _message('Could not open the download link.');
    } catch (e) {
      if (mounted) _message(friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialEditorPage(material: widget.material),
      ),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this material?'),
        content: const Text('The attached PDF will be deleted too.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _repo.delete(widget.material);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _message(friendlyError(e));
    }
  }

  void _openPdf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(material: widget.material),
      ),
    );
  }

  Widget _chip(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.material;
    final completed = _completed == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Material'),
        actions: [
          if (_isStaff) ...[
            IconButton(
              tooltip: 'Edit material',
              onPressed: _busy ? null : _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete material',
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  m.title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (m.category != null)
                      _chip(m.category!, AppColors.tilePurple, AppColors.primary),
                    if (_isStaff)
                      m.isPublished
                          ? _chip('Published', AppColors.tileGreen,
                          const Color(0xFF15803D))
                          : _chip('Draft', AppColors.tileYellow,
                          const Color(0xFFA16207)),
                    if (m.createdAt != null)
                      Text(
                        formatDate(m.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                  ],
                ),
                if (m.description != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    m.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      height: 1.55,
                    ),
                  ),
                ],
                if (m.hasFile) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.tilePink,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                m.fileName ?? 'Material.pdf',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _busy ? null : _openPdf,
                                icon: const Icon(Icons.menu_book_rounded),
                                label: const Text('Read PDF'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _download,
                                icon: const Icon(Icons.download_rounded),
                                label: const Text('Download'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  minimumSize: const Size.fromHeight(54),
                                  side: const BorderSide(
                                      color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.button),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (m.content != null) ...[
                  const Divider(height: 36),
                  SelectableText(
                    m.content!,
                    style: const TextStyle(fontSize: 15, height: 1.7),
                  ),
                ],
                if (!m.hasFile && m.content == null) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'This material has no content yet.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _isStaff
          ? null
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ElevatedButton.icon(
            onPressed: (_busy || _completed == null)
                ? null
                : _toggleCompleted,
            icon: Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
            ),
            label: Text(
              completed ? 'Completed (tap to undo)' : 'Mark as completed',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              completed ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}