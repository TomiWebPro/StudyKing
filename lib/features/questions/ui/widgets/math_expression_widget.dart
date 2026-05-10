import 'package:flutter/material.dart';

/// Mathematical Expression Renderer
/// 
/// Displays LaTeX/Typst math expressions
/// For production, integrate with MathJax or MathPainter
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
    // Parse and display math expression
    // For production, use a proper math rendering library
    
    final styledExpression = _styleMathExpression(expression);
    
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

  List<TextSpan> _styleMathExpression(String expression) {
    final tokenRegex = RegExp(r'(\\\(|\\\)|\\\[|\\\]|\$|\s+|[+\-*/=><^()])');
    final parts = expression.splitMapJoin(
      tokenRegex,
      onMatch: (m) => '\u0000${m.group(0)}\u0000',
      onNonMatch: (n) => n,
    ).split('\u0000').where((e) => e.isNotEmpty);

    return parts.map((token) {
      if (RegExp(r'^\s+$').hasMatch(token)) {
        return TextSpan(text: token);
      }

      if (token == r'\(' || token == r'\)' || token == r'\[' || token == r'\]' || token == r'$') {
        return TextSpan(
          text: token,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        );
      }
      
      if (RegExp(r'^[+\-*/=><^()]$').hasMatch(token)) {
        return TextSpan(
          text: token,
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
      }
      
      if (RegExp(r'^[a-zA-Z]+$').hasMatch(token)) {
        return TextSpan(
          text: token,
          style: const TextStyle(
            fontStyle: FontStyle.italic,
          ),
        );
      }
      
      return TextSpan(text: token);
    }).toList();
  }

  Widget _buildStyledText(BuildContext context, List<TextSpan> spans) {
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
