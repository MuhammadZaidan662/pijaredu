import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A text controller that colors SQL keywords, functions, strings, numbers
/// and comments. It only changes how the text looks, never the text itself.
class SqlTextEditingController extends TextEditingController {
  SqlTextEditingController({super.text});

  static final _tokenPattern = RegExp(
    r"(--[^\n]*)"
    r"|(/\*[\s\S]*?(?:\*/|$))"
    r"|('(?:[^']|'')*'?)"
    r"|(\b\d+(?:\.\d+)?\b)"
    r"|(\b[A-Za-z_][A-Za-z_0-9]*\b)",
  );

  static const _keywords = {
    'SELECT', 'FROM', 'WHERE', 'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET',
    'DELETE', 'CREATE', 'TABLE', 'DROP', 'ALTER', 'ADD', 'COLUMN', 'RENAME',
    'TO', 'PRIMARY', 'KEY', 'FOREIGN', 'REFERENCES', 'NOT', 'NULL', 'DEFAULT',
    'UNIQUE', 'INDEX', 'VIEW', 'AND', 'OR', 'IN', 'LIKE', 'BETWEEN', 'IS',
    'AS', 'ON', 'JOIN', 'INNER', 'LEFT', 'RIGHT', 'OUTER', 'CROSS', 'GROUP',
    'BY', 'ORDER', 'HAVING', 'LIMIT', 'OFFSET', 'DISTINCT', 'UNION', 'ALL',
    'CASE', 'WHEN', 'THEN', 'ELSE', 'END', 'ASC', 'DESC', 'EXISTS', 'WITH',
    'RECURSIVE', 'INTEGER', 'TEXT', 'REAL', 'NUMERIC', 'BLOB', 'CHECK', 'IF',
    'PRAGMA', 'EXPLAIN', 'REPLACE', 'AUTOINCREMENT', 'CONSTRAINT',
  };

  static const _functions = {
    'COUNT', 'SUM', 'AVG', 'MIN', 'MAX', 'ROUND', 'LENGTH', 'UPPER', 'LOWER',
    'SUBSTR', 'COALESCE', 'IFNULL', 'ABS', 'TRIM', 'REPLACE', 'DATE', 'NOW',
  };

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    const keywordStyle =
    TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700);
    const functionStyle = TextStyle(color: Color(0xFF0E7490));
    const stringStyle = TextStyle(color: Color(0xFF15803D));
    const numberStyle = TextStyle(color: Color(0xFFB45309));
    const commentStyle =
    TextStyle(color: AppColors.textGrey, fontStyle: FontStyle.italic);

    final children = <TextSpan>[];
    var last = 0;

    for (final match in _tokenPattern.allMatches(text)) {
      if (match.start > last) {
        children.add(TextSpan(text: text.substring(last, match.start)));
      }

      final token = match[0]!;
      TextStyle? tokenStyle;

      if (match[1] != null || match[2] != null) {
        tokenStyle = commentStyle;
      } else if (match[3] != null) {
        tokenStyle = stringStyle;
      } else if (match[4] != null) {
        tokenStyle = numberStyle;
      } else {
        final upper = token.toUpperCase();
        if (_keywords.contains(upper)) {
          tokenStyle = keywordStyle;
        } else if (_functions.contains(upper)) {
          tokenStyle = functionStyle;
        }
      }

      children.add(TextSpan(text: token, style: tokenStyle));
      last = match.end;
    }

    if (last < text.length) {
      children.add(TextSpan(text: text.substring(last)));
    }

    return TextSpan(style: style, children: children);
  }
}