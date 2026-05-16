import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_constants.dart';

void main() {
  group('app_constants barrel', () {
    test('exports ApiSecrets', () {
      expect(ApiSecrets, isA<Type>());
    });

    test('exports ApiConfig', () {
      expect(ApiConfig, isA<Type>());
    });

    test('exports BuildConfig', () {
      expect(BuildConfig, isA<Type>());
    });

    test('exports AppEnvironment', () {
      expect(AppEnvironment, isA<Type>());
    });

    test('exports AppConfig', () {
      expect(AppConfig, isA<Type>());
    });

    test('exports AppConstants', () {
      expect(AppConstants, isA<Type>());
    });

    test('exports UiConfig', () {
      expect(UiConfig, isA<Type>());
    });

    test('exports CacheConfig', () {
      expect(CacheConfig, isA<Type>());
    });

    test('exports StorageConfig', () {
      expect(StorageConfig, isA<Type>());
    });

    test('exports SecurityConfig', () {
      expect(SecurityConfig, isA<Type>());
    });

    test('exports defaultModelForProvider', () {
      expect(defaultModelForProvider, isA<Function>());
    });
  });
}
