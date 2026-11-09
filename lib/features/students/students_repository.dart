import 'package:supabase_flutter/supabase_flutter.dart';

import '../tests/tests_repository.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime? date) {
  if (date == null) return '-';
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

class StudentResult {
  const StudentResult({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.studentNumber,
    required this.pretestScore,
    required this.posttestScore,
    required this.pretestAt,
    required this.posttestAt,
  });

  factory StudentResult.fromJson(Map<String, dynamic> json) {
    DateTime? date(Object? raw) =>
        raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

    return StudentResult(
      userId: json['user_id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      studentNumber: json['student_number'] as String?,
      pretestScore: (json['pretest_score'] as num?)?.toDouble(),
      posttestScore: (json['posttest_score'] as num?)?.toDouble(),
      pretestAt: date(json['pretest_at']),
      posttestAt: date(json['posttest_at']),
    );
  }

  final String userId;
  final String fullName;
  final String email;
  final String? studentNumber;
  final double? pretestScore;
  final double? posttestScore;
  final DateTime? pretestAt;
  final DateTime? posttestAt;

  String get displayName {
    final name = fullName.trim();
    if (name.isNotEmpty) return name;
    return email.contains('@') ? email.split('@').first : email;
  }

  /// Uses the student number when it exists. Otherwise, if the email starts
  /// with digits only (like 25050974012@...), that number is shown.
  String get displayNumber {
    final number = studentNumber?.trim() ?? '';
    if (number.isNotEmpty) return number;
    final local = email.split('@').first;
    return RegExp(r'^\d+$').hasMatch(local) ? local : '-';
  }

  String get initial =>
      displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase();

  double? get improvement {
    final pre = pretestScore;
    final post = posttestScore;
    if (pre == null || post == null) return null;
    return post - pre;
  }

  bool get hasStarted => pretestScore != null;
  bool get hasCompletedBoth => pretestScore != null && posttestScore != null;
}

class ResultsSummary {
  const ResultsSummary({
    required this.studentCount,
    required this.pretestDone,
    required this.posttestDone,
    required this.averagePretest,
    required this.averagePosttest,
    required this.averageImprovement,
  });

  factory ResultsSummary.from(List<StudentResult> students) {
    double? average(Iterable<double> values) {
      final list = values.toList();
      if (list.isEmpty) return null;
      return list.reduce((a, b) => a + b) / list.length;
    }

    return ResultsSummary(
      studentCount: students.length,
      pretestDone: students.where((s) => s.pretestScore != null).length,
      posttestDone: students.where((s) => s.posttestScore != null).length,
      averagePretest: average([
        for (final s in students)
          if (s.pretestScore != null) s.pretestScore!,
      ]),
      averagePosttest: average([
        for (final s in students)
          if (s.posttestScore != null) s.posttestScore!,
      ]),
      averageImprovement: average([
        for (final s in students)
          if (s.improvement != null) s.improvement!,
      ]),
    );
  }

  final int studentCount;
  final int pretestDone;
  final int posttestDone;
  final double? averagePretest;
  final double? averagePosttest;
  final double? averageImprovement;
}

String formatAverage(double? value, {bool signed = false}) {
  if (value == null) return '-';
  final text = formatScore(value.abs());
  if (!signed) return formatScore(value);
  if (value > 0) return '+$text';
  if (value < 0) return '-$text';
  return '0';
}

class StudentsRepository {
  StudentsRepository._();

  static final StudentsRepository instance = StudentsRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  /// One row per student with both scores. Only lecturers and admins can see
  /// every student (the database enforces this).
  Future<List<StudentResult>> loadStudents() async {
    final rows = await _client
        .from('student_results')
        .select()
        .order('full_name', ascending: true);
    return [
      for (final row in rows)
        StudentResult.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  Future<Map<TestKind, int>> loadQuestionCounts() async {
    final rows = await _client.from('questions').select('test_type');
    final counts = {for (final kind in TestKind.values) kind: 0};
    for (final row in rows) {
      final kind = TestKind.values.byName(row['test_type'] as String);
      counts[kind] = (counts[kind] ?? 0) + 1;
    }
    return counts;
  }
}