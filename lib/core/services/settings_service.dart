import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/study_utils.dart';

class SettingsService {
  static int getDailyCapMinutes() {
    final result = Result.captureSync(() {
      if (!Hive.isBoxOpen(HiveBoxNames.settings)) return 0;
      final box = Hive.box(HiveBoxNames.settings);
      return box.get('dailyCapMinutes', defaultValue: 0) as int;
    }, context: 'SettingsService.getDailyCapMinutes');
    return result.data ?? 0;
  }

  static int getMentorCheckinFrequency() {
    final result = Result.captureSync(() {
      if (!Hive.isBoxOpen(HiveBoxNames.settings)) return 1;
      final box = Hive.box(HiveBoxNames.settings);
      return box.get('mentorCheckinFrequencyDays', defaultValue: 1) as int;
    }, context: 'SettingsService.getMentorCheckinFrequency');
    return result.data ?? 1;
  }

  static int getScheduleDurationMinutes() {
    final result = Result.captureSync(() {
      if (!Hive.isBoxOpen(HiveBoxNames.settings)) return defaultSessionDurationMinutes;
      final box = Hive.box(HiveBoxNames.settings);
      final stored = box.get('defaultScheduleDuration', defaultValue: defaultSessionDurationMinutes) as int;
      return stored > 0 && stored <= 480 ? stored : defaultSessionDurationMinutes;
    }, context: 'SettingsService.getScheduleDurationMinutes');
    return result.data ?? defaultSessionDurationMinutes;
  }

  static int getTeachingDurationMinutes() {
    final result = Result.captureSync(() {
      if (!Hive.isBoxOpen(HiveBoxNames.settings)) return 45;
      final box = Hive.box(HiveBoxNames.settings);
      final stored = box.get('defaultTeachingDuration', defaultValue: 45) as int;
      return stored > 0 && stored <= 480 ? stored : 45;
    }, context: 'SettingsService.getTeachingDurationMinutes');
    return result.data ?? 45;
  }
}
