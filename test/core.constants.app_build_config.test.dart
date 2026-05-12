import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_build_config.dart';

void main() {
  group('AppEnvironment', () {
    test('has correct ordinal values', () {
      expect(AppEnvironment.development.index, 0);
      expect(AppEnvironment.staging.index, 1);
      expect(AppEnvironment.production.index, 2);
    });
  });

  group('BuildConfig', () {
    test('has static app name', () {
      expect(BuildConfig.appName, 'StudyKing');
    });

    test('has default version', () {
      expect(BuildConfig.appVersion, '1.0.0');
    });

    test('has default build number', () {
      expect(BuildConfig.appBuildNumber, '1');
    });

    test('get environment returns development by default', () {
      // Default APP_ENV is 'development'
      expect(BuildConfig.environment, AppEnvironment.development);
    });

    group('validateOrThrow', () {
      test('completes without error in non-release mode', () {
        // kReleaseMode is false in tests, so validateOrThrow returns early
        expect(() => BuildConfig.validateOrThrow(), returnsNormally);
      });
    });
  });
}
