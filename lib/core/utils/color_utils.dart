import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import 'logger.dart';

class ColorUtils {
  static final Logger _logger = const Logger('ColorUtils');
  static const Color defaultColor = Color(0xFF2196F3);

  static double _relativeLuminance(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255) / 255.0;
    final g = (color.g * 255.0).round().clamp(0, 255) / 255.0;
    final b = (color.b * 255.0).round().clamp(0, 255) / 255.0;
    double linearize(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
  }

  static Color contrastingTextColor(Color backgroundColor) {
    final luminance = _relativeLuminance(backgroundColor);
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  static const List<String> availableColors = [
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#9C27B0',
    '#E91E63',
    '#00BCD4',
    '#FFC107',
    '#FF5722',
    '#607D8B',
  ];

  static String get defaultColorHex => '#2196F3';

  static Color stringToColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse(hex, radix: 16) + 0xFF000000);
    } catch (e) {
      _logger.w('stringToColor: invalid hex color "$hexColor": $e');
      return defaultColor;
    }
  }

  static Color getSubjectColor(BuildContext context, String name) {
    final cs = Theme.of(context).colorScheme;
    final colors = [cs.primary, cs.secondary, cs.tertiary];
    return colors[name.codeUnits.fold(0, (h, c) => h * 31 + c) % colors.length];
  }

  static String getColorLabel(String hexColor, {AppLocalizations? l10n}) {
    if (l10n != null) {
      switch (hexColor) {
        case '#2196F3':
          return l10n.colorBlue;
        case '#4CAF50':
          return l10n.colorGreen;
        case '#FF9800':
          return l10n.colorOrange;
        case '#9C27B0':
          return l10n.colorPurple;
        case '#E91E63':
          return l10n.colorPink;
        case '#00BCD4':
          return l10n.colorCyan;
        case '#FFC107':
          return l10n.colorAmber;
        case '#FF5722':
          return l10n.colorDeepOrange;
        case '#607D8B':
          return l10n.colorBlueGrey;
        default:
          return hexColor;
      }
    }
    // Fallback English labels used when no BuildContext/AppLocalizations is available
    // (e.g. in tests). All production callers pass l10n so this path is not user-visible.
    switch (hexColor) {
      case '#2196F3':
        return 'Blue';
      case '#4CAF50':
        return 'Green';
      case '#FF9800':
        return 'Orange';
      case '#9C27B0':
        return 'Purple';
      case '#E91E63':
        return 'Pink';
      case '#00BCD4':
        return 'Cyan';
      case '#FFC107':
        return 'Amber';
      case '#FF5722':
        return 'Deep Orange';
      case '#607D8B':
        return 'Blue Grey';
      default:
        return hexColor;
    }
  }
}