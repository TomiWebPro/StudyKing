/// Lightweight, dependency-free parser for the subset of [Mermaid](https://mermaid.js.org/)
/// syntax that StudyKing renders natively via [MermaidDiagram].
///
/// The parser is intentionally partial: it recognises the diagram families the
/// LLM actually emits when reconstructing charts (`reconstruct_chart` tool) or
/// when a tutor embeds a code block inline — **flowcharts/graphs, pie charts,
/// value-series bar charts, and markdown tables**. Anything it cannot classify
/// is returned as an `unsupported` spec so the renderer can show a graceful
/// fallback card instead of dumping raw Mermaid source on the student.
///
/// The parser never throws: a malformed spec degrades to an unsupported spec
/// and the error is logged via a warning (expected error path, per AGENTS.md).
library;
import 'package:studyking/core/utils/logger.dart';

/// Diagram families StudyKing can render from a Mermaid spec.
enum MermaidDiagramFamily { flowchart, pie, bar, table, unsupported }

/// Parsed representation of a Mermaid diagram spec.
///
/// Only the fields relevant to the spec's [family] are populated; the rest are
/// left empty. Inspect [family] first when consuming a spec.
class MermaidSpec {
  final String raw;
  final MermaidDiagramFamily family;

  final String? direction;
  final List<MermaidNode> nodes;
  final List<MermaidEdge> edges;
  final String? title;
  final List<MermaidSlice> slices;
  final List<MermaidDatum> barData;
  final List<String> tableHeaders;
  final List<List<String>> tableRows;
  final String hint;

  const MermaidSpec._({
    required this.raw,
    required this.family,
    this.direction,
    this.nodes = const [],
    this.edges = const [],
    this.title,
    this.slices = const [],
    this.barData = const [],
    this.tableHeaders = const [],
    this.tableRows = const [],
    this.hint = '',
  });

  MermaidSpec.flowchart({
    required String raw,
    required String direction,
    required List<MermaidNode> nodes,
    required List<MermaidEdge> edges,
  })  : this._(
          raw: raw,
          family: MermaidDiagramFamily.flowchart,
          direction: direction,
          nodes: nodes,
          edges: edges,
        );

  MermaidSpec.pie({
    required String raw,
    String? title,
    required List<MermaidSlice> slices,
  })  : this._(
          raw: raw,
          family: MermaidDiagramFamily.pie,
          title: title,
          slices: slices,
        );

  MermaidSpec.bar({
    required String raw,
    String? title,
    required List<MermaidDatum> data,
  })  : this._(
          raw: raw,
          family: MermaidDiagramFamily.bar,
          title: title,
          barData: data,
        );

  MermaidSpec.table({
    required String raw,
    required List<String> headers,
    required List<List<String>> rows,
  })  : this._(
          raw: raw,
          family: MermaidDiagramFamily.table,
          tableHeaders: headers,
          tableRows: rows,
        );

  MermaidSpec.unsupported(String raw, {String hint = ''})
      : this._(raw: raw, family: MermaidDiagramFamily.unsupported, hint: hint);
}

class MermaidNode {
  final String id;
  final String label;
  const MermaidNode(this.id, this.label);
}

class MermaidEdge {
  final String fromId;
  final String toId;
  final String fromLabel;
  final String toLabel;
  final String? label;
  const MermaidEdge(this.fromId, this.toId, this.fromLabel, this.toLabel,
      {this.label});
}

class MermaidSlice {
  final String label;
  final double value;
  final double fraction;
  const MermaidSlice(
      {required this.label, required this.value, required this.fraction});
}

class MermaidDatum {
  final String label;
  final double value;
  const MermaidDatum(this.label, this.value);
}

/// Parses Mermaid source text into a [MermaidSpec].
///
/// The parser is tolerant: it never throws for malformed input — unexpected
/// input simply yields an [MermaidDiagramFamily.unsupported] spec and logs a
/// warning.
class MermaidParser {
  static final Logger _logger = const Logger('MermaidParser');
  static Logger? testLogger;
  static Logger get _effectiveLogger => testLogger ?? _logger;

  MermaidSpec parse(String raw) {
    try {
      return _parse(raw);
    } catch (e, stack) {
      _effectiveLogger.w('Failed to parse Mermaid spec, falling back', e, stack);
      return MermaidSpec.unsupported(
        raw,
        hint: _firstMeaningfulLine(raw) ?? 'parse error',
      );
    }
  }

  static final _directiveFlowchart =
      RegExp(r'^(flowchart|graph)(\s+[a-z]{2})?$');
  static final _directiveBar = RegExp(
      r'^(barChart|columnChart|lineChart|hBarChart|scatter)\b',
      caseSensitive: false);
  static final _pieTitle =
      RegExp(r'^pie\s+(?:title|showdata|donut)\s+(.+)$', caseSensitive: false);
  static final _barTitle = RegExp(
      r'^(?:barChart|columnChart|lineChart|hBarChart|scatter)\s+(?:title\s+)?(.+)$',
      caseSensitive: false);

  MermaidSpec _parse(String raw) {
    final lines = _cleanLines(raw);
    if (lines.isEmpty) {
      return MermaidSpec.unsupported(raw, hint: 'empty');
    }
    final first = lines.first.trim();
    final lower = first.toLowerCase();

    if (_directiveFlowchart.hasMatch(lower)) {
      return _parseFlowchart(raw, lines, first);
    }
    if (lower == 'pie' || lower.startsWith('pie ')) {
      return _parsePie(raw, lines);
    }
    if (_directiveBar.hasMatch(lower)) {
      return _parseBar(raw, lines);
    }
    if (first.startsWith('|')) {
      return _parseTable(raw, lines);
    }

    // Directives omitted by the LLM — infer from content shape.
    final hasEdge = lines.any((l) => l.contains('-->'));
    if (hasEdge) {
      return _parseFlowchart(raw, lines, first);
    }
    final hasPieSlice = lines.any((l) => _parseDatum(l) != null);
    if (hasPieSlice) {
      // Quoted "label": value → pie-style; unquoted "label value" → bar.
      final quoted = lines.any((l) => _parseQuotedSlice(l) != null);
      return quoted ? _parsePie(raw, lines) : _parseBar(raw, lines);
    }

    return MermaidSpec.unsupported(raw, hint: first.isEmpty ? '(empty)' : first);
  }

  List<String> _cleanLines(String raw) {
    final out = <String>[];
    for (final line in raw.split('\n')) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('%%')) continue;
      out.add(line);
    }
    return out;
  }

  MermaidSpec _parseFlowchart(String raw, List<String> lines, String first) {
    var direction = 'TD';
    final dirMatch =
        RegExp(r'^(?:flowchart|graph)\s+([a-z]{2})$', caseSensitive: false)
            .firstMatch(first);
    if (dirMatch != null) {
      direction = dirMatch.group(1)!.toUpperCase();
    }

    final nodes = <String, MermaidNode>{};
    final edges = <MermaidEdge>[];

    for (final line in lines) {
      if (_directiveFlowchart.hasMatch(line.trim().toLowerCase())) continue;
      final edge = _parseEdge(line);
      if (edge != null) {
        edges.add(edge);
        _registerNode(nodes, edge.fromId, edge.fromLabel);
        _registerNode(nodes, edge.toId, edge.toLabel);
        continue;
      }
      // Standalone node definition: "A[label]", "B{decision}", etc.
      final node = _parseNode(line.trim());
      if (node != null && node.id.isNotEmpty && node.id != node.label) {
        _registerNode(nodes, node.id, node.label);
      }
    }

    return MermaidSpec.flowchart(
      raw: raw,
      direction: direction,
      nodes: nodes.values.toList(),
      edges: edges,
    );
  }

  void _registerNode(Map<String, MermaidNode> nodes, String id, String label) {
    if (id.isEmpty) return;
    nodes.putIfAbsent(id, () => MermaidNode(id, label));
  }

  /// Parses a flowchart edge line like `A --> B`, `A[Start] --> B[End]`,
  /// `A -->|label| B`, or `A --> B : note`.
  MermaidEdge? _parseEdge(String line) {
    final arrowIdx = line.indexOf('-->');
    if (arrowIdx < 0) return null;

    final fromStr = line.substring(0, arrowIdx).trim();
    var rest = line.substring(arrowIdx + 3).trim();

    String? edgeLabel;
    final pipe = RegExp(r'^\|([^|]*)\|\s*(.*)$').firstMatch(rest);
    if (pipe != null) {
      edgeLabel = pipe.group(1);
      rest = pipe.group(2)!.trim();
    }

    var toStr = rest;
    final colonIdx = rest.indexOf(':');
    // A trailing ": note" is Mermaid arrow-text; only split when a node token
    // precedes the colon so node labels containing ':' are not corrupted.
    if (colonIdx > 0) {
      final note = rest.substring(colonIdx + 1).trim();
      if (note.isNotEmpty) {
        edgeLabel = edgeLabel == null ? note : '$edgeLabel $note';
      }
      toStr = rest.substring(0, colonIdx).trim();
    }

    final from = _parseNode(fromStr);
    final to = _parseNode(toStr);
    if (from == null || to == null) return null;
    return MermaidEdge(
      from.id,
      to.id,
      from.label,
      to.label,
      label: edgeLabel,
    );
  }

  MermaidNode? _parseNode(String s) {
    s = s.trim();
    if (s.isEmpty) return null;
    final idMatch = RegExp(r'^([A-Za-z0-9_][A-Za-z0-9_\-\.]*)').firstMatch(s);
    final id = idMatch?.group(1) ?? s;
    var rest = s.substring(id.length).trim();
    var label = id;
    if (rest.isNotEmpty) {
      final open = rest[0];
      String? close;
      if (open == '[') {
        close = ']';
      } else if (open == '(') {
        close = rest.startsWith('((') ? '))' : ')';
      } else if (open == '{') {
        close = '}';
      } else if (open == '>') {
        close = ']';
      }
      if (close != null && rest.length > close.length && rest.endsWith(close)) {
        label = rest.substring(close.length, rest.length - close.length).trim();
      }
    }
    return MermaidNode(id, label);
  }

  MermaidSpec _parsePie(String raw, List<String> lines) {
    String? title;
    final data = <MermaidDatum>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('pie')) {
        final tm = _pieTitle.firstMatch(trimmed);
        if (tm != null) {
          title = tm.group(1)!.trim();
        }
        continue;
      }
      final datum = _parseQuotedSlice(line) ?? _parseDatum(line);
      if (datum != null) data.add(datum);
    }
    final sum = data.fold<double>(0, (p, e) => p + e.value);
    final count = data.length;
    final slices = data
        .map((d) => MermaidSlice(
              label: d.label,
              value: d.value,
              fraction: sum > 0
                  ? d.value / sum
                  : (count == 0 ? 0.0 : 1.0 / count),
            ))
        .toList();
    return MermaidSpec.pie(raw: raw, title: title, slices: slices);
  }

  MermaidSpec _parseBar(String raw, List<String> lines) {
    String? title;
    final data = <MermaidDatum>[];
    for (final line in lines) {
      final t = line.trim().toLowerCase();
      if (_directiveBar.hasMatch(t)) {
        final tm = _barTitle.firstMatch(line.trim());
        if (tm != null) title = tm.group(1)!.trim();
        continue;
      }
      final datum = _parseDatum(line) ?? _parseQuotedSlice(line);
      if (datum != null) data.add(datum);
    }
    return MermaidSpec.bar(raw: raw, title: title, data: data);
  }

  MermaidSpec _parseTable(String raw, List<String> lines) {
    final headers = _parseTableRow(lines.first);
    final rows = <List<String>>[];
    for (var i = 1; i < lines.length; i++) {
      final row = _parseTableRow(lines[i]);
      // Skip markdown separator rows (e.g. "|---|---|").
      if (row.isNotEmpty &&
          row.every((c) => c.isNotEmpty && c.replaceAll('-', '').isEmpty)) {
        continue;
      }
      if (row.isNotEmpty) rows.add(row);
    }
    return MermaidSpec.table(raw: raw, headers: headers, rows: rows);
  }

  List<String> _parseTableRow(String line) => line
      .split('|')
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toList();

  MermaidDatum? _parseDatum(String line) {
    final t = line.trim();
    final tokens = t.split(RegExp(r'\s+'));
    if (tokens.length < 2) return null;
    final last = tokens.last;
    final stripped = last.replaceAll('%', '');
    final val = double.tryParse(stripped);
    if (val == null) return null;
    return MermaidDatum(tokens.sublist(0, tokens.length - 1).join(' '), val);
  }

  /// Parses `"label" : value` (Mermaid pie-slice style).
  MermaidDatum? _parseQuotedSlice(String line) {
    final m = RegExp(r'^"([^"]*)"\s*:\s*([\d.]+)\s*%?$').firstMatch(line.trim());
    if (m == null) return null;
    return MermaidDatum(m.group(1)!, double.parse(m.group(2)!));
  }

  String? _firstMeaningfulLine(String raw) {
    for (final line in raw.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty && !t.startsWith('%%')) return t;
    }
    return null;
  }
}
