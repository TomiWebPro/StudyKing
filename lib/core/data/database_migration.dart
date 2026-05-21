import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';
import 'hive_box_names.dart';

class DatabaseMigration {
  static final Logger _logger = const Logger('DatabaseMigration');
  static const String versionBoxName = HiveBoxNames.dbVersion;
  static const int currentVersionNum = 1;

  static Future<void> runMigrations() async {
    if (!Hive.isBoxOpen(versionBoxName)) {
      await Hive.openBox(versionBoxName);
    }

    await Hive.box(versionBoxName).put('version', currentVersionNum);
    _logger.i('Database version set to $currentVersionNum');
  }

  static Future<DatabaseValidationResult> validateSchema() async {
    try {
      final boxes = [
        HiveBoxNames.topics,
        HiveBoxNames.questions,
        HiveBoxNames.answers,
        HiveBoxNames.sources,
        HiveBoxNames.attempts,
        HiveBoxNames.lessons,
        HiveBoxNames.sessions,
      ];

      final missingBoxes = <String>[];
      for (final boxName in boxes) {
        try {
          await Hive.openBox(boxName);
        } catch (e) {
          _logger.w('Failed to open box "$boxName"', e);
          missingBoxes.add(boxName);
        }
      }

      return DatabaseValidationResult(
        isValid: missingBoxes.isEmpty,
        missingBoxes: missingBoxes,
        currentVersion: Hive.box(versionBoxName).get('version', defaultValue: 0),
      );
    } catch (e) {
      return DatabaseValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }
}

class DatabaseValidationResult {
  final bool isValid;
  final List<String> missingBoxes;
  final int currentVersion;
  final String? error;

  DatabaseValidationResult({
    this.isValid = true,
    this.missingBoxes = const [],
    this.currentVersion = 0,
    this.error,
  });

  bool get hasErrors => error != null || !isValid || missingBoxes.isNotEmpty;
}
