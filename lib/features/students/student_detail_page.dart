import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/widgets/stat_card.dart';
import '../tests/tests_repository.dart';
import 'students_repository.dart';

/// Profile and test scores of one student (for lecturers and admins).
class StudentDetailPage extends StatelessWidget {
  const StudentDetailPage({super.key, required this.student});

  final StudentResult student;

  String get _status {
    if (student.hasCompletedBoth) return 'Completed';
    if (student.hasStarted) return 'In progress';
    return 'Not started';
  }

  @override
  Widget build(BuildContext context) {
    final pre = student.pretestScore;
    final post = student.posttestScore;

    return Scaffold(
      appBar: AppBar(title: const Text('Student')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        student.initial,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      student.displayName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Student ID ${student.displayNumber}',
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.email,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              StatGrid(
                children: [
                  StatCard(
                    icon: Icons.quiz_rounded,
                    value: pre == null ? '-' : formatScore(pre),
                    label: 'Pretest score',
                  ),
                  StatCard(
                    icon: Icons.fact_check_rounded,
                    value: post == null ? '-' : formatScore(post),
                    label: 'Posttest score',
                  ),
                  StatCard(
                    icon: Icons.trending_up_rounded,
                    value: formatAverage(student.improvement, signed: true),
                    label: 'Improvement',
                  ),
                  StatCard(
                    icon: Icons.task_alt_rounded,
                    value: _status,
                    label: 'Status',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  children: [
                    _DateRow(
                      label: 'Pretest completed',
                      value: formatDate(student.pretestAt),
                    ),
                    const Divider(height: 1),
                    _DateRow(
                      label: 'Posttest completed',
                      value: formatDate(student.posttestAt),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}