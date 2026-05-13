import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/color_utils.dart';
import 'package:studyking/l10n/generated/app_localizations_en.dart';

void main() {
  group('ColorUtils', () {
    test('defaultColor is blue', () {
      expect(ColorUtils.defaultColor.toARGB32(), 0xFF2196F3);
    });

    test('defaultColorHex is correct', () {
      expect(ColorUtils.defaultColorHex, '#2196F3');
    });

    test('availableColors has 9 colors', () {
      expect(ColorUtils.availableColors.length, 9);
    });

    group('stringToColor', () {
      test('parses valid hex color', () {
        final color = ColorUtils.stringToColor('#2196F3');
        expect(color.toARGB32(), 0xFF2196F3);
      });

      test('parses hex without hash', () {
        final color = ColorUtils.stringToColor('4CAF50');
        expect(color.toARGB32(), 0xFF4CAF50);
      });

      test('returns default color for invalid input', () {
        final color = ColorUtils.stringToColor('not-a-color');
        expect(color, ColorUtils.defaultColor);
      });

      test('returns default color for empty string', () {
        final color = ColorUtils.stringToColor('');
        expect(color, ColorUtils.defaultColor);
      });

      test('parses 3-char hex shorthand', () {
        final color = ColorUtils.stringToColor('#FFF');
        expect(color.toARGB32(), 0xFF000FFF);
      });

      test('parses hex with alpha channel', () {
        final color = ColorUtils.stringToColor('#FF2196F3');
        expect(color.toARGB32(), equals(0xFE2196F3));
      });

      test('parses boundary value black', () {
        final color = ColorUtils.stringToColor('#000000');
        expect(color.toARGB32(), 0xFF000000);
      });

      test('parses boundary value white', () {
        final color = ColorUtils.stringToColor('#FFFFFF');
        expect(color.toARGB32(), 0xFFFFFFFF);
      });

      test('returns default for very long string', () {
        final color = ColorUtils.stringToColor('#1234567890ABCDEF');
        expect(color, ColorUtils.defaultColor);
      });

      test('returns default for null-like empty after hash', () {
        final color = ColorUtils.stringToColor('#');
        expect(color, ColorUtils.defaultColor);
      });
    });

    group('getColorLabel', () {
      test('returns Blue for #2196F3', () {
        expect(ColorUtils.getColorLabel('#2196F3'), 'Blue');
      });

      test('returns Green for #4CAF50', () {
        expect(ColorUtils.getColorLabel('#4CAF50'), 'Green');
      });

      test('returns Orange for #FF9800', () {
        expect(ColorUtils.getColorLabel('#FF9800'), 'Orange');
      });

      test('returns Purple for #9C27B0', () {
        expect(ColorUtils.getColorLabel('#9C27B0'), 'Purple');
      });

      test('returns Pink for #E91E63', () {
        expect(ColorUtils.getColorLabel('#E91E63'), 'Pink');
      });

      test('returns Cyan for #00BCD4', () {
        expect(ColorUtils.getColorLabel('#00BCD4'), 'Cyan');
      });

      test('returns Amber for #FFC107', () {
        expect(ColorUtils.getColorLabel('#FFC107'), 'Amber');
      });

      test('returns Deep Orange for #FF5722', () {
        expect(ColorUtils.getColorLabel('#FF5722'), 'Deep Orange');
      });

      test('returns Blue Grey for #607D8B', () {
        expect(ColorUtils.getColorLabel('#607D8B'), 'Blue Grey');
      });

      test('returns hex string for unknown color', () {
        expect(ColorUtils.getColorLabel('#FFFFFF'), '#FFFFFF');
      });

      test('returns localized label when l10n provided', () {
        final l10n = AppLocalizationsEn();
        expect(ColorUtils.getColorLabel('#2196F3', l10n: l10n), l10n.colorBlue);
        expect(ColorUtils.getColorLabel('#4CAF50', l10n: l10n), l10n.colorGreen);
        expect(ColorUtils.getColorLabel('#FF9800', l10n: l10n), l10n.colorOrange);
      });

      test('returns hex string for unknown color with l10n', () {
        final l10n = AppLocalizationsEn();
        expect(ColorUtils.getColorLabel('#AABBCC', l10n: l10n), '#AABBCC');
      });

      test('returns default label for null l10n', () {
        expect(ColorUtils.getColorLabel('#2196F3', l10n: null), 'Blue');
      });
    });
  });
}
