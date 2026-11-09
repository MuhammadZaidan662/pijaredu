import 'package:supabase_flutter/supabase_flutter.dart';

enum TestKind {
  pretest,
  posttest;

  String get title => this == TestKind.pretest ? 'Pretest' : 'Posttest';
}

class TestOption {
  const TestOption({required this.id, required this.text});

  final int id;
  final String text;
}

class TestQuestion {
  const TestQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  final int id;
  final String text;
  final List<TestOption> options;
}

class TestAttempt {
  const TestAttempt({
    required this.id,
    required this.kind,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
  });

  factory TestAttempt.fromJson(Map<String, dynamic> json) {
    return TestAttempt(
      id: (json['id'] as num).toInt(),
      kind: TestKind.values.byName(json['test_type'] as String),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final TestKind kind;
  final double score;
  final int correctCount;
  final int totalQuestions;
}

class ReviewItem {
  const ReviewItem({
    required this.number,
    required this.questionText,
    required this.selectedText,
    required this.correctText,
    required this.isCorrect,
    required this.explanation,
  });

  final int number;
  final String questionText;
  final String? selectedText;
  final String? correctText;
  final bool isCorrect;
  final String? explanation;
}

class TestsOverview {
  const TestsOverview({required this.attempts, required this.questionCounts});

  final Map<TestKind, TestAttempt> attempts;
  final Map<TestKind, int> questionCounts;
}

/// Formats 85.0 as "85" and 82.5 as "82.5".
String formatScore(double score) {
  return score.toStringAsFixed(score % 1 == 0 ? 0 : 1);
}

String friendlyError(Object error) {
  if (error is PostgrestException) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}

class TestsRepository {
  TestsRepository._();

  static final TestsRepository instance = TestsRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<TestsOverview> loadOverview() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Please log in again.');
    }

    final attemptRows =
    await _client.from('test_attempts').select().eq('user_id', userId);
    final questionRows = await _client.from('questions').select('test_type');

    final attempts = <TestKind, TestAttempt>{};
    for (final row in attemptRows) {
      if (row['completed_at'] == null) continue;
      final attempt = TestAttempt.fromJson(Map<String, dynamic>.from(row));
      attempts[attempt.kind] = attempt;
    }

    final counts = {for (final kind in TestKind.values) kind: 0};
    for (final row in questionRows) {
      final kind = TestKind.values.byName(row['test_type'] as String);
      counts[kind] = (counts[kind] ?? 0) + 1;
    }

    return TestsOverview(attempts: attempts, questionCounts: counts);
  }

  Future<List<TestQuestion>> loadQuestions(TestKind kind) async {
    final rows = await _client
        .from('questions')
        .select(
      'id, question_text, order_number, '
          'question_options(id, option_text, order_number)',
    )
        .eq('test_type', kind.name)
        .order('order_number', ascending: true)
        .order('id', ascending: true);

    return [
      for (final row in rows)
        TestQuestion(
          id: (row['id'] as num).toInt(),
          text: row['question_text'] as String,
          options: _parseOptions(row['question_options']),
        ),
    ];
  }

  List<TestOption> _parseOptions(Object? raw) {
    final list = List<Map<String, dynamic>>.from(
      (raw as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    list.sort((a, b) {
      final byOrder = ((a['order_number'] as num?) ?? 0)
          .compareTo((b['order_number'] as num?) ?? 0);
      if (byOrder != 0) return byOrder;
      return (a['id'] as num).compareTo(b['id'] as num);
    });
    return [
      for (final o in list)
        TestOption(
          id: (o['id'] as num).toInt(),
          text: o['option_text'] as String,
        ),
    ];
  }

  /// [answers] maps question id to the chosen option id.
  /// The score is calculated by the database, not by the app.
  Future<TestAttempt> submit(TestKind kind, Map<int, int> answers) async {
    final data = await _client.rpc(
      'submit_test',
      params: {
        'p_test': kind.name,
        'p_answers': [
          for (final entry in answers.entries)
            {'question_id': entry.key, 'option_id': entry.value},
        ],
      },
    );
    return TestAttempt.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<ReviewItem>> loadReview(TestKind kind) async {
    final data = await _client.rpc('get_my_review', params: {'p_test': kind.name});

    final items = <ReviewItem>[];
    var number = 0;
    for (final raw in data as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      number++;
      items.add(
        ReviewItem(
          number: number,
          questionText: row['question_text'] as String,
          selectedText: row['selected_text'] as String?,
          correctText: row['correct_text'] as String?,
          isCorrect: row['is_correct'] == true,
          explanation: row['explanation'] as String?,
        ),
      );
    }
    return items;
  }
}