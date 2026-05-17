import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/dashboard/services/dashboard_service.dart';

class _SimpleFakeMasteryService extends MasteryGraphService {
  _SimpleFakeMasteryService() : super(
    repository: null,
    masteryStateRepo: null,
    questionMasteryRepo: null,
    topicDependencyRepo: null,
    questionEvaluationRepo: null,
    calculationService: null,
  );

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<MasteryState>>> getAllTopicMastery(String studentId) async {
    return Result.success([]);
  }

  @override
  Future<Result<Map<String, dynamic>>> getMasterySnapshot(String studentId) async {
    return Result.success({'overallAccuracy': 0.75, 'totalMastered': 5, 'totalTopics': 10});
  }
}

void main() {
  group('DashboardService', () {
    test('can be constructed with minimal dependencies', () {
      expect(
        () => DashboardService(
          masteryService: _SimpleFakeMasteryService(),
        ),
        returnsNormally,
      );
    });

    test('getAllTopicMastery returns empty list when no mastery states', () async {
      final service = DashboardService(
        masteryService: _SimpleFakeMasteryService(),
      );
      final result = await service.getAllTopicMastery('student1');
      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });

    test('getMasterySnapshot returns snapshot data', () async {
      final service = DashboardService(
        masteryService: _SimpleFakeMasteryService(),
      );
      final result = await service.getMasterySnapshot('student1');
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
    });
  });
}
