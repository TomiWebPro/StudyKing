import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/utils/logger.dart';

void main() {
  group('Logger', () {
    late Logger logger;

    setUp(() {
      logger = const Logger('TestTag');
    });

    test('has correct tag', () {
      expect(logger.tag, equals('TestTag'));
    });

    test('setVerbose changes verbose state', () {
      Logger.setVerbose(true);
      expect(Logger.shouldLog(LogLevel.debug), isTrue);
      expect(Logger.shouldLog(LogLevel.info), isTrue);
      expect(Logger.shouldLog(LogLevel.warn), isTrue);
      expect(Logger.shouldLog(LogLevel.error), isTrue);

      Logger.setVerbose(false);
      expect(Logger.shouldLog(LogLevel.debug), isFalse);
      expect(Logger.shouldLog(LogLevel.info), isFalse);
    });

    test('error and warn always log regardless of verbose', () {
      Logger.setVerbose(false);
      expect(Logger.shouldLog(LogLevel.error), isTrue);
      expect(Logger.shouldLog(LogLevel.warn), isTrue);
    });

    test('debug and info only log when verbose', () {
      Logger.setVerbose(false);
      expect(Logger.shouldLog(LogLevel.debug), isFalse);
      expect(Logger.shouldLog(LogLevel.info), isFalse);

      Logger.setVerbose(true);
      expect(Logger.shouldLog(LogLevel.debug), isTrue);
      expect(Logger.shouldLog(LogLevel.info), isTrue);
    });

    test('log methods do not throw', () {
      Logger.setVerbose(false);
      logger.d('debug message');
      logger.i('info message');
      logger.w('warn message');
      logger.e('error message');
      logger.w('warn with error', Exception('test error'));
      logger.e('error with stack', Exception('test'), StackTrace.current);
    });

    test('log methods do not throw when verbose', () {
      Logger.setVerbose(true);
      logger.d('debug message');
      logger.i('info message');
    });
  });
}
