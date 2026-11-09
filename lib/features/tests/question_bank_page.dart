import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/widgets/home_widgets.dart';
import 'question_editor_page.dart';
import 'questions_repository.dart';
import 'tests_repository.dart';

/// Lecturer/Admin: all questions of one test, with add and edit.
class QuestionBankPage extends StatefulWidget {
  const QuestionBankPage({super.key, required this.kind});

  final TestKind kind;

  @override
  State<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends State<QuestionBankPage> {
  static const _recommended = 20;

  late Future<List<BankQuestion>> _future =
  QuestionsRepository.instance.loadBank(widget.kind);

  Future<void> _reload() async {
    final next = QuestionsRepository.instance.loadBank(widget.kind);
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  Future<void> _openEditor([BankQuestion? question]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionEditorPage(kind: widget.kind, question: question),
      ),
    );
    if (changed == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.kind.title} questions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add question'),
      ),
      body: FutureBuilder<List<BankQuestion>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) return _content(snapshot.data!);
          if (snapshot.hasError) {
            return HomeLoadError(
              message:
              'Could not load the questions.\n${friendlyError(snapshot.error!)}',
              onRetry: _reload,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _content(List<BankQuestion> questions) {
    final count = questions.length;
    final ready = count >= _recommended;

    return RefreshIndicator(
      onRefresh: _reload,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count of $_recommended questions',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (count / _recommended).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppColors.tilePurple,
                        color: ready ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ready
                          ? 'The question bank is ready.'
                          : 'Add ${_recommended - count} more to reach the recommended $_recommended.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (questions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No questions yet. Tap "Add question".',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ),
                )
              else
                for (final question in questions) ...[
                  _QuestionTile(
                    question: question,
                    onTap: () => _openEditor(question),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question, required this.onTap});

  final BankQuestion question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final answer = question.correctText;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tilePurple,
                ),
                child: Text(
                  '${question.number}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      answer == null ? 'No correct answer set' : 'Answer: $answer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: answer == null
                            ? AppColors.danger
                            : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }
}