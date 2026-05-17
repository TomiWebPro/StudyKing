import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/constants/notification_channel_ids.dart';

void main() {
  group('NotificationChannelIds', () {
    test('all channel IDs are unique', () {
      final ids = {
        NotificationChannelIds.general,
        NotificationChannelIds.dailyReminder,
        NotificationChannelIds.revision,
        NotificationChannelIds.wellbeing,
        NotificationChannelIds.planning,
        NotificationChannelIds.lessons,
        NotificationChannelIds.mastery,
        NotificationChannelIds.badges,
      };
      expect(ids.length, 8);
    });

    test('all channel IDs follow studyking_ prefix format', () {
      for (final id in [
        NotificationChannelIds.general,
        NotificationChannelIds.dailyReminder,
        NotificationChannelIds.revision,
        NotificationChannelIds.wellbeing,
        NotificationChannelIds.planning,
        NotificationChannelIds.lessons,
        NotificationChannelIds.mastery,
        NotificationChannelIds.badges,
      ]) {
        expect(id, startsWith('studyking_'));
        expect(id.length, greaterThan('studyking_'.length));
      }
    });
  });
}
