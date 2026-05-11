import 'package:flutter/material.dart';

class ColorUtils {
  static const Color defaultColor = Color(0xFF2196F3);

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
    } catch (_) {
      return defaultColor;
    }
  }

  static String getColorLabel(String hexColor) {
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