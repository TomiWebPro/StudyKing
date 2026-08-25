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
}
