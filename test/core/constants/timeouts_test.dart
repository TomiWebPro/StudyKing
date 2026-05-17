import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/timeouts.dart';

void main() {
  group('Timeouts', () {
    test('all timeout values are positive', () {
      expect(Timeouts.second.inMilliseconds, greaterThan(0));
      expect(Timeouts.ms100.inMilliseconds, greaterThan(0));
      expect(Timeouts.ms500.inMilliseconds, greaterThan(0));
      expect(Timeouts.hour.inSeconds, greaterThan(0));
      expect(Timeouts.fiveMinutes.inMinutes, greaterThan(0));
      expect(Timeouts.thirtyMinutes.inMinutes, greaterThan(0));
      expect(Timeouts.day.inHours, greaterThan(0));
      expect(Timeouts.week.inDays, greaterThan(0));
      expect(Timeouts.apiCall.inSeconds, greaterThan(0));
      expect(Timeouts.apiHealthCheck.inSeconds, greaterThan(0));
    });

    test('time relationships are consistent', () {
      expect(Timeouts.ms100.inMilliseconds, lessThan(Timeouts.second.inMilliseconds));
      expect(Timeouts.ms500.inMilliseconds, lessThan(Timeouts.second.inMilliseconds));
      expect(Timeouts.fiveMinutes.inMinutes, equals(5));
      expect(Timeouts.thirtyMinutes.inMinutes, equals(30));
      expect(Timeouts.hour.inMinutes, equals(60));
      expect(Timeouts.day.inHours, equals(24));
      expect(Timeouts.week.inDays, equals(7));
    });

    test('api timeouts are reasonable', () {
      expect(Timeouts.apiCall.inSeconds, lessThan(Timeouts.fiveMinutes.inSeconds));
      expect(Timeouts.apiHealthCheck.inSeconds, lessThan(Timeouts.apiCall.inSeconds));
    });
  });
}
