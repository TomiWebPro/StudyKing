import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/data/models/topic_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/presentation/widgets/study_plan_tab.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/providers/subject_repository_provider.dart';
import 'package:studyking/features/subjects/providers/topic_repository_provider.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../helpers/locale_switch_harness.dart';

class _FakePlannerService extends PlannerService {
  _FakePlannerService() : super(lessonAgentService: null, localeName: 'en');

  @override
  Future<Result<PersonalLearningPlan?>> loadExistingPlan() async {
    return Result.success(null);
  }

  @override
  Future<Result<List<RoadmapModel>>> loadRoadmaps() async {
    return Result.success([]);
  }

  @override
  Future<Result<List<PendingActionModel>>> loadPendingActions() async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Session>>> getScheduledLessons() async {
    return Result.success([]);
  }

  @override
  Future<Result<List<Session>>> getMissedLessons() async {
    return Result.success([]);
  }

  @override
  Future<Result<Map<String, int>>> getAdherenceMetrics() async {
    return Result.success({});
  }

  @override
  Future<Result<List<PlanAdherenceModel>>> getAdherenceRecords() async {
    return Result.success([]);
  }
}

Widget buildApp(Widget widget) {
  return ProviderScope(
    overrides: [
      plannerServiceProvider.overrideWithValue(_FakePlannerService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: widget),
    ),
  );
}

class _ThrowingSubjectRepository extends SubjectRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Subject>>> getAll() async {
    throw Exception('Failed to load subjects');
  }
}

void main() {
  group('StudyPlanTab', () {
    testWidgets('shows create study plan title', (tester) async {
      await tester.pumpWidget(buildApp(const StudyPlanTab()));

      expect(find.text('Create Study Plan'), findsOneWidget);
    });

    testWidgets('shows generate plan button', (tester) async {
      await tester.pumpWidget(buildApp(const StudyPlanTab()));

      expect(find.text('Generate Plan'), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildApp(const StudyPlanTab()));

      expect(tester.takeException(), isNull);
    });
  });

  group('StudyPlanTab - locale switch', () {
    testWidgets('subjects error banner follows locale switch',
        (tester) async {
      final harnessKey = GlobalKey<LocaleSwitchHarnessState>();
      await tester.pumpWidget(LocaleSwitchHarness(
        key: harnessKey,
        child: ProviderScope(
          overrides: [
            plannerServiceProvider.overrideWithValue(_FakePlannerService()),
            subjectRepositoryProvider.overrideWithValue(
              _ThrowingSubjectRepository(),
            ),
          ],
          child: Scaffold(
            body: const StudyPlanTab(),
          ),
        ),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);

      harnessKey.currentState!.switchLocale(const Locale('es'));
      await tester.pumpAndSettle();

      expect(find.text('Algo salió mal'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });
  });
}
