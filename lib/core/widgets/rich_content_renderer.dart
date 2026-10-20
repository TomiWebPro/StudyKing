import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../utils/logger.dart';
import 'mermaid_diagram.dart';

class RichContentRenderer extends StatelessWidget {
  static final Logger _logger = const Logger('RichContentRenderer');

  static Logger? testLogger;

  static Logger get _effectiveLogger => testLogger ?? _logger;
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
        if (segment is _DiagramSegment) {
          return _buildDiagramWidget(context, segment);
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

  Widget _buildDiagramWidget(BuildContext context, _DiagramSegment segment) {
    return MermaidDiagram(
      spec: segment.spec,
      textStyle: textStyle,
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
          _effectiveLogger.w(
            'Failed to render LaTeX segment: ${segment.latex}',
            e,
          );
          return Text(
            segment.latex,
            style: TextStyle(
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      _effectiveLogger.w(
        'Failed to render LaTeX segment: ${segment.latex}',
        e,
        stackTrace,
      );
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

  static const int _dollar = 36; // '$'
  static const String _doubleDollar = '\$\$';

  static List<_ContentSegment> _parseContent(String text) {
    final segments = <_ContentSegment>[];
    final lines = text.split('\n');
    final textBuffer = StringBuffer();
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];
      if (_isMermaidFenceStart(line)) {
        segments.addAll(_parseTextSegments(textBuffer.toString()));
        textBuffer.clear();
        final specBuf = StringBuffer();
        i++;
        while (i < lines.length && !_isFenceEnd(lines[i])) {
          if (specBuf.isNotEmpty) specBuf.writeln();
          specBuf.write(lines[i]);
          i++;
        }
        if (i < lines.length) i++; // skip closing fence
        segments.add(_DiagramSegment(specBuf.toString()));
        continue;
      }
      if (textBuffer.isNotEmpty) textBuffer.writeln();
      textBuffer.write(line);
      i++;
    }

    segments.addAll(_parseTextSegments(textBuffer.toString()));

    if (segments.isEmpty) {
      segments.add(_TextSegment(''));
    }

    return segments;
  }

  static bool _isMermaidFenceStart(String line) {
    final t = line.trim();
    if (t == '```mermaid' || t == '```mermaid ') {
      return true;
    }
    return t.startsWith('```') &&
        t.length > 3 &&
        t.substring(3).trim() == 'mermaid';
  }

  static bool _isFenceEnd(String line) => line.trim() == '```';

  /// Math-aware text segmentation (pure `$…$` / `$$…$$`), preserving plain
  /// text runs. Extracted from the original char-level parser so fenced diagram
  /// blocks can be peeled off before math parsing runs.
  static List<_ContentSegment> _parseTextSegments(String text) {
    final segments = <_ContentSegment>[];
    final buffer = StringBuffer();
    var i = 0;

    while (i < text.length) {
      final code = text.codeUnitAt(i);
      if (i + 1 < text.length &&
          code == _dollar &&
          text.codeUnitAt(i + 1) == _dollar) {
        if (buffer.isNotEmpty) {
          segments.add(_TextSegment(buffer.toString()));
          buffer.clear();
        }
        final end = text.indexOf(_doubleDollar, i + 2);
        if (end != -1) {
          segments.add(_MathSegment(
              text.substring(i + 2, end), displayMode: true));
          i = end + 2;
        } else {
          buffer.write(_doubleDollar);
          i += 2;
        }
      } else if (code == _dollar) {
        if (buffer.isNotEmpty) {
          segments.add(_TextSegment(buffer.toString()));
          buffer.clear();
        }
        final end = text.indexOf(String.fromCharCode(_dollar), i + 1);
        if (end != -1 && end > i + 1) {
          segments.add(_MathSegment(
              text.substring(i + 1, end), displayMode: false));
          i = end + 1;
        } else {
          buffer.writeCharCode(_dollar);
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

class _DiagramSegment extends _ContentSegment {
  final String spec;
  _DiagramSegment(this.spec);
}
