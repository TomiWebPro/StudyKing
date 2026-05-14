import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/models/markscheme_model.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/spaced_repetition_repository.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/practice/presentation/services/practice_data_service.dart';
import 'package:studyking/features/practice/providers/practice_providers.dart';

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> _questions;

  _FakeQuestionRepository(this._questions);

  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async =>
      Result.success(_questions);
}

class _FakeSpacedRepetitionRepository extends SpacedRepetitionRepository {
  final Map<String, int> _dueCounts;

  _FakeSpacedRepetitionRepository(this._dueCounts);

  @override
  Future<void> init() async {}

  @override
  Future<Result<int>> getSubjectDueCount(String subjectId) async {
    return Result.success(_dueCounts[subjectId] ?? 0);
  }
}

Question _question({
  String id = 'q1',
  String text = 'Question',
  String? topic,
}) {
  return Question(
    id: id,
    text: text,
    type: QuestionType.singleChoice,
    subjectId: 'subj-1',
    topicId: 'topic-1',
    topic: topic,
    markscheme: Markscheme(questionId: id, correctAnswer: 'A'),
    options: ['A', 'B'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('PracticeDataService', () {
    testWidgets('loadDueCounts returns counts per subject', (tester) async {
      final srRepo = _FakeSpacedRepetitionRepository({'subj-1': 5, 'subj-2': 3});
      final subjects = [
        Subject(id: 'subj-1', name: 'Math'),
        Subject(id: 'subj-2', name: 'Physics'),
      ];

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          spacedRepetitionRepositoryProvider.overrideWithValue(srRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final dueCounts = await service.loadDueCounts(subjects);
      expect(dueCounts['subj-1'], 5);
      expect(dueCounts['subj-2'], 3);
    });

    testWidgets('loadDueCounts defaults to 0 on failure', (tester) async {
      final srRepo = _FakeSpacedRepetitionRepository({'subj-1': 5});
      final subjects = [Subject(id: 'missing', name: 'Unknown')];

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          spacedRepetitionRepositoryProvider.overrideWithValue(srRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final dueCounts = await service.loadDueCounts(subjects);
      expect(dueCounts['missing'], 0);
    });

    testWidgets('loadTopics extracts unique non-empty topics', (tester) async {
      final questionRepo = _FakeQuestionRepository([
        _question(id: 'q1', topic: 'Algebra'),
        _question(id: 'q2', topic: 'Geometry'),
        _question(id: 'q3', topic: 'Algebra'),
        _question(id: 'q4', topic: ''),
        _question(id: 'q5', topic: null),
      ]);

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(questionRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final topics = await service.loadTopics(questionRepo);
      expect(topics, hasLength(2));
      expect(topics, containsAll(['Algebra', 'Geometry']));
    });

    testWidgets('loadTopics returns empty list when getAll fails', (tester) async {
      final questionRepo = _FakeFailingQuestionRepository();

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final topics = await service.loadTopics(questionRepo);
      expect(topics, isEmpty);
    });

    testWidgets('loadTopicQuestions filters questions by topic', (tester) async {
      final questionRepo = _FakeQuestionRepository([
        _question(id: 'q1', topic: 'Algebra'),
        _question(id: 'q2', topic: 'Algebra'),
        _question(id: 'q3', topic: 'Geometry'),
      ]);

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(questionRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final algebraQs = await service.loadTopicQuestions('Algebra');
      expect(algebraQs, hasLength(2));
    });

    testWidgets('loadTopicQuestions returns empty list when getAll fails', (tester) async {
      final failingRepo = _FakeFailingQuestionRepository();

      WidgetRef? capturedRef;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          questionRepositoryProvider.overrideWithValue(failingRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ));

      final service = PracticeDataService(capturedRef!);
      final result = await service.loadTopicQuestions('Algebra');
      expect(result, isEmpty);
    });
  });
}

class _FakeFailingQuestionRepository extends QuestionRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<List<Question>>> getAll() async =>
      Result.failure('Failed to load');
}
