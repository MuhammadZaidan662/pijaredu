import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Result of running a script in the playground.
class QueryResult {
  const QueryResult({
    this.columns = const [],
    this.rows = const [],
    this.totalRows = 0,
    this.message,
    this.error,
    this.elapsed = Duration.zero,
    this.statementCount = 1,
    this.truncated = false,
  });

  final List<String> columns;
  final List<List<Object?>> rows;
  final int totalRows;
  final String? message;
  final String? error;
  final Duration elapsed;
  final int statementCount;
  final bool truncated;

  bool get isError => error != null;
  bool get hasTable => columns.isNotEmpty;

  QueryResult copyWith({Duration? elapsed, int? statementCount}) {
    return QueryResult(
      columns: columns,
      rows: rows,
      totalRows: totalRows,
      message: message,
      error: error,
      elapsed: elapsed ?? this.elapsed,
      statementCount: statementCount ?? this.statementCount,
      truncated: truncated,
    );
  }
}

class ColumnInfo {
  const ColumnInfo({
    required this.name,
    required this.type,
    required this.isPrimaryKey,
  });

  final String name;
  final String type;
  final bool isPrimaryKey;
}

class TableInfo {
  const TableInfo(this.name, this.columns);

  final String name;
  final List<ColumnInfo> columns;
}

class PlaygroundException implements Exception {
  const PlaygroundException(this.message);

  final String message;
}

/// Local SQLite sandbox for the SQL Playground.
/// It never touches the Supabase database.
class SqlDatabase {
  SqlDatabase._();

  static final SqlDatabase instance = SqlDatabase._();

  static const _fileName = 'sql_playground.db';
  static const _maxRows = 200;
  static const _timeout = Duration(seconds: 10);

  static const _readKeywords = {'SELECT', 'WITH', 'PRAGMA', 'EXPLAIN', 'VALUES'};
  static const _writeKeywords = {'INSERT', 'UPDATE', 'DELETE', 'REPLACE'};
  static const _blockedKeywords = {
    'ATTACH',
    'DETACH',
    'VACUUM',
    'BEGIN',
    'COMMIT',
    'ROLLBACK',
    'SAVEPOINT',
    'RELEASE',
  };

  Database? _db;

  Future<Database> _open() async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;

    final path = p.join(await getDatabasesPath(), _fileName);
    final db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        for (final statement in _seedStatements) {
          await db.execute(statement);
        }
      },
    );
    _db = db;
    return db;
  }

  /// Opens the database (and fills it with sample data the first time).
  Future<void> ensureReady() async {
    await _open();
  }

  /// Deletes the database and recreates the sample data.
  Future<void> reset() async {
    final existing = _db;
    if (existing != null && existing.isOpen) {
      await existing.close();
    }
    _db = null;
    final path = p.join(await getDatabasesPath(), _fileName);
    await deleteDatabase(path);
    await _open();
  }

  Future<List<TableInfo>> loadSchema() async {
    final db = await _open();
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata' "
          'ORDER BY name',
    );

    final result = <TableInfo>[];
    for (final table in tables) {
      final name = table['name'] as String;
      final columns = await db.rawQuery('PRAGMA table_info("$name")');
      result.add(
        TableInfo(name, [
          for (final c in columns)
            ColumnInfo(
              name: c['name'] as String,
              type: (c['type'] as String?) ?? '',
              isPrimaryKey: ((c['pk'] as int?) ?? 0) > 0,
            ),
        ]),
      );
    }
    return result;
  }

  /// Runs one or more statements separated by `;`.
  /// Shows the result of the last statement.
  Future<QueryResult> run(String script) async {
    final stopwatch = Stopwatch()..start();
    final statements = splitStatements(script);

    if (statements.isEmpty) {
      return const QueryResult(error: 'Nothing to run. Type a query first.');
    }

    final Database db;
    try {
      db = await _open();
    } catch (e) {
      return QueryResult(error: 'Could not open the database: ${_cleanError(e)}');
    }

    QueryResult? last;
    for (var i = 0; i < statements.length; i++) {
      try {
        last = await _runOne(db, statements[i]).timeout(_timeout);
      } on TimeoutException {
        return QueryResult(
          error: 'Statement ${i + 1} took too long. '
              'Try a smaller query, or reset the database.',
          elapsed: stopwatch.elapsed,
        );
      } catch (e) {
        final prefix = statements.length > 1 ? 'Statement ${i + 1}: ' : '';
        return QueryResult(
          error: '$prefix${_cleanError(e)}',
          elapsed: stopwatch.elapsed,
        );
      }
    }

    return last!.copyWith(
      elapsed: stopwatch.elapsed,
      statementCount: statements.length,
    );
  }

  Future<QueryResult> _runOne(Database db, String sql) async {
    final keyword = _firstWord(sql);

    if (_blockedKeywords.contains(keyword)) {
      throw PlaygroundException('$keyword is not available in the playground.');
    }

    if (_readKeywords.contains(keyword)) {
      final rows = await db.rawQuery(sql);
      if (rows.isEmpty) {
        return const QueryResult(message: 'The query returned 0 rows.');
      }
      final columns = rows.first.keys.toList();
      return QueryResult(
        columns: columns,
        rows: [
          for (final row in rows.take(_maxRows))
            [for (final c in columns) row[c]],
        ],
        totalRows: rows.length,
        truncated: rows.length > _maxRows,
      );
    }

    if (_writeKeywords.contains(keyword)) {
      final changes = await db.rawUpdate(sql);
      return QueryResult(
        message: '$changes ${changes == 1 ? 'row' : 'rows'} affected.',
      );
    }

    await db.execute(sql);
    return const QueryResult(message: 'Statement executed successfully.');
  }

  static String _firstWord(String sql) {
    final match = RegExp(r'^[A-Za-z]+').firstMatch(sql.trimLeft());
    return match?.group(0)?.toUpperCase() ?? '';
  }

  /// Splits a script on `;`, ignoring `;` inside quotes and comments.
  static List<String> splitStatements(String script) {
    final statements = <String>[];
    final buffer = StringBuffer();
    String? quote;
    var i = 0;

    void flush() {
      final text = buffer.toString().trim();
      if (text.isNotEmpty) statements.add(text);
      buffer.clear();
    }

    while (i < script.length) {
      final ch = script[i];
      final next = i + 1 < script.length ? script[i + 1] : '';

      if (quote != null) {
        buffer.write(ch);
        if (ch == quote) {
          if (next == quote) {
            buffer.write(next);
            i += 2;
            continue;
          }
          quote = null;
        }
        i++;
        continue;
      }

      if (ch == "'" || ch == '"') {
        quote = ch;
        buffer.write(ch);
        i++;
        continue;
      }

      if (ch == '-' && next == '-') {
        while (i < script.length && script[i] != '\n') {
          i++;
        }
        continue;
      }

      if (ch == '/' && next == '*') {
        i += 2;
        while (i < script.length &&
            !(script[i] == '*' && i + 1 < script.length && script[i + 1] == '/')) {
          i++;
        }
        i += 2;
        continue;
      }

      if (ch == ';') {
        flush();
        i++;
        continue;
      }

      buffer.write(ch);
      i++;
    }

    flush();
    return statements;
  }

  static String _cleanError(Object e) {
    if (e is PlaygroundException) return e.message;

    var text = e.toString();
    text = text.replaceFirst(RegExp(r'^DatabaseException\('), '');
    for (final marker in [', while compiling', ' sql ']) {
      final index = text.indexOf(marker);
      if (index > 0) text = text.substring(0, index);
    }
    text = text.replaceAll(RegExp(r'\)\s*$'), '');
    return text.trim();
  }

  static const _seedStatements = <String>[
    'CREATE TABLE lecturers ('
        'id INTEGER PRIMARY KEY, '
        'name TEXT NOT NULL, '
        'department TEXT NOT NULL)',
    'CREATE TABLE courses ('
        'id INTEGER PRIMARY KEY, '
        'code TEXT NOT NULL UNIQUE, '
        'title TEXT NOT NULL, '
        'credits INTEGER NOT NULL, '
        'lecturer_id INTEGER, '
        'FOREIGN KEY (lecturer_id) REFERENCES lecturers(id))',
    'CREATE TABLE students ('
        'id INTEGER PRIMARY KEY, '
        'name TEXT NOT NULL, '
        'email TEXT UNIQUE, '
        'major TEXT, '
        'gpa REAL, '
        'enrolled_year INTEGER)',
    'CREATE TABLE enrollments ('
        'id INTEGER PRIMARY KEY, '
        'student_id INTEGER NOT NULL, '
        'course_id INTEGER NOT NULL, '
        'grade INTEGER, '
        'FOREIGN KEY (student_id) REFERENCES students(id), '
        'FOREIGN KEY (course_id) REFERENCES courses(id))',
    "INSERT INTO lecturers (id, name, department) VALUES "
        "(1, 'Dr. Budi Santoso', 'Information Systems'), "
        "(2, 'Dr. Rina Wijaya', 'Computer Science'), "
        "(3, 'Prof. Hendra Kusuma', 'Information Systems'), "
        "(4, 'Dr. Sari Lestari', 'Data Science')",
    "INSERT INTO courses (id, code, title, credits, lecturer_id) VALUES "
        "(1, 'DB101', 'Database Systems', 3, 1), "
        "(2, 'DB201', 'Advanced SQL', 3, 1), "
        "(3, 'CS101', 'Programming Fundamentals', 4, 2), "
        "(4, 'IS201', 'Systems Analysis', 3, 3), "
        "(5, 'DS101', 'Data Analysis', 3, 4), "
        "(6, 'CS202', 'Data Structures', 4, 2)",
    "INSERT INTO students (id, name, email, major, gpa, enrolled_year) VALUES "
        "(1, 'Alya Putri', 'alya@campus.edu', 'Information Systems', 3.85, 2023), "
        "(2, 'Budi Pratama', 'budi@campus.edu', 'Computer Science', 3.40, 2022), "
        "(3, 'Citra Dewi', 'citra@campus.edu', 'Information Systems', 3.65, 2023), "
        "(4, 'Dimas Saputra', 'dimas@campus.edu', 'Data Science', 3.10, 2024), "
        "(5, 'Eka Rahma', 'eka@campus.edu', 'Computer Science', 3.75, 2022), "
        "(6, 'Fajar Nugroho', 'fajar@campus.edu', 'Information Systems', 2.95, 2024), "
        "(7, 'Gita Maharani', 'gita@campus.edu', 'Data Science', 3.55, 2023), "
        "(8, 'Hadi Firmansyah', 'hadi@campus.edu', 'Computer Science', 3.20, 2024)",
    'INSERT INTO enrollments (student_id, course_id, grade) VALUES '
        '(1, 1, 92), (1, 2, 88), (1, 4, 90), '
        '(2, 1, 78), (2, 3, 85), (2, 6, 80), '
        '(3, 1, 90), (3, 4, 86), (3, 5, 91), '
        '(4, 5, 75), (4, 3, 70), '
        '(5, 3, 95), (5, 6, 92), (5, 1, 84), '
        '(6, 1, 68), (6, 4, 72), '
        '(7, 5, 89), (7, 1, 82), '
        '(8, 3, 74), (8, 6, 77)',
  ];
}