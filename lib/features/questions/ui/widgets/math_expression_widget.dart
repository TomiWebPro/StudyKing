import 'package:flutter/material.dart';

/// Mathematical Expression Renderer
///
/// Renders math expressions with styled tokens.
/// Supports fractions (a/b), exponents (^), subscripts (_),
/// sqrt, Greek letters, common operators, and LaTeX delimiters.
class MathExpressionWidget extends StatelessWidget {
  final String expression;
  final bool isSolution;
  final bool showPrefix;

  const MathExpressionWidget({
    super.key,
    required this.expression,
    this.isSolution = false,
    this.showPrefix = false,
  });

  @override
  Widget build(BuildContext context) {
    final styledExpression = _parseExpression(expression);

    if (isSolution) {
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: _buildStyledText(context, styledExpression),
      );
    }

    return _buildStyledText(context, styledExpression);
  }

  static const _greekLetters = <String, String>{
    'alpha': '\u03B1',
    'beta': '\u03B2',
    'gamma': '\u03B3',
    'delta': '\u03B4',
    'epsilon': '\u03B5',
    'zeta': '\u03B6',
    'eta': '\u03B7',
    'theta': '\u03B8',
    'iota': '\u03B9',
    'kappa': '\u03BA',
    'lambda': '\u03BB',
    'mu': '\u03BC',
    'nu': '\u03BD',
    'xi': '\u03BE',
    'omicron': '\u03BF',
    'pi': '\u03C0',
    'rho': '\u03C1',
    'sigma': '\u03C3',
    'tau': '\u03C4',
    'upsilon': '\u03C5',
    'phi': '\u03C6',
    'chi': '\u03C7',
    'psi': '\u03C8',
    'omega': '\u03C9',
    'Alpha': '\u0391',
    'Beta': '\u0392',
    'Gamma': '\u0393',
    'Delta': '\u0394',
    'Theta': '\u0398',
    'Lambda': '\u039B',
    'Pi': '\u03A0',
    'Sigma': '\u03A3',
    'Phi': '\u03A6',
    'Psi': '\u03A8',
    'Omega': '\u03A9',
  };

  List<InlineSpan> _parseExpression(String expr) {
    final spans = <InlineSpan>[];
    int i = 0;

    while (i < expr.length) {
      if (expr[i] == '\\') {
        final start = i;
        i++;
        final cmdStart = i;
        while (i < expr.length && (RegExp(r'^[a-zA-Z]$').hasMatch(expr[i]) || expr[i] == '{')) { i++; }
        final command = expr.substring(cmdStart, i);
        if (command == 'sqrt') {
          spans.add(TextSpan(
            text: '\u221A',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ));
        } else if (command == 'frac') {
          i = _skipWhitespace(expr, i);
          if (i < expr.length && expr[i] == '{') {
            i++;
            i = _findClosingBrace(expr, i) + 1;
          } else {
            spans.add(TextSpan(text: '/'));
          }
          i = _skipWhitespace(expr, i);
          if (i < expr.length && expr[i] == '{') {
            i++;
            final denEnd = _findClosingBrace(expr, i);
            i = denEnd + 1;
          }
          spans.add(const TextSpan(
            text: '/',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ));
        } else if (_greekLetters.containsKey(command)) {
          spans.add(TextSpan(text: _greekLetters[command]));
        } else if (command == 'times') {
          spans.add(const TextSpan(
            text: '\u00D7',
            style: TextStyle(fontSize: 16),
          ));
        } else if (command == 'cdot') {
          spans.add(const TextSpan(
            text: '\u00B7',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ));
        } else if (command == 'infty') {
          spans.add(const TextSpan(text: '\u221E'));
        } else if (command == 'rightarrow' || command == 'to') {
          spans.add(const TextSpan(text: '\u2192'));
        } else if (command == 'leftarrow') {
          spans.add(const TextSpan(text: '\u2190'));
        } else if (command == 'pm') {
          spans.add(const TextSpan(text: '\u00B1'));
        } else if (command == 'ge') {
          spans.add(TextSpan(
            text: '\u2265',
            style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
          ));
        } else if (command == 'le') {
          spans.add(TextSpan(
            text: '\u2264',
            style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
          ));
        } else if (command == 'neq') {
          spans.add(TextSpan(
            text: '\u2260',
            style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
          ));
        } else if (command == '(') {
          spans.add(TextSpan(
            text: '(',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ));
        } else if (command == ')') {
          spans.add(TextSpan(
            text: ')',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ));
        } else if (command == '[') {
          spans.add(TextSpan(
            text: '[',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ));
        } else if (command == ']') {
          spans.add(TextSpan(
            text: ']',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ));
        } else if (command == '{' || command == '}') {
          // skip grouping braces in output
        } else if (command == ' ') {
          spans.add(const TextSpan(text: ' '));
        } else {
          spans.add(TextSpan(text: expr.substring(start, i)));
        }
      } else if (expr[i] == '^' && i + 1 < expr.length) {
        i++;
        int superStart = i;
        if (expr[i] == '{') {
          i++;
          superStart = i;
          i = _findClosingBrace(expr, i);
        } else if (expr[i] == '(') {
          i++;
          superStart = i;
          i = _findClosingParen(expr, i);
        } else {
          while (i < expr.length && (RegExp(r'^[a-zA-Z0-9]$').hasMatch(expr[i]) || expr[i] == '-')) { i++; }
        }
        final superContent = expr.substring(superStart, i);
        if (superStart > 0 && expr[superStart - 1] == '(') i++;
        if (superStart > 0 && expr[superStart - 1] == '{') i++;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Text(
            superContent,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.purple[700],
            ),
            textScaler: const TextScaler.linear(0.75),
          ),
        ));
      } else if (expr[i] == '_' && i + 1 < expr.length) {
        i++;
        int subStart = i;
        if (expr[i] == '{') {
          i++;
          subStart = i;
          i = _findClosingBrace(expr, i);
        } else {
          while (i < expr.length && RegExp(r'^[a-zA-Z0-9]$').hasMatch(expr[i])) { i++; }
        }
        final subContent = expr.substring(subStart, i);
        if (subStart > 0 && expr[subStart - 1] == '{') i++;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Text(
            subContent,
            style: TextStyle(
              fontSize: 11,
              color: Colors.teal[700],
            ),
            textScaler: const TextScaler.linear(0.75),
          ),
        ));
      } else if (_isOperator(expr[i])) {
        spans.add(_buildOperatorSpan(expr[i]));
        i++;
      } else if (expr[i] == '{' || expr[i] == '}') {
        i++;
      } else if (expr[i] == '(' || expr[i] == '[') {
        spans.add(TextSpan(
          text: expr[i],
          style: TextStyle(
            color: Colors.brown.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ));
        i++;
      } else if (expr[i] == ')' || expr[i] == ']') {
        spans.add(TextSpan(
          text: expr[i],
          style: TextStyle(
            color: Colors.brown.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ));
        i++;
      } else if (expr[i] == ',' || expr[i] == ';') {
        spans.add(TextSpan(
          text: expr[i],
          style: const TextStyle(fontSize: 14),
        ));
        i++;
      } else if (expr[i] == '%') {
        spans.add(const TextSpan(
          text: '%',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
        ));
        i++;
      } else if (expr[i] == '=') {
        spans.add(const TextSpan(
          text: '=',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ));
        i++;
      } else if (expr[i] == ' ') {
        spans.add(const TextSpan(text: ' '));
        i++;
      } else {
        final start = i;
        while (i < expr.length &&
            RegExp(r'^[a-zA-Z0-9]$').hasMatch(expr[i]) &&
            !_isOperator(expr[i])) {
          i++;
        }
        final word = expr.substring(start, i);
        if (RegExp(r'^\d+\.?\d*$').hasMatch(word)) {
          spans.add(TextSpan(
            text: word,
            style: TextStyle(color: Colors.deepOrange.shade700),
          ));
        } else {
          spans.add(TextSpan(
            text: word,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ));
        }
      }
    }

    return spans;
  }

  int _skipWhitespace(String expr, int i) {
    while (i < expr.length && expr[i] == ' ') { i++; }
    return i;
  }

  int _findClosingBrace(String expr, int start) {
    int depth = 1;
    int i = start;
    while (i < expr.length && depth > 0) {
      if (expr[i] == '{') depth++;
      if (expr[i] == '}') depth--;
      if (depth > 0) i++;
    }
    return i;
  }

  int _findClosingParen(String expr, int start) {
    int depth = 1;
    int i = start;
    while (i < expr.length && depth > 0) {
      if (expr[i] == '(') depth++;
      if (expr[i] == ')') depth--;
      if (depth > 0) i++;
    }
    return i;
  }

  bool _isOperator(String ch) {
    return ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '>';
  }

  TextSpan _buildOperatorSpan(String op) {
    final color = op == '+' || op == '-'
        ? Colors.green.shade700
        : op == '*' || op == '/'
            ? Colors.orange.shade700
            : Colors.blue.shade700;
    return TextSpan(
      text: op == '*' ? '\u00D7' : op,
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStyledText(BuildContext context, List<InlineSpan> spans) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          if (showPrefix)
            const TextSpan(
              text: 'Expression: ',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ...spans,
        ],
      ),
    );
  }
}

/// Formula Renderer Widget
class FormulaWidget extends StatelessWidget {
  final String formula;
  final String? variable;

  const FormulaWidget({
    super.key,
    required this.formula,
    this.variable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        variable == null || variable!.trim().isEmpty
            ? formula
            : '$variable = $formula',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
        ),
      ),
    );
  }
}
