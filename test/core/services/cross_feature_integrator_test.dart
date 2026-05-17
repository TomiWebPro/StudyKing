import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/models/session_model.dart';
import 'package:studyking/core/services/cross_feature_integrator.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/core/errors/result.dart';

class _FakeStudentIdService extends StudentIdService {
  @override
  String getStudentId() => 'test-student';
  @override
  Future<void> init() async {}
}

class _FakeSessionRepository extends SessionRepository {
  final List<Session> _sessions = [];

  @override
  Future<Result<void>> save(String key, Session session) async {
    _sessions.add(session);
    return Result.success(null);
  }

  @override
  Future<Result<Session?>> get(String id) async {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return Result.success(null);
    return Result.success(_sessions[idx]);
  }

  @override
  Future<Result<List<Session>>> getAll() async {
    return Result.success(List.from(_sessions));
  }

  @override
  Future<Result<List<Session>>> getByStudent(String studentId) async {
    return Result.success(
      _sessions.where((s) => s.studentId == studentId).toList(),
    );
  }
}

void main() {
  group('CrossFeatureIntegrator', () {
    late _FakeSessionRepository sessionRepo;
    late CrossFeatureIntegrator integrator;

    setUp(() {
      sessionRepo = _FakeSessionRepository();
      integrator = CrossFeatureIntegrator(
        sessionRepo: sessionRepo,
        studentIdService: _FakeStudentIdService(),
      );
    });

    group('recordTutorSessionAsSession', () {
      test('creates Session for tutor session', () async {
        await integrator.recordTutorSessionAsSession(
          tutorSessionId: 'ts1',
          subjectId: 'sub1',
          topicId: 't1',
          durationMs: 2700000,
          studentId: 's1',
        );

        expect(sessionRepo._sessions, hasLength(1));
        final session = sessionRepo._sessions.first;
        expect(session.type, SessionType.tutoring);
        expect(session.subjectId, 'sub1');
        expect(session.topicId, 't1');
        expect(session.actualDurationMs, 2700000);
        expect(session.completed, isTrue);
        expect(session.sourceId, 'ts1');
      });
    });

    group('linkPracticeSessionToSource', () {
      test('updates sourceId on practice session', () async {
        final session = Session(
          id: 'practice_1',
          studentId: 's1',
          subjectId: 'sub1',
          startTime: DateTime(2026, 1, 1),
          completed: true,
        );
        await sessionRepo.save(session.id, session);

        await integrator.linkPracticeSessionToSource(
          practiceSessionId: 'practice_1',
          tutorSessionId: 'ts1',
        );

        final updated = await sessionRepo.get('practice_1');
        expect(updated.data?.sourceId, 'ts1');
      });

      test('gracefully handles missing session', () async {
        await expectLater(
          integrator.linkPracticeSessionToSource(
            practiceSessionId: 'nonexistent',
            tutorSessionId: 'ts1',
          ),
          completes,
        );
      });
    });

    group('getUnifiedTimeline', () {
      test('returns sessions sorted chronologically', () async {
        final sess0 = Session(
          
                    id: 's1',
                    studentId: 's1',
                    subjectId: 'sub1',
                    type: SessionType.practice,
                    startTime: DateTime(2026, 1, 3),
                    actualDurationMs: 1000,
                    completed: true,
                  
        );
        await sessionRepo.save(sess0.id, sess0);
        final sess1 = Session(
          
                    id: 's2',
                    studentId: 's1',
                    subjectId: 'sub1',
                    type: SessionType.tutoring,
                    startTime: DateTime(2026, 1, 1),
                    actualDurationMs: 2000,
                    completed: true,
                  
        );
        await sessionRepo.save(sess1.id, sess1);
        final sess2 = Session(
          
                    id: 's3',
                    studentId: 's1',
                    subjectId: 'sub1',
                    type: SessionType.focus,
                    startTime: DateTime(2026, 1, 2),
                    actualDurationMs: 3000,
                    completed: true,
                  
        );
        await sessionRepo.save(sess2.id, sess2);

        final timeline = await integrator.getUnifiedTimeline(studentId: 's1');

        expect(timeline, hasLength(3));
        expect(timeline[0].id, 's1');
        expect(timeline[1].id, 's3');
        expect(timeline[2].id, 's2');
      });

      test('respects limit parameter', () async {
        for (var i = 0; i < 5; i++) {
          final sess3 = Session(
            
                        id: 's$i',
                        studentId: 's1',
                        startTime: DateTime(2026, 1, i + 1),
                        actualDurationMs: 1000,
                        completed: true,
                      
          );
          await sessionRepo.save(sess3.id, sess3);
        }

        final timeline = await integrator.getUnifiedTimeline(
          studentId: 's1',
          limit: 2,
        );

        expect(timeline, hasLength(2));
      });

      test('respects offset parameter', () async {
        for (var i = 0; i < 5; i++) {
          final sess4 = Session(
            
                        id: 's$i',
                        studentId: 's1',
                        startTime: DateTime(2026, 1, i + 1),
                        actualDurationMs: 1000,
                        completed: true,
                      
          );
          await sessionRepo.save(sess4.id, sess4);
        }

        final timeline = await integrator.getUnifiedTimeline(
          studentId: 's1',
          limit: 10,
          offset: 2,
        );

        expect(timeline, hasLength(3));
      });

      test('returns empty for student with no sessions', () async {
        final timeline = await integrator.getUnifiedTimeline(studentId: 'none');
        expect(timeline, isEmpty);
      });
    });

    group('getTotalStudyDurationMs', () {
      test('sums all session durations', () async {
        final sess5 = Session(
          
                    id: 's1',
                    studentId: 's1',
                    startTime: DateTime(2026, 1, 1),
                    actualDurationMs: 100000,
                    completed: true,
                  
        );
        await sessionRepo.save(sess5.id, sess5);
        final sess6 = Session(
          
                    id: 's2',
                    studentId: 's1',
                    startTime: DateTime(2026, 1, 2),
                    actualDurationMs: 200000,
                    completed: true,
                  
        );
        await sessionRepo.save(sess6.id, sess6);

        final total = await integrator.getTotalStudyDurationMs(studentId: 's1');
        expect(total, 300000);
      });

      test('filters by date', () async {
        final sess7 = Session(
          
                    id: 's1',
                    studentId: 's1',
                    startTime: DateTime(2025, 1, 1),
                    actualDurationMs: 100000,
                    completed: true,
                  
        );
        await sessionRepo.save(sess7.id, sess7);
        final sess8 = Session(
          
                    id: 's2',
                    studentId: 's1',
                    startTime: DateTime(2026, 1, 1),
                    actualDurationMs: 200000,
                    completed: true,
                  
        );
        await sessionRepo.save(sess8.id, sess8);

        final total = await integrator.getTotalStudyDurationMs(
          studentId: 's1',
          since: DateTime(2026, 1, 1),
        );
        expect(total, 200000);
      });
    });

    group('getDurationByType', () {
      test('groups durations by session type', () async {
        final sess9 = Session(
          
                    id: 's1',
                    studentId: 's1',
                    type: SessionType.practice,
                    startTime: DateTime(2026, 1, 1),
                    actualDurationMs: 100000,
                    completed: true,
                  
        );
        await sessionRepo.save(sess9.id, sess9);
        final sess10 = Session(
          
                    id: 's2',
                    studentId: 's1',
                    type: SessionType.practice,
                    startTime: DateTime(2026, 1, 1),
                    actualDurationMs: 200000,
                    completed: true,
                  
        );
        await sessionRepo.save(sess10.id, sess10);
        final sess11 = Session(
          
                    id: 's3',
                    studentId: 's1',
                    type: SessionType.tutoring,
                    startTime: DateTime(2026, 1, 1),
                    actualDurationMs: 300000,
                    completed: true,
                  
        );
        await sessionRepo.save(sess11.id, sess11);

        final byType = await integrator.getDurationByType(studentId: 's1');

        expect(byType[SessionType.practice], 300000);
        expect(byType[SessionType.tutoring], 300000);
      });
    });

    test('getCompletedSessionCount returns count', () async {
      final sess12 = Session(
        
                id: 's1',
                studentId: 's1',
                startTime: DateTime(2026, 1, 1),
                completed: true,
              
      );
      await sessionRepo.save(sess12.id, sess12);
      final sess13 = Session(
        
                id: 's2',
                studentId: 's1',
                startTime: DateTime(2026, 1, 1),
                completed: false,
              
      );
      await sessionRepo.save(sess13.id, sess13);

      final count = await integrator.getCompletedSessionCount(studentId: 's1');
      expect(count, 1);
    });
  });
}
