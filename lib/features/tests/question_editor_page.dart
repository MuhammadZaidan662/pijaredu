import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'questions_repository.dart';
import 'tests_repository.dart';

/// Create or edit one multiple-choice question (2 to 4 options).
class QuestionEditorPage extends StatefulWidget {
  const QuestionEditorPage({super.key, required this.kind, this.question});

  final TestKind kind;

  /// Null when adding a new question.
  final BankQuestion? question;

  @override
  State<QuestionEditorPage> createState() => _QuestionEditorPageState();
}

class _QuestionEditorPageState extends State<QuestionEditorPage> {
  static const _slots = 4;

  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _explanationController = TextEditingController();
  final List<TextEditingController> _optionControllers =
  List.generate(_slots, (_) => TextEditingController());
  final List<int?> _optionIds = List<int?>.filled(_slots, null);

  int _correct = 0;
  bool _busy = false;

  bool get _isEditing => widget.question != null;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    if (q == null) return;

    _textController.text = q.text;
    _explanationController.text = q.explanation ?? '';
    for (var i = 0; i < q.options.length && i < _slots; i++) {
      _optionControllers[i].text = q.options[i].text;
      _optionIds[i] = q.options[i].id;
    }
    final index = q.options.indexWhere((o) => o.id == q.correctOptionId);
    _correct = (index >= 0 && index < _slots) ? index : 0;
  }

  @override
  void dispose() {
    _textController.dispose();
    _explanationController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final drafts = <QuestionDraftOption>[];
    int? correctIndex;
    for (var i = 0; i < _slots; i++) {
      final text = _optionControllers[i].text.trim();
      if (text.isEmpty) continue;
      if (i == _correct) correctIndex = drafts.length;
      drafts.add(QuestionDraftOption(id: _optionIds[i], text: text));
    }

    if (drafts.length < 2) {
      _message('Fill in at least two options.');
      return;
    }
    if (correctIndex == null) {
      _message('The correct answer cannot be an empty option.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await QuestionsRepository.instance.save(
        id: widget.question?.id,
        kind: widget.kind,
        text: _textController.text.trim(),
        options: drafts,
        correctIndex: correctIndex,
        explanation: _explanationController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _message(friendlyError(e));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this question?'),
        content: const Text('This cannot be undone.'),
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
      await QuestionsRepository.instance.delete(widget.question!.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _message(friendlyError(e));
    }
  }

  String? _requiredOption(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit question' : 'New question'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete question',
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
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
                Text(
                  '${widget.kind.title} question',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _textController,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Question'),
                  validator: _requiredOption,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Options',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap the circle to mark the correct answer. '
                      'Options A and B are required.',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < _slots; i++) ...[
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Mark option ${String.fromCharCode(65 + i)} as correct',
                        onPressed: _busy ? null : () => setState(() => _correct = i),
                        icon: Icon(
                          _correct == i
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _correct == i
                              ? AppColors.success
                              : AppColors.textGrey,
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _optionControllers[i],
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText:
                            'Option ${String.fromCharCode(65 + i)}'
                                '${i >= 2 ? ' (optional)' : ''}',
                          ),
                          validator: i < 2 ? _requiredOption : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                TextFormField(
                  controller: _explanationController,
                  minLines: 2,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Explanation (shown in the review)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
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
                      : Text(_isEditing ? 'Save changes' : 'Add question'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}