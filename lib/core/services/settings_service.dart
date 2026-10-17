import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/study_utils.dart';

class SettingsService {
  static final Logger _logger = const Logger('SettingsService');

  static int getDailyCapMinutes() {
    if (!Hive.isBoxOpen(HiveBoxNames.settings)) return 0;
    try {
      final box = Hive.box(HiveBoxNames.settings);
      return box.get('dailyCapMinutes', defaultValue: 0) as int;
    } catch (e) {
      _logger.w('getDailyCapMinutes failed, defaulting to 0', e);
      return 0;
    }
  }

  static int getMentorCheckinFrequency() {
    if (!Hive.isBoxOpen(HiveBoxNames.settings)) return 1;
    try {
      final box = Hive.box(HiveBoxNames.settings);
      return box.get('mentorCheckinFrequencyDays', defaultValue: 1) as int;
    } catch (e) {
      _logger.w('getMentorCheckinFrequency failed, defaulting to 1', e);
      return 1;
    }
  }

  static int getScheduleDurationMinutes() {
    if (!Hive.isBoxOpen(HiveBoxNames.settings)) return defaultSessionDurationMinutes;
    try {
      final box = Hive.box(HiveBoxNames.settings);
      final stored = box.get('defaultScheduleDuration', defaultValue: defaultSessionDurationMinutes) as int;
      return stored > 0 && stored <= 480 ? stored : defaultSessionDurationMinutes;
    } catch (e) {
      _logger.w('getScheduleDurationMinutes failed, defaulting to $defaultSessionDurationMinutes', e);
      return defaultSessionDurationMinutes;
    }
  }

  static int getTeachingDurationMinutes() {
    if (!Hive.isBoxOpen(HiveBoxNames.settings)) return 45;
    try {
      final box = Hive.box(HiveBoxNames.settings);
      final stored = box.get('defaultTeachingDuration', defaultValue: 45) as int;
      return stored > 0 && stored <= 480 ? stored : 45;
    } catch (e) {
      _logger.w('getTeachingDurationMinutes failed, defaulting to 45', e);
      return 45;
    }
  }

  /// Wellbeing reminder keys stored in the settings box as a JSON-encoded list.
  /// Each entry is a map with `reminderType` (bedtime|break|pacing), `time`
  /// (HH:MM), `enabled` (bool), and optional `note` (String).
  static const String _wellbeingRemindersKey = 'wellbeing_reminders';

  /// Reads all persisted wellbeing reminders from the settings box.
  /// Returns an empty list when the box is closed or the key is absent.
  static List<Map<String, dynamic>> getWellbeingReminders() {
    if (!Hive.isBoxOpen(HiveBoxNames.settings)) return [];
    try {
      final box = Hive.box(HiveBoxNames.settings);
      final raw = box.get(_wellbeingRemindersKey);
      if (raw is List) {
        return raw
            .cast<Map<dynamic, dynamic>>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.w('getWellbeingReminders failed, returning empty list', e);
      return [];
    }
  }

  /// Adds or replaces a wellbeing reminder. If a reminder with the same
  /// `reminderType` already exists it is updated in place; otherwise the
  /// new reminder is appended.
  static Future<bool> saveWellbeingReminder(Map<String, dynamic> reminder) async {
    if (!Hive.isBoxOpen(HiveBoxNames.settings)) return false;
    try {
      final box = Hive.box(HiveBoxNames.settings);
      final existing = getWellbeingReminders();
      final reminderType = reminder['reminderType'] as String? ?? '';
      existing.removeWhere(
        (r) => (r['reminderType'] as String? ?? '') == reminderType,
      );
      existing.add(reminder);
      await box.put(_wellbeingRemindersKey, existing);
      return true;
    } catch (e) {
      _logger.w('saveWellbeingReminder failed to persist reminder', e);
      return false;
    }
  }
}
