import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/color_utils.dart';

void main() {
  group('ColorUtils', () {
    test('defaultColorHex is a valid hex string', () {
      expect(ColorUtils.defaultColorHex, startsWith('#'));
    });

    test('availableColors contains at least one color', () {
      expect(ColorUtils.availableColors, isNotEmpty);
    });

    test('stringToColor returns a Color', () {
      final color = ColorUtils.stringToColor('#2196F3');
      expect(color, isA<Color>());
    });

    test('getColorLabel returns a string', () {
      final label = ColorUtils.getColorLabel('#2196F3');
      expect(label, isA<String>());
      expect(label, isNotEmpty);
    });

    test('defaultColorHex matches expected hex', () {
      expect(ColorUtils.defaultColorHex, '#2196F3');
    });

    test('availableColors contains all expected colors', () {
      expect(ColorUtils.availableColors, containsAll([
        '#2196F3',
        '#4CAF50',
        '#FF9800',
        '#9C27B0',
        '#E91E63',
        '#00BCD4',
        '#FFC107',
        '#FF5722',
        '#607D8B',
      ]));
    });

    test('stringToColor returns correct color for known hex', () {
      final color = ColorUtils.stringToColor('#4CAF50');
      expect(color, isA<Color>());
      expect(color.toARGB32(), 0xFF4CAF50);
    });

    test('stringToColor handles invalid hex gracefully', () {
      final color = ColorUtils.stringToColor('invalid');
      expect(color, isA<Color>());
    });

    test('getColorLabel returns label for known color', () {
      final label = ColorUtils.getColorLabel('#2196F3');
      expect(label, 'Blue');
    });

    test('getColorLabel returns hex for unknown color', () {
      final label = ColorUtils.getColorLabel('#FFFFFF');
      expect(label, '#FFFFFF');
    });

    test('getColorLabel returns label for all known colors', () {
      expect(ColorUtils.getColorLabel('#4CAF50'), 'Green');
      expect(ColorUtils.getColorLabel('#FF9800'), 'Orange');
      expect(ColorUtils.getColorLabel('#9C27B0'), 'Purple');
      expect(ColorUtils.getColorLabel('#E91E63'), 'Pink');
      expect(ColorUtils.getColorLabel('#00BCD4'), 'Cyan');
      expect(ColorUtils.getColorLabel('#FFC107'), 'Amber');
      expect(ColorUtils.getColorLabel('#FF5722'), 'Deep Orange');
      expect(ColorUtils.getColorLabel('#607D8B'), 'Blue Grey');
    });
  });
}
