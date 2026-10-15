import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/utils/logger.dart';

/// Persists the student's preparation budget as raw keys under the settings
/// box (vision Next-Term §4.2 "Preparation budget" settings surface).
///
/// Stored keys (all under [HiveBoxNames.settings]):
///  - `prepBudgetEnabled` : bool, the "Prepare while I'm away" master switch.
///  - `prepBudgetCaps`    : `Map<String,int>` from [PrepCategory.taskTypeKey]
///    to a token cap. Missing categories fall back to [PrepBudget.defaults].
///
/// Using raw keys (rather than HiveFields on [SettingsBox]) keeps this
/// opt-in feature decoupled from the SettingsBox adapter generation and the
/// legacy migration path used by [SettingsRepository].
class PrepBudgetRepository {
  static final Logger _logger = const Logger('PrepBudgetRepository');
  static const String _enabledKey = 'prepBudgetEnabled';
  static const String _capsKey = 'prepBudgetCaps';

  Box? _box;

  /// Opens the settings box if it is not already open. Safe to call repeatedly.
  Future<Result<void>> init() async {
    if (_box != null && _box!.isOpen) return Result.success(null);
    try {
      _box = Hive.isBoxOpen(HiveBoxNames.settings)
          ? Hive.box(HiveBoxNames.settings)
          : await Hive.openBox(HiveBoxNames.settings);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to open settings box for prep budget', e);
      _box = null;
      return Result.failure('Failed to open settings box: $e');
    }
  }

  /// Loads the persisted budget, falling back to [PrepBudget.defaults] on any
  /// I/O issue so the Settings surface always has something to render.
  Result<PrepBudget> load() {
    final box = _box;
    if (box == null || !box.isOpen) {
      return Result.success(PrepBudget.defaults);
    }
    try {
      final enabled = box.get(_enabledKey, defaultValue: true) as bool? ?? true;
      final stored = box.get(_capsKey);
      final caps = <PrepCategory, int>{};
      for (final category in PrepCategory.values) {
        final storedCap = stored is Map
            ? (stored[category.taskTypeKey] is num
                ? (stored[category.taskTypeKey] as num).toInt()
                : (PrepBudget.defaults.caps[category] ?? 0))
            : (PrepBudget.defaults.caps[category] ?? 0);
        caps[category] = storedCap;
      }
      return Result.success(PrepBudget(enabled: enabled, caps: caps));
    } catch (e) {
      _logger.w('Failed to load prep budget from settings box', e);
      return Result.success(PrepBudget.defaults);
    }
  }

  /// Persists the given [budget]. Returns a failure if the settings box is not
  /// available, so callers can decide whether to surface an error.
  Future<Result<void>> save(PrepBudget budget) async {
    final box = _box;
    if (box == null || !box.isOpen) {
      return Result.failure('PrepBudgetRepository: settings box not open');
    }
    try {
      final caps = <String, int>{
        for (final category in PrepCategory.values)
          category.taskTypeKey: budget.caps[category] ?? 0,
      };
      await box.put(_enabledKey, budget.enabled);
      await box.put(_capsKey, caps);
      return Result.success(null);
    } catch (e) {
      _logger.w('Failed to persist prep budget', e);
      return Result.failure('Failed to persist prep budget: $e');
    }
  }
}
