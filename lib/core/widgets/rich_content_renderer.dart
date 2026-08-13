import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class RichContentRenderer extends StatelessWidget {
  final String content;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final bool displayMode;

  const RichContentRenderer({
    super.key,
    required this.content,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.displayMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final segments = _parseContent(content);
    if (segments.length == 1 && segments.first is _TextSegment) {
      return Text(
        (segments.first as _TextSegment).text,
        style: textStyle ?? DefaultTextStyle.of(context).style,
        textAlign: textAlign,
      );
    }

    return Wrap(
      alignment: _wrapAlignment(textAlign),
      crossAxisAlignment: WrapCrossAlignment.center,
      children: segments.map((segment) {
        if (segment is _MathSegment) {
          return _buildMathWidget(context, segment);
        }
        final textSegment = segment as _TextSegment;
        return Text(
          textSegment.text,
          style: textStyle ?? DefaultTextStyle.of(context).style,
          textAlign: textAlign,
        );
      }).toList(),
    );
  }

  Widget _buildMathWidget(BuildContext context, _MathSegment segment) {
    try {
      return Math.tex(
        segment.latex,
        textStyle: TextStyle(
          fontSize: segment.displayMode ? 20 : null,
          color: DefaultTextStyle.of(context).style.color,
        ),
        textScaleFactor: 1.0,
        onErrorFallback: (FlutterMathException e) {
          return Text(
            segment.latex,
            style: TextStyle(
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    } catch (e) {
      return Text(
        segment.latex,
        style: TextStyle(
          fontFamily: 'monospace',
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  WrapAlignment _wrapAlignment(TextAlign align) {
    return switch (align) {
      TextAlign.center => WrapAlignment.center,
      TextAlign.end => WrapAlignment.end,
      TextAlign.left || TextAlign.start => WrapAlignment.start,
      TextAlign.right || TextAlign.end => WrapAlignment.end,
      TextAlign.justify => WrapAlignment.spaceBetween,
    };
  }

  static List<_ContentSegment> _parseContent(String text) {
    final segments = <_ContentSegment>[];
    final buffer = StringBuffer();
    int i = 0;

    while (i < text.length) {
      if (i + 1 < text.length && text[i] == '\$' && text[i + 1] == '\$') {
        if (buffer.isNotEmpty) {
          segments.add(_TextSegment(buffer.toString()));
          buffer.clear();
        }
        final end = text.indexOf(r'$$', i + 2);
        if (end != -1) {
          segments.add(_MathSegment(
            text.substring(i + 2, end),
            displayMode: true,
          ));
          i = end + 2;
        } else {
          buffer.write(r'$$');
          i += 2;
        }
      } else if (text[i] == '\$') {
        if (buffer.isNotEmpty) {
          segments.add(_TextSegment(buffer.toString()));
          buffer.clear();
        }
        final end = text.indexOf('\$', i + 1);
        if (end != -1 && end > i + 1) {
          segments.add(_MathSegment(
            text.substring(i + 1, end),
            displayMode: false,
          ));
          i = end + 1;
        } else {
          buffer.write('\$');
          i++;
        }
      } else {
        buffer.write(text[i]);
        i++;
      }
    }

    if (buffer.isNotEmpty) {
      segments.add(_TextSegment(buffer.toString()));
    }

    if (segments.isEmpty) {
      segments.add(_TextSegment(''));
    }

    return segments;
  }
}

abstract class _ContentSegment {}

class _TextSegment extends _ContentSegment {
  final String text;
  _TextSegment(this.text);
}

class _MathSegment extends _ContentSegment {
  final String latex;
  final bool displayMode;
  _MathSegment(this.latex, {this.displayMode = false});
}
