import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:studyking/core/utils/mermaid_parser.dart';
import 'package:studyking/core/utils/number_format_utils.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// Renders a parsed Mermaid diagram spec as a widget instead of dumping raw
/// Mermaid source on the student (vision agent_must_read.md §23: "rich
/// rendering for mathematical and scientific content, including graphs and
/// charts").
///
/// Only the chart families emitted by the mentor/tutor toolset are rendered
/// natively — flowcharts, pie charts, value-series bar charts, and markdown
/// tables. Anything the [MermaidParser] cannot classify is rendered as a
/// graceful fallback card (icon + hint) with **no raw source code visible**,
/// so a reconstruction the parser doesn't understand still fails safe.
class MermaidDiagram extends StatelessWidget {
  final String spec;
  final TextStyle? textStyle;
  final String? localeName;

  const MermaidDiagram({
    super.key,
    required this.spec,
    this.textStyle,
    this.localeName,
  });

  @override
  Widget build(BuildContext context) {
    final locale = localeName ??
        AppLocalizations.of(context)?.localeName ??
        'en';
    final parsed = MermaidParser().parse(spec);
    switch (parsed.family) {
      case MermaidDiagramFamily.flowchart:
        return _FlowchartRenderer(parsed, textStyle, locale);
      case MermaidDiagramFamily.pie:
        return _PieRenderer(parsed, textStyle, locale);
      case MermaidDiagramFamily.bar:
        return _BarRenderer(parsed, textStyle, locale);
      case MermaidDiagramFamily.table:
        return _TableRenderer(parsed, textStyle);
      case MermaidDiagramFamily.unsupported:
        return _UnsupportedDiagramCard(parsed);
    }
  }
}

class _DiagramCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget body;

  const _DiagramCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            body,
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Flowchart
// ---------------------------------------------------------------------------

class _FlowchartRenderer extends StatelessWidget {
  final MermaidSpec spec;
  final TextStyle? textStyle;
  final String locale;

  const _FlowchartRenderer(this.spec, this.textStyle, this.locale);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodes = spec.nodes;

    Widget nodeBox(MermaidNode node) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            node.label,
            style: textStyle ?? theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        );

    final nodeColumn = <Widget>[];
    for (var i = 0; i < nodes.length; i++) {
      nodeColumn.add(KeyedSubtree(
          key: ValueKey('node_${nodes[i].id}'), child: nodeBox(nodes[i])));
      if (i < nodes.length - 1) {
        nodeColumn.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Icon(Icons.arrow_downward, size: 20),
        ));
      }
    }

    final edgeChips = <Widget>[
      for (final e in spec.edges)
        LabelCard(
          text: e.label == null
              ? '${e.fromLabel} \u2192 ${e.toLabel}'
              : '${e.fromLabel} \u2192 ${e.toLabel}: ${e.label}',
        ),
    ];

    return _DiagramCard(
      icon: Icons.account_tree,
      title: spec.title ?? 'Flowchart',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nodeColumn.isNotEmpty)
            Column(crossAxisAlignment: CrossAxisAlignment.center, children: nodeColumn),
          if (edgeChips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 4, children: edgeChips),
          ],
        ],
      ),
    );
  }
}

class LabelCard extends StatelessWidget {
  final String text;
  const LabelCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: theme.textTheme.bodySmall),
    );
  }
}

// ---------------------------------------------------------------------------
// Pie chart
// ---------------------------------------------------------------------------

class _PieRenderer extends StatelessWidget {
  final MermaidSpec spec;
  final TextStyle? textStyle;
  final String locale;

  const _PieRenderer(this.spec, this.textStyle, this.locale);

  static const _colors = [
    Color(0xFF667EEA), Color(0xFFF47C54), Color(0xFF48A999),
    Color(0xFF9B5DE5), Color(0xFFF9C741), Color(0xFF61A0AF), Color(0xFF00BBF9),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slices = spec.slices;
    if (slices.isEmpty) {
      return _DiagramCard(
        icon: Icons.pie_chart,
        title: spec.title ?? 'Pie Chart',
        body: Text('No data', style: theme.textTheme.bodySmall),
      );
    }

    final arcs = <_PieArc>[];
    var start = -math.pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final s = slices[i];
      final sweep = s.fraction * 2 * math.pi;
      arcs.add(_PieArc(
        color: _colors[i % _colors.length],
        startAngle: start,
        sweepAngle: sweep,
      ));
      start += sweep;
    }

    final legend = <Widget>[
      for (var i = 0; i < slices.length; i++)
        _LegendDot(
          color: _colors[i % _colors.length],
          label: slices[i].label,
          fraction: slices[i].fraction,
          locale: locale,
        ),
    ];

    return _DiagramCard(
      icon: Icons.pie_chart,
      title: spec.title ?? 'Pie Chart',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: Center(
              child: CustomPaint(
                size: const Size.square(120),
                painter: _PiePainter(arcs),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 16, runSpacing: 6, children: legend),
        ],
      ),
    );
  }
}

class _PieArc {
  final Color color;
  final double startAngle;
  final double sweepAngle;
  const _PieArc(
      {required this.color, required this.startAngle, required this.sweepAngle});
}

class _PiePainter extends CustomPainter {
  final List<_PieArc> arcs;
  _PiePainter(this.arcs);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (final a in arcs) {
      canvas.drawArc(
        rect,
        a.startAngle,
        a.sweepAngle,
        true,
        Paint()
          ..color = a.color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) => old.arcs != arcs;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final double fraction;
  final String locale;
  const _LegendDot(
      {required this.color,
      required this.label,
      required this.fraction,
      required this.locale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = formatPercent(fraction * 100, locale,
        minFractionDigits: 0, maxFractionDigits: 1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$label ($pct)', style: theme.textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bar / value-series chart
// ---------------------------------------------------------------------------

class _BarRenderer extends StatelessWidget {
  final MermaidSpec spec;
  final TextStyle? textStyle;
  final String locale;

  const _BarRenderer(this.spec, this.textStyle, this.locale);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = spec.barData;
    if (data.isEmpty) {
      return _DiagramCard(
        icon: Icons.bar_chart,
        title: spec.title ?? 'Chart',
        body: Text('No data', style: theme.textTheme.bodySmall),
      );
    }
    final maxVal = data.map((d) => d.value).reduce(math.max);
    final heightScale = maxVal > 0 ? (100.0 / maxVal) : 0.0;
    final accent = Theme.of(context).colorScheme.tertiary;

    final bars = <Widget>[
      for (final d in data)
        Semantics(
          label: '${d.label}: ${formatDecimal(d.value, locale, minFractionDigits: 0, maxFractionDigits: 1)}',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (d.value > 0)
                Container(
                  width: 28,
                  height: d.value * heightScale,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                formatDecimal(d.value, locale,
                    minFractionDigits: 0, maxFractionDigits: 1),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
    ];

    final xLabels = <Widget>[
      for (final d in data) Text(d.label, style: theme.textTheme.bodySmall),
    ];

    return _DiagramCard(
      icon: Icons.bar_chart,
      title: spec.title ?? 'Chart',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: bars,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(spacing: 16, runSpacing: 4, children: xLabels),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Table
// ---------------------------------------------------------------------------

class _TableRenderer extends StatelessWidget {
  final MermaidSpec spec;
  final TextStyle? textStyle;

  const _TableRenderer(this.spec, this.textStyle);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headers = spec.tableHeaders;
    final rows = spec.tableRows;
    if (headers.isEmpty && rows.isEmpty) {
      return _DiagramCard(
        icon: Icons.table_chart,
        title: 'Table',
        body: Text('No data', style: theme.textTheme.bodySmall),
      );
    }

    final defaultCell = theme.textTheme.bodySmall ?? const TextStyle();
    TableCell buildCell(String text, bool header) => TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              text,
              style: header
                  ? defaultCell.copyWith(fontWeight: FontWeight.w600)
                  : defaultCell,
            ),
          ),
        );

    final tableRows = <TableRow>[
      if (headers.isNotEmpty)
        TableRow(children: [for (final h in headers) buildCell(h, true)]),
      for (final r in rows)
        TableRow(children: [for (final c in r) buildCell(c, false)]),
    ];

    return _DiagramCard(
      icon: Icons.table_chart,
      title: 'Table',
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(color: theme.colorScheme.outlineVariant),
          children: tableRows,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unsupported fallback (no raw source visible)
// ---------------------------------------------------------------------------

class _UnsupportedDiagramCard extends StatelessWidget {
  final MermaidSpec spec;
  const _UnsupportedDiagramCard(this.spec);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appL10n = AppLocalizations.of(context);
    final label = appL10n?.diagram ?? 'Diagram';
    return _DiagramCard(
      icon: Icons.insights,
      title: label,
      body: Text(
        spec.hint.isEmpty ? 'Unable to render this diagram' : spec.hint,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
