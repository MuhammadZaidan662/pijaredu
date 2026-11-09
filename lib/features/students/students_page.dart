import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/widgets/home_widgets.dart';
import '../tests/tests_repository.dart';
import 'student_detail_page.dart';
import 'students_repository.dart';

enum _Filter {
  all('All'),
  notStarted('Not started'),
  pretestOnly('Pretest only'),
  completed('Completed');

  const _Filter(this.label);

  final String label;

  bool matches(StudentResult s) {
    switch (this) {
      case _Filter.all:
        return true;
      case _Filter.notStarted:
        return !s.hasStarted;
      case _Filter.pretestOnly:
        return s.hasStarted && !s.hasCompletedBoth;
      case _Filter.completed:
        return s.hasCompletedBoth;
    }
  }
}

/// Lecturer/Admin: all students with their pretest and posttest scores.
class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  late Future<List<StudentResult>> _future =
  StudentsRepository.instance.loadStudents();
  final _searchController = TextEditingController();

  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final next = StudentsRepository.instance.loadStudents();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  List<StudentResult> _visible(List<StudentResult> all) {
    final query = _query.trim().toLowerCase();
    return [
      for (final s in all)
        if (_filter.matches(s) &&
            (query.isEmpty ||
                s.displayName.toLowerCase().contains(query) ||
                s.displayNumber.contains(query) ||
                s.email.toLowerCase().contains(query)))
          s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: FutureBuilder<List<StudentResult>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) return _content(snapshot.data!);
          if (snapshot.hasError) {
            return HomeLoadError(
              message:
              'Could not load the students.\n${friendlyError(snapshot.error!)}',
              onRetry: _reload,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _content(List<StudentResult> all) {
    final summary = ResultsSummary.from(all);
    final visible = _visible(all);

    return RefreshIndicator(
      onRefresh: _reload,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Row(
                children: [
                  _MiniStat(
                    value: '${summary.studentCount}',
                    label: 'Students',
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    value: formatAverage(summary.averagePretest),
                    label: 'Avg pretest',
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    value: formatAverage(summary.averagePosttest),
                    label: 'Avg posttest',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search students',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in _Filter.values) ...[
                      ChoiceChip(
                        label: Text(filter.label),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                        selectedColor: AppColors.tilePurple,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _filter == filter
                              ? AppColors.primary
                              : AppColors.outline,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _filter == filter
                              ? AppColors.primary
                              : AppColors.textGrey,
                        ),
                        showCheckmark: false,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${visible.length} of ${all.length} students',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No students match.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ),
                )
              else
                for (final student in visible) ...[
                  _StudentTile(
                    student: student,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailPage(student: student),
                      ),
                    ),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});

  final StudentResult student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.tilePurple,
                child: Text(
                  student.initial,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
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
                      student.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.displayNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ScorePill(label: 'Pre', score: student.pretestScore),
                  const SizedBox(height: 4),
                  _ScorePill(label: 'Post', score: student.posttestScore),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.label, required this.score});

  final String label;
  final double? score;

  @override
  Widget build(BuildContext context) {
    final done = score != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: done ? AppColors.tileGreen : AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label ${done ? formatScore(score!) : '-'}',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: done ? const Color(0xFF15803D) : AppColors.textGrey,
        ),
      ),
    );
  }
}