import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/security_config.dart';

void main() {
  group('SecurityConfig encryption key validation', () {
    test('encryptionKeyOrThrow returns valid key when STUDYKING_ENCRYPTION_KEY is set', () {
      final key = SecurityConfig.encryptionKeyOrThrow();
      expect(key, isNotEmpty);
      expect(key.length, greaterThanOrEqualTo(32));
      expect(RegExp(r'[A-Za-z]').hasMatch(key), isTrue);
      expect(RegExp(r'\d').hasMatch(key), isTrue);
    });

    test('enforceStartupGuards passes with production env and valid key', () {
      expect(() => SecurityConfig.enforceStartupGuards(), returnsNormally);
    });
  });
}
