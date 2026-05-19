import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/mentor/services/tools/get_weak_topics_tool.dart';
import 'package:studyking/features/practice/data/models/mastery_state_model.dart';
import 'package:studyking/features/practice/data/models/question_mastery_state_model.dart';
import '../../../../helpers/fakes.dart';

class FakeMasteryGraphService extends MasteryGraphService {
  Result<List<MasteryState>>? _weakTopicsResult;
  Result<List<QuestionMasteryState>>? _atRiskResult;
  String? capturedStudentId;

  FakeMasteryGraphService();

  void setWeakTopics(Result<List<MasteryState>> result) => _weakTopicsResult = result;
  void setAtRiskQuestions(Result<List<QuestionMasteryState>> result) => _atRiskResult = result;

  @override
  Future<Result<List<MasteryState>>> getWeakTopics(String studentId) async {
    capturedStudentId = studentId;
    return _weakTopicsResult ?? Result.success([]);
  }

  @override
  Future<Result<List<QuestionMasteryState>>> getAtRiskQuestions(
    String studentId, {
    double threshold = 0.5,
  }) async => _atRiskResult ?? Result.success([]);
}

MasteryState _createMasteryState({
  String topicId = 'topic-1',
  double accuracy = 0.45,
  double reviewUrgency = 0.8,
  double readinessScore = 0.3,
}) {
  return MasteryState(
    studentId: 'student-1',
    topicId: topicId,
    accuracy: accuracy,
    lastAttempt: DateTime.now(),
    lastUpdated: DateTime.now(),
    reviewUrgency: reviewUrgency,
    readinessScore: readinessScore,
  );
}

QuestionMasteryState _createAtRiskQuestion({String questionId = 'q-1'}) {
  return QuestionMasteryState(
    studentId: 'student-1',
    questionId: questionId,
    masteryLevel: 0.3,
    lastAttempt: DateTime.now(),
    nextReview: DateTime.now().add(const Duration(hours: 1)),

  );
}

void main() {
  group('GetWeakTopicsTool', () {
    late FakeMasteryGraphService fakeMastery;
    late FakeStudentIdService fakeStudentId;
    late GetWeakTopicsTool tool;

    setUp(() {
      fakeMastery = FakeMasteryGraphService();
      fakeStudentId = FakeStudentIdService()..setStudentId('student-1');
      tool = GetWeakTopicsTool(
        masteryService: fakeMastery,
        studentIdService: fakeStudentId,
      );
    });

    test('name returns get_weak_topics', () {
      expect(tool.name, 'get_weak_topics');
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

    test('execute returns weak topics and at-risk questions from services', () async {
      fakeMastery.setWeakTopics(Result.success([
        _createMasteryState(topicId: 'topic-1', accuracy: 0.45, reviewUrgency: 0.8, readinessScore: 0.3),
        _createMasteryState(topicId: 'topic-2', accuracy: 0.30, reviewUrgency: 0.9, readinessScore: 0.2),
      ]));
      fakeMastery.setAtRiskQuestions(Result.success([
        _createAtRiskQuestion(questionId: 'q-1'),
        _createAtRiskQuestion(questionId: 'q-2'),
        _createAtRiskQuestion(questionId: 'q-3'),
      ]));

      final result = await tool.execute({});

      expect(result['weakTopicCount'], 2);
      expect(result['weakTopics'], hasLength(2));
      expect(result['weakTopics'][0]['topicId'], 'topic-1');
      expect(result['weakTopics'][0]['accuracy'], 0.45);
      expect(result['weakTopics'][0]['reviewUrgency'], 0.8);
      expect(result['weakTopics'][0]['readinessScore'], 0.3);
      expect(result['weakTopics'][1]['topicId'], 'topic-2');
      expect(result['atRiskQuestionCount'], 3);
    });

    test('execute returns empty lists when services return null data', () async {
      fakeMastery.setWeakTopics(Result.failure('no_data'));
      fakeMastery.setAtRiskQuestions(Result.failure('no_data'));

      final result = await tool.execute({});

      expect(result['weakTopicCount'], 0);
      expect(result['weakTopics'], []);
      expect(result['atRiskQuestionCount'], 0);
    });

    test('execute uses studentId from StudentIdService', () async {
      await tool.execute({});

      expect(fakeMastery.capturedStudentId, 'student-1');
    });

    test('execute returns empty lists when services return empty lists', () async {
      fakeMastery.setWeakTopics(Result.success([]));
      fakeMastery.setAtRiskQuestions(Result.success([]));

      final result = await tool.execute({});

      expect(result['weakTopicCount'], 0);
      expect(result['weakTopics'], []);
      expect(result['atRiskQuestionCount'], 0);
    });

    test('execute handles single weak topic correctly', () async {
      fakeMastery.setWeakTopics(Result.success([
        _createMasteryState(topicId: 'topic-1', accuracy: 0.50, reviewUrgency: 0.7, readinessScore: 0.4),
      ]));
      fakeMastery.setAtRiskQuestions(Result.success([]));

      final result = await tool.execute({});

      expect(result['weakTopicCount'], 1);
      expect(result['weakTopics'][0]['topicId'], 'topic-1');
      expect(result['weakTopics'][0]['accuracy'], 0.50);
      expect(result['weakTopics'][0]['reviewUrgency'], 0.7);
      expect(result['weakTopics'][0]['readinessScore'], 0.4);
      expect(result['atRiskQuestionCount'], 0);
    });
  });
}
