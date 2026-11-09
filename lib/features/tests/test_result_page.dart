import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/widgets/home_widgets.dart';
import 'tests_repository.dart';

/// Shown right after a test is submitted.
class TestResultPage extends StatelessWidget {
  const TestResultPage({super.key, required this.attempt});

  final TestAttempt attempt;

  String get _message {
    if (attempt.score >= 85) return 'Excellent work!';
    if (attempt.score >= 70) return 'Good job!';
    if (attempt.score >= 50) return 'Keep practicing.';
    return 'Review the materials and try the SQL practice.';
  }

  @override
  Widget build(BuildContext context) {
    final kind = attempt.kind;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('${kind.title} result'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SizedBox(
                      width: 168,
                      height: 168,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 168,
                            height: 168,
                            child: CircularProgressIndicator(
                              value: (attempt.score / 100).clamp(0.0, 1.0),
                              strokeWidth: 12,
                              strokeCap: StrokeCap.round,
                              backgroundColor: AppColors.tilePurple,
                              color: AppColors.primary,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatScore(attempt.score),
                                style: GoogleFonts.poppins(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  height: 1.1,
                                ),
                              ),
                              const Text(
                                'out of 100',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${attempt.correctCount} of ${attempt.totalQuestions} answers correct',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TestReviewPage(kind: kind),
                      ),
                    ),
                    child: const Text('Review answers'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: const Text('Back to Tests'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lists every question with the student's answer, the correct answer and
/// the explanation. Available only after the test has been submitted.
class TestReviewPage extends StatefulWidget {
  const TestReviewPage({super.key, required this.kind});

  final TestKind kind;

  @override
  State<TestReviewPage> createState() => _TestReviewPageState();
}

class _TestReviewPageState extends State<TestReviewPage> {
  late Future<List<ReviewItem>> _future =
  TestsRepository.instance.loadReview(widget.kind);

  void _retry() {
    setState(() => _future = TestsRepository.instance.loadReview(widget.kind));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.kind.title} review')),
      body: FutureBuilder<List<ReviewItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return HomeLoadError(
              message: 'Could not load the review.\n${friendlyError(snapshot.error!)}',
              onRetry: _retry,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Nothing to review yet.',
                style: TextStyle(color: AppColors.textGrey),
              ),
            );
          }
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ReviewCard(item: items[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item});

  final ReviewItem item;

  @override
  Widget build(BuildContext context) {
    final correct = item.isCorrect;
    final accent = correct ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 20,
                color: accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Question ${item.number}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.questionText,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _AnswerLine(
            label: 'Your answer',
            value: item.selectedText ?? 'Not answered',
            color: correct ? AppColors.success : AppColors.danger,
          ),
          if (!correct && item.correctText != null) ...[
            const SizedBox(height: 6),
            _AnswerLine(
              label: 'Correct answer',
              value: item.correctText!,
              color: AppColors.success,
            ),
          ],
          if ((item.explanation ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.explanation!,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textGrey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textGrey),
          ),
          TextSpan(
            text: value,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 13.5, height: 1.4),
    );
  }
}