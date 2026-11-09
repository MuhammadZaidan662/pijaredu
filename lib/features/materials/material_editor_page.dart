import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../tests/tests_repository.dart' show friendlyError;
import 'materials_repository.dart';
import 'pdf_picker.dart';

/// Lecturer/Admin: create or edit a material and attach a PDF (max 20 MB).
class MaterialEditorPage extends StatefulWidget {
  const MaterialEditorPage({super.key, this.material});

  /// Null when adding a new material.
  final MaterialItem? material;

  @override
  State<MaterialEditorPage> createState() => _MaterialEditorPageState();
}

class _MaterialEditorPageState extends State<MaterialEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _contentController = TextEditingController();

  bool _published = true;
  PickedPdf? _picked;
  bool _removeExisting = false;
  bool _busy = false;

  bool get _isEditing => widget.material != null;

  @override
  void initState() {
    super.initState();
    final m = widget.material;
    if (m == null) return;
    _titleController.text = m.title;
    _descriptionController.text = m.description ?? '';
    _categoryController.text = m.category ?? '';
    _contentController.text = m.content ?? '';
    _published = m.isPublished;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _hasExistingFile =>
      widget.material?.filePath != null && !_removeExisting;

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).ceil()} KB';
  }

  Future<void> _choosePdf() async {
    try {
      final picked = await pickPdf();
      if (picked == null || !mounted) return;
      if (picked.size > MaterialsRepository.maxPdfBytes) {
        _message('That PDF is larger than 20 MB. Please choose a smaller file.');
        return;
      }
      setState(() {
        _picked = picked;
        _removeExisting = false;
      });
    } catch (e) {
      if (mounted) _message('Could not open the file picker.');
    }
  }

  void _removePdf() {
    setState(() {
      if (_picked != null) {
        _picked = null;
      } else {
        _removeExisting = true;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final hasPdf = _picked != null || _hasExistingFile;
    final content = _contentController.text.trim();
    if (!hasPdf && content.isEmpty) {
      _message('Attach a PDF or write some notes.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await MaterialsRepository.instance.save(
        existing: widget.material,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        content: content,
        published: _published,
        newPdf: _picked,
        removeFile: _removeExisting && _picked == null,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _message(friendlyError(e));
    }
  }

  Widget _pdfBlock() {
    final picked = _picked;
    final String? name = picked?.name ??
        (_hasExistingFile ? (widget.material?.fileName ?? 'Attached PDF') : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.tilePink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'No PDF attached',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: name == null
                            ? AppColors.textGrey
                            : AppColors.textDark,
                      ),
                    ),
                    if (picked != null)
                      Text(
                        _formatSize(picked.size),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                  ],
                ),
              ),
              if (name != null)
                IconButton(
                  tooltip: 'Remove PDF',
                  onPressed: _busy ? null : _removePdf,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _choosePdf,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(name == null ? 'Choose PDF' : 'Replace PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit material' : 'New material')),
      body: Form(
        key: _formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a title'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _categoryController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category, for example "SQL Basics" (optional)',
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'PDF file',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _pdfBlock(),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _contentController,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional text shown below the PDF)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _published,
                  onChanged: _busy ? null : (v) => setState(() => _published = v),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  title: const Text('Published'),
                  subtitle: const Text(
                    'Students can only see published materials.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(_isEditing ? 'Save changes' : 'Add material'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}