import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/conversation_repository.dart';
import 'package:studyking/core/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/study_session_repository.dart';
import 'package:studyking/core/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/data/repositories/tutor_session_repository.dart';
import 'package:studyking/core/data/models/tutor_session_model.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/features/lessons/providers/lesson_providers.dart';
import 'package:studyking/features/lessons/services/lesson_service.dart';
import 'package:studyking/features/teaching/services/tutor_service.dart';

DatabaseService _fakeDb() => DatabaseService(
  topicRepository: TopicRepository(),
  questionRepository: QuestionRepository(),
  attemptRepository: AttemptRepository(),
  lessonRepository: LessonRepository(),
  sessionRepository: StudySessionRepository(),
  subjectRepository: SubjectRepository(),
  conversationRepository: ConversationRepository(),
  tutorSessionRepository: TutorSessionRepository(),
);

TutorService _fakeTutorService() => TutorService(
  database: _fakeDb(),
  llmService: LlmService(
    config: const LlmConfiguration(
      provider: LlmProvider.openRouter,
      apiKey: 'test',
    ),
  ),
  masteryService: MasteryGraphService(),
  modelId: 'test',
);

class _FakeLessonService extends LessonService {
  final List<TutorSession> _lessons;
  final double _completionRate;
  final Map<String, double> _progressBySubject;
  final Map<String, int> _countBySubject;

  _FakeLessonService({
    List<TutorSession>? lessons,
    double completionRate = 0.0,
    Map<String, double> progressBySubject = const {},
    Map<String, int> countBySubject = const {},
  })  : _lessons = lessons ?? [],
        _completionRate = completionRate,
        _progressBySubject = progressBySubject,
        _countBySubject = countBySubject,
        super(database: _fakeDb(), tutorService: _fakeTutorService());

  @override
  Future<List<TutorSession>> getLessonsForStudent(String studentId) async =>
      _lessons;

  @override
  Future<double> getCompletionRate(String studentId) async => _completionRate;

  @override
  Future<Map<String, double>> getProgressBySubject(String studentId) async =>
      _progressBySubject;

  @override
  Future<Map<String, int>> getLessonCountBySubject(String studentId) async =>
      _countBySubject;

  @override
  Future<List<TutorSession>> getUpcomingLessons(String studentId) async =>
      _lessons.where((l) => l.status == SessionStatus.planned).toList();

  @override
  Future<List<TutorSession>> getRecentLessons(String studentId, {int limit = 5}) async =>
      _lessons.take(limit).toList();
}

TutorSession _session({
  String id = 's1',
  String studentId = 'stu1',
  String subjectId = 'Math',
  SessionStatus status = SessionStatus.completed,
}) {
  return TutorSession(
    id: id,
    studentId: studentId,
    subjectId: subjectId,
    topicId: 'topic-$id',
    topicTitle: 'Topic $id',
    status: status,
    startTime: DateTime(2025, 6, 15, 10, 0),
  );
}

void main() {
  group('LessonProviders', () {
    group('lessonServiceProvider', () {
      test('can be overridden with custom LessonService', () {
        final fakeService = _FakeLessonService();
        final container = ProviderContainer(
          overrides: [
            lessonServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        expect(
          container.read(lessonServiceProvider),
          same(fakeService),
        );
      });
    });

    group('studentLessonsProvider', () {
      test('resolves with list of lessons', () async {
        final lessons = [
          _session(id: 's1', studentId: 'stu1'),
          _session(id: 's2', studentId: 'stu1'),
        ];
        final fakeService = _FakeLessonService(lessons: lessons);
        final container = ProviderContainer(
          overrides: [
            lessonServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        final result =
            await container.read(studentLessonsProvider('stu1').future);
        expect(result, hasLength(2));
        expect(result.first.id, 's1');
      });

      test('resolves with empty list when no lessons', () async {
        final fakeService = _FakeLessonService(lessons: []);
        final container = ProviderContainer(
          overrides: [
            lessonServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        final result =
            await container.read(studentLessonsProvider('stu1').future);
        expect(result, isEmpty);
      });
    });

    group('lessonCompletionRateProvider', () {
      test('resolves with completion rate', () async {
        final fakeService = _FakeLessonService(completionRate: 0.75);
        final container = ProviderContainer(
          overrides: [
            lessonServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        final rate =
            await container.read(lessonCompletionRateProvider('stu1').future);
        expect(rate, 0.75);
      });

      test('resolves with 0.0 when no lessons', () async {
        final fakeService = _FakeLessonService(completionRate: 0.0);
        final container = ProviderContainer(
          overrides: [
            lessonServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        final rate =
            await container.read(lessonCompletionRateProvider('stu1').future);
        expect(rate, 0.0);
      });
    });

    group('lessonProgressBySubjectProvider', () {
      test('resolves with progress map', () async {
        final fakeService = _FakeLessonService(
          progressBySubject: {'Math': 0.5, 'Physics': 1.0},
        );
        final container = ProviderContainer(
          overrides: [
            lessonServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        final progress = await container
            .read(lessonProgressBySubjectProvider('stu1').future);
        expect(progress['Math'], 0.5);
        expect(progress['Physics'], 1.0);
      });

      test('resolves with empty map for no lessons', () async {
        final fakeService = _FakeLessonService(progressBySubject: {});
        final container = ProviderContainer(
          overrides: [
            lessonServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        final progress = await container
            .read(lessonProgressBySubjectProvider('stu1').future);
        expect(progress, isEmpty);
      });
    });

    group('lessonCountBySubjectProvider', () {
      test('resolves with count map', () async {
        final fakeService = _FakeLessonService(
          countBySubject: {'Math': 5, 'Physics': 3},
        );
        final container = ProviderContainer(
          overrides: [
            lessonServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        final counts =
            await container.read(lessonCountBySubjectProvider('stu1').future);
        expect(counts['Math'], 5);
        expect(counts['Physics'], 3);
      });
    });

    group('upcomingLessonsProvider', () {
      test('resolves with only planned future lessons', () async {
        final lessons = [
          _session(id: 's1', status: SessionStatus.planned),
          _session(id: 's2', status: SessionStatus.completed),
        ];
        final fakeService = _FakeLessonService(lessons: lessons);
        final container = ProviderContainer(
          overrides: [
            lessonServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        final upcoming =
            await container.read(upcomingLessonsProvider('stu1').future);
        expect(upcoming, hasLength(1));
        expect(upcoming.first.id, 's1');
      });
    });

    group('recentLessonsProvider', () {
      test('resolves with recent lessons', () async {
        final lessons = [
          _session(id: 's1'),
          _session(id: 's2'),
        ];
        final fakeService = _FakeLessonService(lessons: lessons);
        final container = ProviderContainer(
          overrides: [
            lessonServiceProvider.overrideWithValue(fakeService),
          ],
        );
        addTearDown(container.dispose);

        final recent =
            await container.read(recentLessonsProvider('stu1').future);
        expect(recent, hasLength(2));
      });
    });

    group('llmServiceProviderForLesson fallback pattern', () {
      test('throws UnimplementedError when not overridden', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          () => container.read(llmServiceProviderForLesson),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('llmServiceProviderFallback throws UnimplementedError', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          () => container.read(llmServiceProviderFallback),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('masteryServiceForLessonProvider can be overridden to verify wiring', () {
        final mock = MasteryGraphService();
        final container = ProviderContainer(
          overrides: [
            masteryServiceForLessonProvider.overrideWithValue(mock),
          ],
        );
        addTearDown(container.dispose);

        expect(
          container.read(masteryServiceForLessonProvider),
          same(mock),
        );
      });
    });

    group('masteryServiceForLessonProvider', () {
      test('resolves to MasteryGraphService', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(masteryServiceForLessonProvider);
        expect(service, isA<MasteryGraphService>());
      });

      test('can be overridden', () {
        final mock = MasteryGraphService();
        final container = ProviderContainer(
          overrides: [
            masteryServiceForLessonProvider.overrideWithValue(mock),
          ],
        );
        addTearDown(container.dispose);

        expect(
          container.read(masteryServiceForLessonProvider),
          same(mock),
        );
      });
    });
  });
}
