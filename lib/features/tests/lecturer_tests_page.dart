import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/home_widgets.dart';
import '../../core/widgets/stat_card.dart';
import '../students/students_page.dart';
import '../students/students_repository.dart';
import 'question_bank_page.dart';
import 'tests_repository.dart';

class _LecturerTestsData {
  const _LecturerTestsData({required this.students, required this.counts});

  final List<StudentResult> students;
  final Map<TestKind, int> counts;
}

/// Lecturer/Admin "Tests" tab: overall results and the question banks.
class LecturerTestsPage extends StatefulWidget {
  const LecturerTestsPage({super.key});

  @override
  State<LecturerTestsPage> createState() => _LecturerTestsPageState();
}

class _LecturerTestsPageState extends State<LecturerTestsPage> {
  static const _recommendedQuestions = 20;

  late Future<_LecturerTestsData> _future = _load();

  Future<_LecturerTestsData> _load() async {
    final repo = StudentsRepository.instance;
    final students = await repo.loadStudents();
    final counts = await repo.loadQuestionCounts();
    return _LecturerTestsData(students: students, counts: counts);
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  void _openStudents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentsPage()),
    ).then((_) {
      if (mounted) _reload();
    });
  }

  void _openBank(TestKind kind) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuestionBankPage(kind: kind)),
    ).then((_) {
      if (mounted) _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tests & Results'),
      ),
      body: FutureBuilder<_LecturerTestsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) return _content(snapshot.data!);
          if (snapshot.hasError) {
            return HomeLoadError(
              message: 'Could not load the results.\n${friendlyError(snapshot.error!)}',
              onRetry: _reload,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _content(_LecturerTestsData data) {
    final summary = ResultsSummary.from(data.students);

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
                  const SectionHeader(title: 'Overall results'),
                  const SizedBox(height: 12),
                  StatGrid(
                    children: [
                      StatCard(
                        icon: Icons.quiz_rounded,
                        value: formatAverage(summary.averagePretest),
                        label: 'Avg pretest',
                      ),
                      StatCard(
                        icon: Icons.fact_check_rounded,
                        value: formatAverage(summary.averagePosttest),
                        label: 'Avg posttest',
                      ),
                      StatCard(
                        icon: Icons.trending_up_rounded,
                        value: formatAverage(
                          summary.averageImprovement,
                          signed: true,
                        ),
                        label: 'Avg improvement',
                      ),
                      StatCard(
                        icon: Icons.groups_rounded,
                        value:
                        '${summary.posttestDone} / ${summary.studentCount}',
                        label: 'Finished both',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openStudents,
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('View student results'),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Question banks'),
                  const SizedBox(height: 12),
                  _BankCard(
                    kind: TestKind.pretest,
                    icon: Icons.quiz_rounded,
                    color: AppColors.tileGreen,
                    count: data.counts[TestKind.pretest] ?? 0,
                    recommended: _recommendedQuestions,
                    onManage: () => _openBank(TestKind.pretest),
                  ),
                  const SizedBox(height: 12),
                  _BankCard(
                    kind: TestKind.posttest,
                    icon: Icons.fact_check_rounded,
                    color: AppColors.tileBlue,
                    count: data.counts[TestKind.posttest] ?? 0,
                    recommended: _recommendedQuestions,
                    onManage: () => _openBank(TestKind.posttest),
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

class _BankCard extends StatelessWidget {
  const _BankCard({
    required this.kind,
    required this.icon,
    required this.color,
    required this.count,
    required this.recommended,
    required this.onManage,
  });

  final TestKind kind;
  final IconData icon;
  final Color color;
  final int count;
  final int recommended;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final enough = count >= recommended;

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
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${kind.title} questions',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$count ${count == 1 ? 'question' : 'questions'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: enough ? AppColors.tileGreen : AppColors.tileYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  enough ? 'Ready' : 'Need $recommended+',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: enough
                        ? const Color(0xFF15803D)
                        : const Color(0xFFA16207),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onManage,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: const Text('Manage questions'),
          ),
        ],
      ),
    );
  }
}