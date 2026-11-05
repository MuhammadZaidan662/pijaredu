import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/widgets/home_widgets.dart';
import 'sql_database.dart';
import 'sql_highlighter.dart';

class _Example {
  const _Example(this.title, this.sql);

  final String title;
  final String sql;
}

const _examples = [
  _Example('All students', 'SELECT * FROM students;'),
  _Example(
    'Filter and sort',
    'SELECT name, gpa\nFROM students\nWHERE gpa >= 3.5\nORDER BY gpa DESC;',
  ),
  _Example(
    'Count students per major',
    'SELECT major, COUNT(*) AS total\nFROM students\nGROUP BY major;',
  ),
  _Example(
    'JOIN three tables',
    'SELECT s.name AS student, c.title AS course, e.grade\n'
        'FROM enrollments e\n'
        'JOIN students s ON s.id = e.student_id\n'
        'JOIN courses c ON c.id = e.course_id;',
  ),
  _Example(
    'Average grade per course',
    'SELECT c.title, ROUND(AVG(e.grade), 1) AS avg_grade\n'
        'FROM courses c\n'
        'JOIN enrollments e ON e.course_id = c.id\n'
        'GROUP BY c.title;',
  ),
  _Example(
    'Insert a student',
    "INSERT INTO students (name, email, major, gpa, enrolled_year)\n"
        "VALUES ('New Student', 'new@campus.edu', 'Information Systems', 3.2, 2025);",
  ),
  _Example(
    'Update a record',
    "UPDATE students SET gpa = 3.9 WHERE name = 'Alya Putri';",
  ),
  _Example(
    'Create your own table',
    'CREATE TABLE rooms (\n'
        '  id INTEGER PRIMARY KEY,\n'
        '  name TEXT NOT NULL,\n'
        '  capacity INTEGER\n'
        ');',
  ),
];

class SqlPlaygroundPage extends StatefulWidget {
  const SqlPlaygroundPage({super.key});

  @override
  State<SqlPlaygroundPage> createState() => _SqlPlaygroundPageState();
}

class _SqlPlaygroundPageState extends State<SqlPlaygroundPage> {
  final _controller = SqlTextEditingController(
    text: 'SELECT *\nFROM students;',
  );
  final _db = SqlDatabase.instance;

  QueryResult? _result;
  bool _ready = false;
  bool _running = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _ready = false;
      _initError = null;
    });
    try {
      await _db.ensureReady();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = e.toString());
    }
  }

  Future<void> _run() async {
    FocusScope.of(context).unfocus();
    setState(() => _running = true);
    final result = await _db.run(_controller.text);
    if (!mounted) return;
    setState(() {
      _result = result;
      _running = false;
    });
  }

  void _setQuery(String sql) {
    _controller.text = sql;
    _controller.selection = TextSelection.collapsed(offset: sql.length);
  }

  Future<void> _showExamples() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _examples.length + 1,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Example queries',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                );
              }
              final example = _examples[index - 1];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(example.title),
                subtitle: Text(
                  example.sql,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    color: AppColors.textGrey,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, example.sql),
              );
            },
          ),
        ),
      ),
    );
    if (chosen != null) _setQuery(chosen);
  }

  Future<void> _showSchema() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          child: FutureBuilder<List<TableInfo>>(
            future: _db.loadSchema(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Could not load the database structure.'),
                );
              }
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final tables = snapshot.data!;
              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Database structure',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Tap a table name to select all of its rows.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  for (final table in tables)
                    _TableTile(
                      table: table,
                      onSelect: () => Navigator.pop(
                        sheetContext,
                        'SELECT * FROM ${table.name};',
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    if (chosen != null) _setQuery(chosen);
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset database?'),
        content: const Text(
          'All changes and tables you created will be removed, and the sample '
              'University database will be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _db.reset();
      if (!mounted) return;
      setState(() {
        _result = const QueryResult(
          message: 'The database was reset to its original state.',
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _result = const QueryResult(
          error: 'Could not reset the database. Please try again.',
        );
      });
    }
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _running ? null : _run,
            icon: _running
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(_running ? 'Running...' : 'Run Query'),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          tooltip: 'Clear editor',
          onPressed: _running ? null : () => _setQuery(''),
          icon: const Icon(Icons.backspace_outlined),
          style: IconButton.styleFrom(
            minimumSize: const Size(54, 54),
            foregroundColor: AppColors.textGrey,
            side: const BorderSide(color: AppColors.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (kIsWeb) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'SQL Practice runs on Android.\n'
                'Please open the app on a phone or an emulator.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    if (_initError != null) {
      return HomeLoadError(
        message: 'Could not open the practice database.\n$_initError',
        onRetry: _init,
      );
    }

    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape =
            constraints.maxWidth > constraints.maxHeight &&
                constraints.maxWidth >= 600;
        final editor = _EditorCard(controller: _controller);
        final result = _ResultPanel(result: _result, running: _running);

        if (landscape) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: editor),
                      const SizedBox(height: 10),
                      _actions(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: result),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            children: [
              SizedBox(height: 190, child: editor),
              const SizedBox(height: 10),
              _actions(),
              const SizedBox(height: 12),
              Expanded(child: result),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('SQL Practice'),
        actions: [
          IconButton(
            tooltip: 'Example queries',
            onPressed: _ready ? _showExamples : null,
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            tooltip: 'Database structure',
            onPressed: _ready ? _showSchema : null,
            icon: const Icon(Icons.table_chart_outlined),
          ),
          IconButton(
            tooltip: 'Reset database',
            onPressed: _ready ? _confirmReset : null,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: _body(),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.controller});

  final SqlTextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: TextField(
        controller: controller,
        expands: true,
        maxLines: null,
        minLines: null,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        autocorrect: false,
        enableSuggestions: false,
        smartQuotesType: SmartQuotesType.disabled,
        smartDashesType: SmartDashesType.disabled,
        textCapitalization: TextCapitalization.none,
        cursorColor: AppColors.primary,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          height: 1.5,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration.collapsed(
          hintText: 'Write your SQL here...',
          hintStyle: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result, required this.running});

  final QueryResult? result;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const Divider(height: 1),
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _header() {
    final r = result;
    IconData icon = Icons.table_rows_outlined;
    Color color = AppColors.textGrey;
    String label = 'Result';

    if (running) {
      label = 'Running...';
    } else if (r != null) {
      final ms = r.elapsed.inMilliseconds;
      if (r.isError) {
        icon = Icons.error_outline_rounded;
        color = AppColors.danger;
        label = 'Error';
      } else if (r.hasTable) {
        icon = Icons.check_circle_outline_rounded;
        color = AppColors.success;
        label = '${r.totalRows} ${r.totalRows == 1 ? 'row' : 'rows'} · $ms ms';
      } else {
        icon = Icons.check_circle_outline_rounded;
        color = AppColors.success;
        label = 'Done · $ms ms';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: color == AppColors.textGrey ? AppColors.textDark : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    final r = result;

    if (r == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Run a query to see the result here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    if (r.isError) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          r.error!,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            height: 1.5,
            color: AppColors.danger,
          ),
        ),
      );
    }

    if (!r.hasTable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            r.message ?? 'Done.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r.statementCount > 1 || r.truncated)
          Container(
            color: AppColors.tileYellow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              [
                if (r.statementCount > 1)
                  'Ran ${r.statementCount} statements. Showing the last result.',
                if (r.truncated)
                  'Showing the first ${r.rows.length} of ${r.totalRows} rows.',
              ].join(' '),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                const WidgetStatePropertyAll(AppColors.tilePurple),
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 44,
                columnSpacing: 24,
                horizontalMargin: 16,
                columns: [
                  for (final column in r.columns)
                    DataColumn(
                      label: Text(
                        column,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
                rows: [
                  for (final row in r.rows)
                    DataRow(
                      cells: [
                        for (final value in row) DataCell(_cell(value)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(Object? value) {
    if (value == null) {
      return const Text(
        'NULL',
        style: TextStyle(
          fontSize: 12.5,
          fontStyle: FontStyle.italic,
          color: AppColors.textGrey,
        ),
      );
    }
    if (value is List<int>) {
      return Text(
        '[BLOB ${value.length} bytes]',
        style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
      );
    }
    return Text('$value', style: const TextStyle(fontSize: 12.5));
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({required this.table, required this.onSelect});

  final TableInfo table;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_rows_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      table.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final column in table.columns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          child: column.isPrimaryKey
                              ? const Icon(Icons.key_rounded,
                              size: 14, color: AppColors.spark)
                              : null,
                        ),
                        Expanded(
                          child: Text(
                            column.name,
                            style: GoogleFonts.jetBrainsMono(fontSize: 12.5),
                          ),
                        ),
                        Text(
                          column.type.toLowerCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11.5,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}