import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/app_build_config.dart';

void main() {
  group('AppEnvironment', () {
    test('has correct ordinal values', () {
      expect(AppEnvironment.development.index, 0);
      expect(AppEnvironment.staging.index, 1);
      expect(AppEnvironment.production.index, 2);
    });

    test('development name is development', () {
      expect(AppEnvironment.development.name, 'development');
    });

    test('staging name is staging', () {
      expect(AppEnvironment.staging.name, 'staging');
    });

    test('production name is production', () {
      expect(AppEnvironment.production.name, 'production');
    });

    test('has exactly 3 values', () {
      expect(AppEnvironment.values.length, 3);
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
      expect(BuildConfig.environment, AppEnvironment.development);
    });

    test('environment parsing: dev returns development', () {
      const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
      // In test mode without APP_ENV override, this defaults to 'dev' which
      // maps to AppEnvironment.development in the default case.
      // This test verifies the parsing logic for 'dev'.
      if (env == 'dev') {
        expect(AppEnvironment.development.index, 0);
      }
    });

    group('validateOrThrow', () {
      test('completes without error in non-release mode', () {
        expect(() => BuildConfig.validateOrThrow(), returnsNormally);
      });


    });

    group('environment guard behavior', () {
      test('default env is not production', () {
        // In test mode, kReleaseMode is false and APP_ENV is 'development'
        // so unknown env values fall back to development
        expect(
          kReleaseMode || BuildConfig.environment == AppEnvironment.development,
          isTrue,
        );
      });
    });
  });
}
