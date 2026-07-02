import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/pending_action_model.dart';
import 'package:studyking/features/planner/data/models/personal_learning_plan_model.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';
import 'package:studyking/features/planner/data/models/roadmap_model.dart';
import 'package:studyking/features/planner/providers/planner_providers.dart';
import 'package:studyking/features/planner/presentation/widgets/subject_progress_tabs.dart';
import 'package:studyking/features/planner/services/planner_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

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

void main() {
  group('SubjectProgressTabs', () {
    testWidgets('returns SizedBox.shrink when plan is null', (tester) async {
      await tester.pumpWidget(buildApp(const SubjectProgressTabs()));

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildApp(const SubjectProgressTabs()));

      expect(tester.takeException(), isNull);
    });
  });
}
