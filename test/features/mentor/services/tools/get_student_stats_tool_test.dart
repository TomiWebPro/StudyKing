import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/study_progress_tracker.dart';
import 'package:studyking/features/mentor/services/tools/get_student_stats_tool.dart';
import '../../../../helpers/fakes.dart';

T _required<T>() => throw UnimplementedError('stub not overridden');

class FakeStudyProgressTracker extends StudyProgressTracker {
  Map<String, dynamic> _stats = {};
  String? capturedStudentId;

  FakeStudyProgressTracker()
      : super(
          attemptRepo: _required(),
          l10n: _required(),
        );

  void setStats(Map<String, dynamic> stats) => _stats = stats;

  @override
  Future<Result<Map<String, dynamic>>> getOverallStats(String studentId) async {
    capturedStudentId = studentId;
    return Result.success(_stats);
  }
}

void main() {
  group('GetStudentStatsTool', () {
    late FakeStudyProgressTracker fakeTracker;
    late FakeStudentIdService fakeStudentId;
    late GetStudentStatsTool tool;

    setUp(() {
      fakeTracker = FakeStudyProgressTracker();
      fakeStudentId = FakeStudentIdService()..setStudentId('student-42');
      tool = GetStudentStatsTool(
        progressTracker: fakeTracker,
        studentIdService: fakeStudentId,
      );
    });

    test('name returns get_student_stats', () {
      expect(tool.name, 'get_student_stats');
    });

    test('description is not empty', () {
      expect(tool.description, isNotEmpty);
    });

    test('parameters has correct JSON schema shape', () {
      final params = tool.parameters;
      expect(params['type'], 'object');
      expect((params['properties'] as Map), isEmpty);
      expect(params['required'], []);
    });

    test('execute returns all stat fields from progress tracker', () async {
      fakeTracker.setStats({
        'totalAttempts': 100,
        'correctAttempts': 75,
        'accuracy': 75,
        'topicsStudied': 8,
        'weeklyActivity': 12,
        'totalStudyTimeHours': 15.5,
      });

      final result = await tool.execute({});

      expect(result['totalAttempts'], 100);
      expect(result['correctAttempts'], 75);
      expect(result['accuracy'], 75);
      expect(result['topicsStudied'], 8);
      expect(result['weeklyActivity'], 12);
      expect(result['totalStudyTimeHours'], 15.5);
    });

    test('execute defaults missing stat fields to zero', () async {
      fakeTracker.setStats({});

      final result = await tool.execute({});

      expect(result['totalAttempts'], 0);
      expect(result['correctAttempts'], 0);
      expect(result['accuracy'], 0);
      expect(result['topicsStudied'], 0);
      expect(result['weeklyActivity'], 0);
      expect(result['totalStudyTimeHours'], 0);
    });

    test('execute uses studentId from StudentIdService', () async {
      await tool.execute({});

      expect(fakeTracker.capturedStudentId, 'student-42');
    });

    test('execute handles partial stats gracefully', () async {
      fakeTracker.setStats({
        'totalAttempts': 50,
        'accuracy': 80,
      });

      final result = await tool.execute({});

      expect(result['totalAttempts'], 50);
      expect(result['accuracy'], 80);
      expect(result['correctAttempts'], 0);
      expect(result['topicsStudied'], 0);
      expect(result['weeklyActivity'], 0);
      expect(result['totalStudyTimeHours'], 0);
    });

    test('execute handles negative values from tracker', () async {
      fakeTracker.setStats({
        'totalAttempts': -1,
        'correctAttempts': -1,
        'accuracy': -1,
        'topicsStudied': -1,
        'weeklyActivity': -1,
        'totalStudyTimeHours': -1.0,
      });

      final result = await tool.execute({});

      expect(result['totalAttempts'], -1);
      expect(result['correctAttempts'], -1);
      expect(result['accuracy'], -1);
      expect(result['topicsStudied'], -1);
      expect(result['weeklyActivity'], -1);
      expect(result['totalStudyTimeHours'], -1.0);
    });
  });
}
