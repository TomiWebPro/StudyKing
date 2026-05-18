import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/engagement_nudge_model.dart';
import 'package:studyking/features/planner/data/repositories/engagement_nudge_repository.dart';

class _FakeNudgeRepo extends EngagementNudgeRepository {
  final List<EngagementNudgeModel> _nudges = [];
  bool shouldThrow = false;

  @override
  Future<Result<void>> create(EngagementNudgeModel nudge) async {
    if (shouldThrow) return Result.failure('nudge error');
    _nudges.add(nudge);
    return Result.success(null);
  }

  @override
  Future<Result<List<EngagementNudgeModel>>> getRecentByStudent(
      String studentId, {int limit = 10}) async {
    if (shouldThrow) return Result.failure('get error');
    return Result.success(_nudges);
  }

  @override
  Future<void> init() async {}
}

void main() {
  group('Planner → Mentor nudges integration', () {
    test('nudge repo creates and retrieves engagement nudges', () async {
      final nudgeRepo = _FakeNudgeRepo();

      final nudge = EngagementNudgeModel(
        id: 'nudge-1',
        studentId: 'student-1',
        nudgeType: 'adherence',
        message: 'Your study adherence needs attention',
      );
      final createResult = await nudgeRepo.create(nudge);
      expect(createResult.isSuccess, isTrue);

      final recentNudges = await nudgeRepo.getRecentByStudent('student-1');
      expect(recentNudges.isSuccess, isTrue);
      expect(recentNudges.data!.length, 1);
      expect(recentNudges.data!.first.nudgeType, 'adherence');
    });

    test('handles error when nudge repo is unavailable', () async {
      final nudgeRepo = _FakeNudgeRepo();
      nudgeRepo.shouldThrow = true;

      final nudge = EngagementNudgeModel(
        id: 'nudge-err',
        studentId: 'student-1',
        nudgeType: 'motivation',
        message: 'Test nudge',
      );
      final result = await nudgeRepo.create(nudge);
      expect(result.isFailure, isTrue);
    });

    test('recovers after nudge repo error', () async {
      final nudgeRepo = _FakeNudgeRepo();
      nudgeRepo.shouldThrow = true;

      await nudgeRepo.create(EngagementNudgeModel(
        id: 'nudge-err1',
        studentId: 'student-1',
        nudgeType: 'adherence',
        message: 'Error nudge',
      ));

      nudgeRepo.shouldThrow = false;
      final result = await nudgeRepo.create(EngagementNudgeModel(
        id: 'nudge-recovery',
        studentId: 'student-1',
        nudgeType: 'motivation',
        message: 'Recovery nudge',
      ));
      expect(result.isSuccess, isTrue);

      final nudges = await nudgeRepo.getRecentByStudent('student-1');
      expect(nudges.data!.length, 1);
      expect(nudges.data!.first.nudgeType, 'motivation');
    });
  });
}
