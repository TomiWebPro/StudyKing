import 'package:flutter/material.dart';

class MathInputToolbar extends StatelessWidget {
  final TextEditingController controller;
  final bool showPreview;
  final String? previewExpression;

  const MathInputToolbar({
    super.key,
    required this.controller,
    this.showPreview = true,
    this.previewExpression,
  });

  static const _symbols = [
    ('^', 'xⁿ'),
    ('_', 'xₙ'),
    ('sqrt(', '√'),
    ('pi', 'π'),
    ('theta', 'θ'),
    ('alpha', 'α'),
    ('beta', 'β'),
    ('infty', '∞'),
    ('sum', 'Σ'),
    ('int', '∫'),
    ('frac{}{}', 'a/b'),
    ('pm', '±'),
    ('times', '×'),
    ('rightarrow', '→'),
    ('geq', '≥'),
    ('leq', '≤'),
    ('neq', '≠'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Row(
            children: _symbols.map((entry) {
              return Padding(
                padding: const EdgeInsets.all(2),
                child: Semantics(
                  button: true,
                  label: entry.$1,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      onTap: () {
                        final text = controller.text;
                        final selection = controller.selection;
                        final cursorPos = selection.isValid ? selection.start : text.length;
                        final newText = text.substring(0, cursorPos) +
                            entry.$1 +
                            text.substring(cursorPos);
                        controller.text = newText;
                        controller.selection = TextSelection.collapsed(
                          offset: cursorPos + entry.$1.length,
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text(
                          entry.$2,
                          style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}