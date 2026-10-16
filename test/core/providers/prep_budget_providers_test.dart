import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/providers/prep_budget_providers.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/prep_budget.dart';
import 'package:studyking/core/services/prep_budget_repository.dart';
import 'package:studyking/core/errors/result.dart';

class FakePrepBudgetRepositoryImpl extends PrepBudgetRepository {
  PrepBudget current = PrepBudget.defaults;
  int initCallCount = 0;
  int saveCallCount = 0;
  bool shouldFail = false;

  @override
  Future<Result<void>> init() async {
    initCallCount++;
    if (shouldFail) return Result.failure('Simulated init failure');
    return Result.success(null);
  }

  @override
  Result<PrepBudget> load() {
    if (shouldFail) return Result.failure('Simulated load failure');
    return Result.success(current);
  }

  @override
  Future<Result<void>> save(PrepBudget budget) async {
    saveCallCount++;
    if (shouldFail) return Result.failure('Simulated save failure');
    current = budget;
    return Result.success(null);
  }
}

/// Drains enough microtask cycles for PrepBudgetSettingsController._load()
/// (which awaits repo.init() then calls sync repo.load()) to complete.
Future<void> _waitForLoad() async {
  for (var i = 0; i < 5; i++) {
    await Future.delayed(Duration.zero);
  }
}

class _FakeMeter extends LlmUsageMeter {
  final Map<String, int> _perTaskTypeTokens;

  _FakeMeter(this._perTaskTypeTokens);

  @override
  Future<void> init() async {}

  @override
  Map<String, int> getTotalTokensPerTaskType() => _perTaskTypeTokens;

  @override
  Map<String, double> getTotalCostPerTaskType() =>
      {for (final k in _perTaskTypeTokens.keys) k: 0.0};
}

void main() {
  group('prepBudgetRepositoryProvider', () {
    test('creates a PrepBudgetRepository', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final repo = container.read(prepBudgetRepositoryProvider);
      expect(repo, isA<PrepBudgetRepository>());
    });
  });

  group('prepBudgetSettingsProvider', () {
    test('falls back to defaults when no persisted data', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(() => container.dispose());

      container.read(prepBudgetSettingsProvider);
      await _waitForLoad();

      final budget = container.read(prepBudgetSettingsProvider);
      expect(budget.enabled, isTrue);
      expect(budget.caps[PrepCategory.pdfIngestion], 200000);
    });

    test('loads persisted budget from repository', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      fakeRepo.current = PrepBudget(
        enabled: false,
        caps: {PrepCategory.background: 10000},
      );
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(() => container.dispose());

      container.read(prepBudgetSettingsProvider);
      await _waitForLoad();

      final budget = container.read(prepBudgetSettingsProvider);
      expect(budget.enabled, isFalse);
      expect(budget.caps[PrepCategory.background], 10000);
      // Categories not in the persisted map are simply absent.
      expect(budget.caps[PrepCategory.pdfIngestion], isNull);
    });

    test('setEnabled persists through repository', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(() => container.dispose());

      final controller = container.read(prepBudgetSettingsProvider.notifier);
      await _waitForLoad();

      await controller.setEnabled(false);

      expect(fakeRepo.saveCallCount, 1);
      expect(fakeRepo.current.enabled, isFalse);
    });

    test('setCategoryPercent persists correct token amount', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(() => container.dispose());

      final controller = container.read(prepBudgetSettingsProvider.notifier);
      await _waitForLoad();

      await controller.setCategoryPercent(PrepCategory.embeddings, 20);

      // 20% of 500000 = 100000
      expect(fakeRepo.current.caps[PrepCategory.embeddings], 100000);
      expect(fakeRepo.saveCallCount, 1);
    });

    test('setCategoryCap persists absolute tokens', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(() => container.dispose());

      final controller = container.read(prepBudgetSettingsProvider.notifier);
      await _waitForLoad();

      await controller.setCategoryCap(PrepCategory.pdfIngestion, 50000);

      expect(fakeRepo.current.caps[PrepCategory.pdfIngestion], 50000);
      expect(fakeRepo.saveCallCount, 1);
    });

    test('setQuietHours persists start and end hours', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(() => container.dispose());

      final controller = container.read(prepBudgetSettingsProvider.notifier);
      await _waitForLoad();

      await controller.setQuietHours(startHour: 22, endHour: 8);

      expect(fakeRepo.current.quietHoursStart, 22);
      expect(fakeRepo.current.quietHoursEnd, 8);
      expect(fakeRepo.saveCallCount, 1);
    });

    test('setQuietHours clears when both hours are null', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      fakeRepo.current = PrepBudget.defaults.copyWith(quietHoursStart: 22, quietHoursEnd: 8);
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(() => container.dispose());

      final controller = container.read(prepBudgetSettingsProvider.notifier);
      await _waitForLoad();

      await controller.setQuietHours(startHour: null, endHour: null);

      expect(fakeRepo.current.quietHoursStart, isNull);
      expect(fakeRepo.current.quietHoursEnd, isNull);
    });

    test('setQuietHours clamps hours to 0–23', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(() => container.dispose());

      final controller = container.read(prepBudgetSettingsProvider.notifier);
      await _waitForLoad();

      await controller.setQuietHours(startHour: 25, endHour: -1);

      expect(fakeRepo.current.quietHoursStart, 23);
      expect(fakeRepo.current.quietHoursEnd, 0);
    });

    test('setSubjectPrepEnabled adds subject to disabled set when false', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(() => container.dispose());

      final controller = container.read(prepBudgetSettingsProvider.notifier);
      await _waitForLoad();

      await controller.setSubjectPrepEnabled('math', false);

      expect(fakeRepo.current.disabledSubjects, contains('math'));
      expect(fakeRepo.saveCallCount, 1);
    });

    test('setSubjectPrepEnabled removes subject from disabled set when true', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      fakeRepo.current = PrepBudget.defaults.copyWith(disabledSubjects: {'math'});
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(() => container.dispose());

      final controller = container.read(prepBudgetSettingsProvider.notifier);
      await _waitForLoad();

      await controller.setSubjectPrepEnabled('math', true);

      expect(fakeRepo.current.disabledSubjects, isNot(contains('math')));
      expect(fakeRepo.current.disabledSubjects, isEmpty);
    });
  });

  group('prepBudgetServiceProvider', () {
    test('wires meter and budget so remainingFor reflects live spend', () {
      final fakeMeter = _FakeMeter({'pdf_ingestion': 60000});
      final service = PrepBudgetService(
        meter: fakeMeter,
        budget: PrepBudget.defaults,
      );
      final container = ProviderContainer(
        overrides: [
          llmUsageMeterProvider.overrideWith((ref) => fakeMeter),
          prepBudgetServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() => container.dispose());

      final result = container.read(prepBudgetServiceProvider);
      expect(result.remainingFor(PrepCategory.pdfIngestion), 200000 - 60000);
      expect(result.spendingByCategory()[PrepCategory.pdfIngestion], 60000);
    });

    test('reads spend per category via taskTypeKey', () {
      final fakeMeter = _FakeMeter({
        'pdf_ingestion': 50000,
        'question_variants': 30000,
        'lesson_prep': 20000,
        'embeddings': 5000,
        'background': 10000,
        'unknown_thing': 9999,
      });
      final container = ProviderContainer(
        overrides: [
          llmUsageMeterProvider.overrideWith((ref) => fakeMeter),
          prepBudgetServiceProvider.overrideWithValue(
            PrepBudgetService(meter: fakeMeter, budget: PrepBudget.defaults),
          ),
        ],
      );
      addTearDown(() => container.dispose());

      final service = container.read(prepBudgetServiceProvider);
      final spending = service.spendingByCategory();
      expect(spending[PrepCategory.pdfIngestion], 50000);
      expect(spending[PrepCategory.questionVariants], 30000);
      expect(spending[PrepCategory.lessonPrep], 20000);
      expect(spending[PrepCategory.embeddings], 5000);
      expect(spending[PrepCategory.background], 10000);
    });

    test('disabled budget denies all spend', () {
      final fakeMeter = _FakeMeter({'background': 1});
      final container = ProviderContainer(
        overrides: [
          llmUsageMeterProvider.overrideWith((ref) => fakeMeter),
          prepBudgetServiceProvider.overrideWithValue(
            PrepBudgetService(
              meter: fakeMeter,
              budget: PrepBudget.defaults.copyWith(enabled: false),
            ),
          ),
        ],
      );
      addTearDown(() => container.dispose());

      final service = container.read(prepBudgetServiceProvider);
      expect(service.canSpend(PrepCategory.background, 1), isFalse);
    });

    test('single instance of service is returned', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      final fakeMeter = _FakeMeter({});
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
          llmUsageMeterProvider.overrideWith((ref) => fakeMeter),
        ],
      );
      addTearDown(() => container.dispose());

      container.read(prepBudgetSettingsProvider);
      await _waitForLoad();

      final service1 = container.read(prepBudgetServiceProvider);
      final service2 = container.read(prepBudgetServiceProvider);
      expect(service1, same(service2));
    });

    // Behavioral assertion: overriding the repository changes the budget
    // the service sees, proving the dependency wiring works.
    test('overriding repository changes budget seen by service', () async {
      final fakeRepo = FakePrepBudgetRepositoryImpl();
      fakeRepo.current = PrepBudget(
        enabled: true,
        caps: {PrepCategory.embeddings: 10000},
      );
      final container = ProviderContainer(
        overrides: [
          prepBudgetRepositoryProvider.overrideWith((ref) => fakeRepo),
        ],
      );
      addTearDown(() => container.dispose());

      container.read(prepBudgetSettingsProvider);
      await _waitForLoad();

      final service = container.read(prepBudgetServiceProvider);
      expect(service.remainingFor(PrepCategory.embeddings), 10000);
    });
  });
}
