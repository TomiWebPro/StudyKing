import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/plan_adherence_repository.dart';
import 'package:studyking/core/services/instrumentation_service.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';

final dashboardTopicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository();
});

final dashboardAttemptRepositoryProvider = Provider<AttemptRepository>((ref) {
  return AttemptRepository();
});

final dashboardStudyProgressTrackerProvider = Provider<StudyProgressTracker>((ref) {
  return StudyProgressTracker(
    attemptRepo: ref.read(dashboardAttemptRepositoryProvider),
  );
});

final dashboardInstrumentationServiceProvider = Provider<InstrumentationService>((ref) {
  return InstrumentationService();
});

final dashboardAdherenceRepositoryProvider = Provider<PlanAdherenceRepository>((ref) {
  return PlanAdherenceRepository();
});
