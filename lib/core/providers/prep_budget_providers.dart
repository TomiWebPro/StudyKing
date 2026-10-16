import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/services/prep_budget_repository.dart';
import 'package:studyking/core/utils/logger.dart';

/// Lazily-created persistence layer for the student's preparation budget.
/// Override this in tests with a hand-written fake to avoid Hive I/O.
final prepBudgetRepositoryProvider = Provider<PrepBudgetRepository>((ref) {
  return PrepBudgetRepository();
});

/// Live, persisted [PrepBudget] the student edits from Settings.
///
/// Holds the "Prepare while I'm away" master switch plus per-category token
/// caps. Edits are written through [PrepBudgetRepository] so they survive app
/// restarts (vision Next-Term §4.2).
final prepBudgetSettingsProvider =
    StateNotifierProvider<PrepBudgetSettingsController, PrepBudget>((ref) {
  return PrepBudgetSettingsController(ref.watch(prepBudgetRepositoryProvider));
});

class PrepBudgetSettingsController extends StateNotifier<PrepBudget> {
  static final Logger _logger = const Logger('PrepBudgetSettingsController');
  final PrepBudgetRepository _repository;
  bool _initialized = false;

  PrepBudgetSettingsController(this._repository) : super(PrepBudget.defaults) {
    _load();
  }

  Future<void> _load() async {
    if (_initialized) return;
    _initialized = true;
    final initResult = await _repository.init();
    if (initResult.isFailure) {
      _logger.w('Prep budget repository init failed: ${initResult.error}');
    }
    final result = _repository.load();
    if (result.isSuccess && result.data != null) {
      state = result.data!;
    } else {
      _logger.w('Failed to load prep budget: ${result.error}');
    }
  }

  /// Toggles the "Prepare while I'm away" master switch.
  Future<void> setEnabled(bool value) async {
    final updated = state.copyWith(enabled: value);
    state = updated;
    final result = await _repository.save(updated);
    if (result.isFailure) {
      _logger.w('Failed to persist prep budget: ${result.error}');
    }
  }

  /// Sets an absolute token cap for [category].
  Future<void> setCategoryCap(PrepCategory category, int tokens) async {
    final updated = state.copyWith(caps: {
      for (final c in PrepCategory.values) c: c == category ? tokens : (state.caps[c] ?? 0),
    });
    state = updated;
    final result = await _repository.save(updated);
    if (result.isFailure) {
      _logger.w('Failed to persist prep budget: ${result.error}');
    }
  }

  /// Sets a category cap from a percentage of [PrepBudget.referenceTotalTokens].
  Future<void> setCategoryPercent(PrepCategory category, int percent) =>
      setCategoryCap(category, (percent.clamp(0, 100) / 100 * PrepBudget.referenceTotalTokens).round());

  /// Configures the quiet-hours window (vision §4.2). Pass null for either
  /// hour to disable quiet hours. Hours are clamped to 0–23.
  Future<void> setQuietHours({int? startHour, int? endHour}) async {
    // Build directly rather than via copyWith: the ?? cascade in copyWith
    // treats an explicit null as "keep current value", so passing null here
    // (i.e. clearing quiet hours) would be silently ignored. Constructing the
    // PrepBudget explicitly ensures null means null.
    final updated = PrepBudget(
      enabled: state.enabled,
      caps: Map<PrepCategory, int>.of(state.caps),
      quietHoursStart: startHour != null ? startHour.clamp(0, 23) : null,
      quietHoursEnd: endHour != null ? endHour.clamp(0, 23) : null,
      disabledSubjects: Set<String>.of(state.disabledSubjects),
    );
    state = updated;
    final result = await _repository.save(updated);
    if (result.isFailure) {
      _logger.w('Failed to persist quiet hours: ${result.error}');
    }
  }

  /// Toggles per-subject preparation opt-in (vision §4.2 "per-syllabus opt-in").
  /// When [enabled] is false the subject is added to the disabled set;
  /// when true it is removed.
  Future<void> setSubjectPrepEnabled(String subjectId, bool enabled) async {
    final current = Set<String>.of(state.disabledSubjects);
    if (enabled) {
      current.remove(subjectId);
    } else {
      current.add(subjectId);
    }
    final updated = state.copyWith(disabledSubjects: current);
    state = updated;
    final result = await _repository.save(updated);
    if (result.isFailure) {
      _logger.w('Failed to persist subject prep preference: ${result.error}');
    }
  }
}

/// Prepares the live [PrepBudgetService] from the student's persisted budget
/// and the live [LlmUsageMeter], so the Settings surface and the task-manager
/// portal can show spend-per-category counters and remaining budget bars.
final prepBudgetServiceProvider = Provider<PrepBudgetService>((ref) {
  return PrepBudgetService(
    meter: ref.watch(llmUsageMeterProvider),
    budget: ref.watch(prepBudgetSettingsProvider),
  );
});
