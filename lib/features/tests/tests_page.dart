import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/widgets/home_widgets.dart';
import '../../core/widgets/stat_card.dart';
import 'take_test_page.dart';
import 'test_result_page.dart';
import 'tests_repository.dart';

/// Student "Tests" tab: pretest, posttest and a small results summary.
class TestsPage extends StatefulWidget {
  const TestsPage({super.key});

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> {
  late Future<TestsOverview> _future = TestsRepository.instance.loadOverview();

  Future<void> _reload() async {
    final next = TestsRepository.instance.loadOverview();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  Future<void> _start(TestKind kind) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TakeTestPage(kind: kind)),
    );
    if (mounted) _reload();
  }

  void _review(TestKind kind) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TestReviewPage(kind: kind)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tests'),
      ),
      body: FutureBuilder<TestsOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) return _content(snapshot.data!);
          if (snapshot.hasError) {
            return HomeLoadError(
              message: 'Could not load your tests.\n${friendlyError(snapshot.error!)}',
              onRetry: _reload,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _content(TestsOverview data) {
    final pre = data.attempts[TestKind.pretest];
    final post = data.attempts[TestKind.posttest];

    String scoreText(TestAttempt? a) => a == null ? '-' : formatScore(a.score);

    String improvement() {
      if (pre == null || post == null) return '-';
      final diff = post.score - pre.score;
      final text = formatScore(diff.abs());
      if (diff > 0) return '+$text';
      if (diff < 0) return '-$text';
      return '0';
    }

    final done = data.attempts.length;

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TestCard(
                    kind: TestKind.pretest,
                    icon: Icons.quiz_rounded,
                    color: AppColors.tileGreen,
                    questionCount: data.questionCounts[TestKind.pretest] ?? 0,
                    attempt: pre,
                    lockedReason: null,
                    onStart: () => _start(TestKind.pretest),
                    onReview: () => _review(TestKind.pretest),
                  ),
                  const SizedBox(height: 12),
                  _TestCard(
                    kind: TestKind.posttest,
                    icon: Icons.fact_check_rounded,
                    color: AppColors.tileBlue,
                    questionCount: data.questionCounts[TestKind.posttest] ?? 0,
                    attempt: post,
                    lockedReason:
                    pre == null ? 'Complete the pretest first.' : null,
                    onStart: () => _start(TestKind.posttest),
                    onReview: () => _review(TestKind.posttest),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'My Results'),
                  const SizedBox(height: 12),
                  StatGrid(
                    children: [
                      StatCard(
                        icon: Icons.quiz_rounded,
                        value: scoreText(pre),
                        label: 'Pretest score',
                      ),
                      StatCard(
                        icon: Icons.fact_check_rounded,
                        value: scoreText(post),
                        label: 'Posttest score',
                      ),
                      StatCard(
                        icon: Icons.trending_up_rounded,
                        value: improvement(),
                        label: 'Improvement',
                      ),
                      StatCard(
                        icon: Icons.task_alt_rounded,
                        value: '$done / 2',
                        label: 'Tests completed',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.kind,
    required this.icon,
    required this.color,
    required this.questionCount,
    required this.attempt,
    required this.lockedReason,
    required this.onStart,
    required this.onReview,
  });

  final TestKind kind;
  final IconData icon;
  final Color color;
  final int questionCount;
  final TestAttempt? attempt;
  final String? lockedReason;
  final VoidCallback onStart;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final done = attempt != null;
    final locked = lockedReason != null;
    final empty = questionCount == 0;

    String subtitle;
    if (done) {
      subtitle =
      '${attempt!.correctCount} of ${attempt!.totalQuestions} correct';
    } else if (locked) {
      subtitle = lockedReason!;
    } else if (empty) {
      subtitle = 'No questions yet.';
    } else {
      subtitle = '$questionCount questions · one attempt';
    }

    return Container(
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
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  locked ? Icons.lock_outline_rounded : icon,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (done)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.tileGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    formatScore(attempt!.score),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (done)
            OutlinedButton(
              onPressed: onReview,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: const Text('Review answers'),
            )
          else
            ElevatedButton(
              onPressed: (locked || empty) ? null : onStart,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text('Start ${kind.title}'),
            ),
        ],
      ),
    );
  }
}