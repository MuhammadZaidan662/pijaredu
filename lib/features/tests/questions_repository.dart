import 'package:supabase_flutter/supabase_flutter.dart';

import 'tests_repository.dart';

class BankOption {
  const BankOption({required this.id, required this.text});

  final int id;
  final String text;
}

class BankQuestion {
  const BankQuestion({
    required this.id,
    required this.number,
    required this.text,
    required this.options,
    required this.correctOptionId,
    required this.explanation,
  });

  final int id;
  final int number;
  final String text;
  final List<BankOption> options;
  final int? correctOptionId;
  final String? explanation;

  String? get correctText {
    for (final option in options) {
      if (option.id == correctOptionId) return option.text;
    }
    return null;
  }
}

/// One option as typed in the editor. [id] is null for a new option.
class QuestionDraftOption {
  const QuestionDraftOption({this.id, required this.text});

  final int? id;
  final String text;
}

/// Lecturer/Admin only. The database refuses these calls for students.
class QuestionsRepository {
  QuestionsRepository._();

  static final QuestionsRepository instance = QuestionsRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<BankQuestion>> loadBank(TestKind kind) async {
    final rows = await _client
        .from('questions')
        .select(
      'id, question_text, order_number, '
          'question_options(id, option_text, order_number), '
          'question_keys(option_id, explanation)',
    )
        .eq('test_type', kind.name)
        .order('order_number', ascending: true)
        .order('id', ascending: true);

    var number = 0;
    final result = <BankQuestion>[];
    for (final row in rows) {
      number++;
      result.add(_parse(Map<String, dynamic>.from(row), number));
    }
    return result;
  }

  BankQuestion _parse(Map<String, dynamic> row, int number) {
    final rawOptions = (row['question_options'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
      ..sort((a, b) {
        final byOrder = ((a['order_number'] as num?) ?? 0)
            .compareTo((b['order_number'] as num?) ?? 0);
        if (byOrder != 0) return byOrder;
        return (a['id'] as num).compareTo(b['id'] as num);
      });

    // PostgREST returns a one-to-one relation as an object or a list.
    final rawKey = row['question_keys'];
    Map<String, dynamic>? key;
    if (rawKey is List && rawKey.isNotEmpty) {
      key = Map<String, dynamic>.from(rawKey.first as Map);
    } else if (rawKey is Map) {
      key = Map<String, dynamic>.from(rawKey);
    }

    return BankQuestion(
      id: (row['id'] as num).toInt(),
      number: number,
      text: row['question_text'] as String,
      options: [
        for (final o in rawOptions)
          BankOption(
            id: (o['id'] as num).toInt(),
            text: o['option_text'] as String,
          ),
      ],
      correctOptionId: (key?['option_id'] as num?)?.toInt(),
      explanation: key?['explanation'] as String?,
    );
  }

  /// Creates a question ([id] null) or updates one. All in one database call.
  Future<void> save({
    int? id,
    required TestKind kind,
    required String text,
    required List<QuestionDraftOption> options,
    required int correctIndex,
    String? explanation,
  }) async {
    await _client.rpc(
      'save_question',
      params: {
        'p_id': id,
        'p_test': kind.name,
        'p_text': text,
        'p_options': [
          for (final o in options) {'id': o.id, 'text': o.text},
        ],
        'p_correct': correctIndex,
        'p_explanation': explanation,
      },
    );
  }

  Future<void> delete(int id) async {
    await _client.rpc('delete_question', params: {'p_id': id});
  }
}