import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/notification_ids.dart';

void main() {
  group('NotificationIds', () {
    test('dailyReminder is a stable alarm id', () {
      // The schedule path (EngagementScheduler / settings time
      // picker) and the cancel path (disabling the toggle) must
      // agree on the same numeric id or the alarm can never be
      // removed again.
      expect(NotificationIds.dailyReminder, isA<int>());
      expect(NotificationIds.dailyReminder, 9999);
    });
  });
}
