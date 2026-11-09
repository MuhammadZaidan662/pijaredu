import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/widgets/home_widgets.dart';
import 'test_result_page.dart';
import 'tests_repository.dart';

/// Shows one question at a time. The score is calculated by the database.
class TakeTestPage extends StatefulWidget {
  const TakeTestPage({super.key, required this.kind});

  final TestKind kind;

  @override
  State<TakeTestPage> createState() => _TakeTestPageState();
}

class _TakeTestPageState extends State<TakeTestPage> {
  final _repo = TestsRepository.instance;

  List<TestQuestion>? _questions;
  String? _error;
  int _index = 0;
  final Map<int, int> _answers = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _questions = null;
      _error = null;
    });
    try {
      final questions = await _repo.loadQuestions(widget.kind);
      if (!mounted) return;
      setState(() => _questions = questions);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    }
  }

  Future<bool> _confirmExit() async {
    if (_answers.isEmpty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this test?'),
        content: const Text('Your answers have not been submitted and will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave == true;
  }

  Future<void> _submit() async {
    final questions = _questions!;
    final unanswered = questions.length - _answers.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Submit ${widget.kind.title}?'),
        content: Text(
          unanswered > 0
              ? 'You have $unanswered unanswered '
              '${unanswered == 1 ? 'question' : 'questions'}. '
              'You cannot retake this test after submitting.'
              : 'You cannot retake this test after submitting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Review'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final attempt = await _repo.submit(widget.kind, _answers);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TestResultPage(attempt: attempt)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _submitting) return;
        final leave = await _confirmExit();
        if (leave && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.kind.title),
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: _submitting
                ? null
                : () async {
              final leave = await _confirmExit();
              if (leave && context.mounted) Navigator.pop(context);
            },
          ),
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return HomeLoadError(
        message: 'Could not load the questions.\n$_error',
        onRetry: _load,
      );
    }

    final questions = _questions;
    if (questions == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (questions.isEmpty) {
      return const Center(
        child: Text(
          'This test has no questions yet.',
          style: TextStyle(color: AppColors.textGrey),
        ),
      );
    }

    final question = questions[_index];
    final isLast = _index == questions.length - 1;
    final selected = _answers[question.id];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${_index + 1} of ${questions.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_index + 1) / questions.length,
                  minHeight: 8,
                  backgroundColor: AppColors.tilePurple,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question.text,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < question.options.length; i++) ...[
                      _OptionTile(
                        letter: String.fromCharCode(65 + i),
                        text: question.options[i].text,
                        selected: selected == question.options[i].id,
                        onTap: () => setState(
                              () => _answers[question.id] = question.options[i].id,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_index == 0 || _submitting)
                        ? null
                        : () => setState(() => _index--),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(color: AppColors.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : (isLast ? _submit : () => setState(() => _index++)),
                    child: _submitting
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : Text(isLast ? 'Submit' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.tilePurple : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : AppColors.background,
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 14.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}