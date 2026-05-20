import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/utils/logger.dart';

abstract class OnboardingStorage {
  Future<bool> getBool(String key, {bool defaultValue = false});
  Future<void> setBool(String key, bool value);
}

class HiveOnboardingStorage implements OnboardingStorage {
  static final _logger = const Logger('HiveOnboardingStorage');

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    try {
      final box = await Hive.openBox(HiveBoxNames.settings);
      return box.get(key, defaultValue: defaultValue) as bool;
    } catch (e) {
      _logger.w('Failed to read onboarding key', e);
      return true;
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    try {
      final box = await Hive.openBox(HiveBoxNames.settings);
      await box.put(key, value);
    } catch (e) {
      _logger.w('Failed to write onboarding key', e);
    }
  }
}

class InMemoryOnboardingStorage implements OnboardingStorage {
  final Map<String, dynamic> _store;

  InMemoryOnboardingStorage([Map<String, bool>? initial])
      : _store = Map<String, dynamic>.from(initial ?? {});

  Map<String, dynamic> get store => _store;

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    return _store[key] as bool? ?? defaultValue;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    _store[key] = value;
  }
}
