import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/prep_budget.dart' show PrepCategory;
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/features/ingestion/services/bulk_ingestion_service.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';

/// Hand-written fake [ContentPipeline] that records every call and allows
/// tests to control the return value. Use [failCount] to make the pipeline
/// fail the first N attempts and then succeed.
class FakeContentPipeline extends ContentPipeline {
  FakeContentPipeline()
      : super(
          llmService: _FakeLlmService(),
          sourceRepository: _FakeSourceRepo(),
          topicRepository: _FakeTopicRepo(),
          questionRepository: _FakeQuestionRepo(),
          transcriptionModelId: 'test-model',
          localeName: 'en',
        );

  /// Number of times to fail before succeeding. 0 = never fail.
  int failCount = 0;
  String failureError = '';
  int callCount = 0;
  List<String> capturedTitles = [];

  @override
  Future<Result<Source>> processFullPipeline({
    required String title,
    required String content,
    required SourceType type,
    required String studentId,
    required String classificationModelId,
    required String summarizationModelId,
    required String generationModelId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
    List<String> possibleTopics = const [],
    bool generateQuestions = false,
    bool generateLessons = false,
    bool generateSlideDecks = false,
    bool generateFlashcards = false,
    QuestionValidator? validator,
    List<String> allowedQuestionTypes = const [
      'singleChoice', 'multiChoice', 'typedAnswer',
      'mathExpression', 'essay',
    ],
    ProcessingProgressCallback? onProgress,
    String? existingSourceId,
    List<String> oldQuestionIds = const [],
  }) async {
    callCount++;
    capturedTitles.add(title);

    onProgress?.call(ProcessingStatus.extracting, 'Extracting content');
    onProgress?.call(ProcessingStatus.classifying, 'Classifying content');

    if (callCount <= failCount) {
      return Result.failure(failureError.isNotEmpty
          ? failureError
          : 'Processing failed');
    }
    return Result.success(Source(
      id: 'src_$callCount',
      title: title,
      type: type,
      content: content,
      studentId: studentId,
    ));
  }

  @override
  Future<Result<Source>> processUpload({
    required String title,
    required String content,
    required SourceType type,
    required String studentId,
    String subjectId = '',
    String topicId = '',
    String syllabusId = '',
    String sourceUrl = '',
    String language = '',
  }) async {
    callCount++;
    capturedTitles.add(title);
    if (callCount <= failCount) {
      return Result.failure(failureError.isNotEmpty
          ? failureError
          : 'Processing failed');
    }
    return Result.success(Source(
      id: 'src_$callCount',
      title: title,
      type: type,
      content: content,
      studentId: studentId,
    ));
  }
}

class _FakeLlmService extends LlmService {
  _FakeLlmService()
      : super(config: const LlmConfiguration(
          provider: LlmProvider.ollama,
          apiKey: 'k',
          baseUrl: '',
          model: 'm',
        ));

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async {
    return Result.success('llm-response');
  }
}

class _FakeSourceRepo extends SourceRepository {
  @override
  Future<void> init() async {}

  @override
  Future<Result<void>> create(Source source) async => Result.success(null);

  @override
  Future<Result<void>> save(String key, Source item) async {
    return Result.success(null);
  }
}

class _FakeTopicRepo extends TopicRepository {
  @override
  Future<Result<void>> init() async => Result.success(null);
}

class _FakeQuestionRepo extends QuestionRepository {
  @override
  Future<void> init() async {}
}

/// A controllable fake [IdleExecutor] that records enqueued tasks and
/// executes them immediately (awaiting the task function) so that tests
/// are fully deterministic without real time delays.
class _SyncIdleExecutor extends IdleExecutor {
  final List<String> enqueuedDescriptions = [];
  final List<_EnqueuedPrepTool> enqueuedPrepTools = [];

  @override
  Future<void> enqueuePrepTool(
    String description,
    Future<Map<String, dynamic>> Function() task, {
    required bool requiresHeavy,
    required String feature,
    required String taskType,
    String? subjectId,
    int estimatedInputTokens = 0,
    int estimatedOutputTokens = 0,
  }) async {
    enqueuedDescriptions.add(description);
    enqueuedPrepTools.add(_EnqueuedPrepTool(
      description: description,
      requiresHeavy: requiresHeavy,
      feature: feature,
      taskType: taskType,
      subjectId: subjectId,
      estimatedInputTokens: estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens,
    ));
    await task();
  }
}

/// Captured parameters from an [IdleExecutor.enqueuePrepTool] call.
class _EnqueuedPrepTool {
  final String description;
  final bool requiresHeavy;
  final String feature;
  final String taskType;
  final String? subjectId;
  final int estimatedInputTokens;
  final int estimatedOutputTokens;

  _EnqueuedPrepTool({
    required this.description,
    required this.requiresHeavy,
    required this.feature,
    required this.taskType,
    this.subjectId,
    this.estimatedInputTokens = 0,
    this.estimatedOutputTokens = 0,
  });
}

void main() {
  group('BulkIngestionService', () {
    late FakeContentPipeline pipeline;
    late _SyncIdleExecutor executor;
    late BulkIngestionService service;

    setUp(() {
      pipeline = FakeContentPipeline();
      executor = _SyncIdleExecutor();
      service = BulkIngestionService(
        pipeline: pipeline,
        idleExecutor: executor,
      );
    });

    group('enqueueBulk — queue ordering', () {
      test('preserves file order when enqueuing multiple files', () async {
        final files = List.generate(5, (i) => BulkUploadFile(
              filePath: '/test/file_$i.pdf',
              fileName: 'file_$i.pdf',
              title: 'Title $i',
              sourceType: SourceType.pdf,
            ));

        final jobs = await service.enqueueBulk(
          files: files,
          studentId: 'student-1',
          classificationModelId: 'clf',
          summarizationModelId: 'sum',
          generationModelId: 'gen',
        );

        expect(jobs.length, 5);
        expect(jobs[0].fileName, 'file_0.pdf');
        expect(jobs[4].fileName, 'file_4.pdf');
        expect(executor.enqueuedDescriptions.length, 5);
        expect(executor.enqueuedDescriptions[0], contains('file_0.pdf'));
        expect(executor.enqueuedDescriptions[4], contains('file_4.pdf'));
      });

      test('all jobs transition from pending to completed on success',
          () async {
        final files = List.generate(3, (i) => BulkUploadFile(
              filePath: '/test/f$i.pdf',
              fileName: 'f$i.pdf',
              title: 'T$i',
              sourceType: SourceType.pdf,
            ));

        await service.enqueueBulk(
          files: files,
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        expect(service.jobs.length, 3);
        expect(service.completedCount, 3);
        expect(service.queuedCount, 0);
        expect(pipeline.callCount, 3);
      });
    });

    group('retry on transient errors', () {
      test('retries and succeeds on 429 rate-limit error', () async {
        // First call fails with 429, retry succeeds.
        pipeline.failCount = 1;
        pipeline.failureError = '429 Too Many Requests';

        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/retry_429.pdf',
              fileName: 'retry_429.pdf',
              title: 'Retry Test',
              sourceType: SourceType.pdf,
            ),
          ],
          studentId: 'student-1',
          classificationModelId: 'clf',
          summarizationModelId: 'sum',
          generationModelId: 'gen',
        );

        // First attempt failed, retry scheduled with 1s delay.
        expect(service.jobs.first.retryCount, 1);
        expect(service.jobs.first.isPending, isTrue);

        // Wait for the retry to fire (1s delay).
        await Future.delayed(
          Duration(
            seconds: BulkIngestionService.retryBaseDelaySeconds + 1,
          ),
        );

        expect(service.jobs.first.isCompleted, isTrue);
        expect(pipeline.callCount, 2);
        expect(service.completedCount, 1);
      });

      test('retries and succeeds on timeout error', () async {
        pipeline.failCount = 1;
        pipeline.failureError = 'Request timed out after 30s';

        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/timeout.pdf',
              fileName: 'timeout.pdf',
              title: 'Timeout Test',
              sourceType: SourceType.pdf,
            ),
          ],
          studentId: 'student-1',
          classificationModelId: 'clf',
          summarizationModelId: 'sum',
          generationModelId: 'gen',
        );

        expect(service.jobs.first.retryCount, 1);
        expect(service.jobs.first.isPending, isTrue);

        await Future.delayed(
          Duration(
            seconds: BulkIngestionService.retryBaseDelaySeconds + 1,
          ),
        );

        expect(service.jobs.first.isCompleted, isTrue);
      });

      test('retries on socket error', () async {
        pipeline.failCount = 1;
        pipeline.failureError = 'SocketException: Failed host lookup';

        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/socket.pdf',
              fileName: 'socket.pdf',
              title: 'Socket',
              sourceType: SourceType.pdf,
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        expect(service.jobs.first.retryCount, 1);
        expect(service.jobs.first.isPending, isTrue);

        await Future.delayed(
          Duration(
            seconds: BulkIngestionService.retryBaseDelaySeconds + 1,
          ),
        );

        expect(service.jobs.first.isCompleted, isTrue);
      });
    });

    group('non-retryable failures', () {
      test('does not retry on permanent error', () async {
        pipeline.failCount = 100; // always fails
        pipeline.failureError = 'Invalid API key: unauthorized';

        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/permanent.pdf',
              fileName: 'permanent.pdf',
              title: 'Permanent Fail',
              sourceType: SourceType.pdf,
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        // No Future.delayed is scheduled for permanent errors.
        expect(service.jobs.first.isFailed, isTrue);
        expect(service.jobs.first.retryCount, 0);
        expect(service.failedCount, 1);
        expect(service.jobs.first.error, contains('Invalid API key'));
      });
    });

    group('status counters', () {
      test('tracks queued, running, completed, failed counts', () async {
        final files = List.generate(3, (i) => BulkUploadFile(
              filePath: '/test/f$i.pdf',
              fileName: 'f$i.pdf',
              title: 'T$i',
              sourceType: SourceType.pdf,
            ));

        await service.enqueueBulk(
          files: files,
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        expect(service.totalCount, 3);
        expect(service.completedCount, 3);
        expect(service.queuedCount, 0);
        expect(service.runningCount, 0);
        expect(service.failedCount, 0);
      });
    });

    group('retryJob', () {
      test('retries a failed job and transitions to completed on success',
          () async {
        pipeline.failCount = 100; // always fails initially
        pipeline.failureError = 'Invalid API key: unauthorized';

        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/retry_manual.pdf',
              fileName: 'retry_manual.pdf',
              title: 'Manual Retry',
              sourceType: SourceType.pdf,
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        expect(service.jobs.first.isFailed, isTrue);

        // Reset pipeline to succeed and retry manually.
        pipeline.failCount = 0;
        await service.retryJob(service.jobs.first);

        expect(service.jobs.first.isCompleted, isTrue);
        expect(service.jobs.first.retryCount, 1);
      });
    });

    group('cancelJob', () {
      test('cancels a pending job', () async {
        pipeline.failCount = 100; // always fails with transient error
        pipeline.failureError = '429';

        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/cancel.pdf',
              fileName: 'cancel.pdf',
              title: 'Cancel',
              sourceType: SourceType.pdf,
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        final job = service.jobs.first;
        // Job failed and was retried (is pending for retry).
        service.cancelJob(job.id);

        expect(job.isCancelled, isTrue);
      });

      test('completed job stays completed when cancel is called', () async {
        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/cancel2.pdf',
              fileName: 'cancel2.pdf',
              title: 'Cancel2',
              sourceType: SourceType.pdf,
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        final job = service.jobs.first;
        service.cancelJob(job.id);

        // Completed jobs can't be cancelled — cancelJob returns early.
        expect(job.isCompleted, isTrue);
      });
    });

    group('notification', () {
      test('notifies listeners when jobs are enqueued', () async {
        var notificationCount = 0;
        service.addListener(() => notificationCount++);

        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/notify.pdf',
              fileName: 'notify.pdf',
              title: 'Notify',
              sourceType: SourceType.pdf,
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        expect(notificationCount, greaterThan(0));
      });
    });

    group('prep-tool attribution', () {
      test('enqueues via enqueuePrepTool with pdf_ingestion feature and background taskType',
          () async {
        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/prep.pdf',
              fileName: 'prep.pdf',
              title: 'Prep',
              sourceType: SourceType.pdf,
              subjectId: 'chemistry',
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        expect(executor.enqueuedPrepTools.length, 1);
        final captured = executor.enqueuedPrepTools.first;
        expect(captured.feature, PrepCategory.pdfIngestion.taskTypeKey);
        expect(captured.taskType, PrepCategory.pdfIngestion.taskTypeKey);
        expect(captured.requiresHeavy, isTrue);
      });

      test('passes subjectId for per-subject opt-in enforcement', () async {
        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/subject.pdf',
              fileName: 'subject.pdf',
              title: 'Subject',
              sourceType: SourceType.pdf,
              subjectId: 'biology',
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        expect(executor.enqueuedPrepTools.first.subjectId, 'biology');
      });

      test('passes null subjectId when file has no subject', () async {
        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/nosubject.pdf',
              fileName: 'nosubject.pdf',
              title: 'No Subject',
              sourceType: SourceType.pdf,
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        expect(executor.enqueuedPrepTools.first.subjectId, isNull);
      });

      test('retry path uses prep-tool attribution with correct feature/taskType/subjectId',
          () async {
        pipeline.failCount = 1;
        pipeline.failureError = '429 Too Many Requests';

        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/retry_attr.pdf',
              fileName: 'retry_attr.pdf',
              title: 'Retry Attr',
              sourceType: SourceType.pdf,
              subjectId: 'physics',
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        // First enqueue + first failed attempt.
        expect(executor.enqueuedPrepTools.length, 1);
        expect(executor.enqueuedPrepTools.first.subjectId, 'physics');

        // Wait for the backoff-delayed retry to fire.
        await Future.delayed(
          Duration(seconds: BulkIngestionService.retryBaseDelaySeconds + 1),
        );

        // The retry should also have gone through enqueuePrepTool with the
        // same attribution (feature/taskType/subjectId).
        expect(executor.enqueuedPrepTools.length, 2);
        final retryCall = executor.enqueuedPrepTools[1];
        expect(retryCall.feature, PrepCategory.pdfIngestion.taskTypeKey);
        expect(retryCall.taskType, PrepCategory.pdfIngestion.taskTypeKey);
        expect(retryCall.subjectId, 'physics');
      });

      test('manual retryJob uses prep-tool attribution', () async {
        // Force a permanent failure so the job lands in failed state.
        pipeline.failCount = 100;
        pipeline.failureError = 'Invalid API key: unauthorized';

        await service.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/manual_retry.pdf',
              fileName: 'manual_retry.pdf',
              title: 'Manual',
              sourceType: SourceType.pdf,
              subjectId: 'math',
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        expect(executor.enqueuedPrepTools.length, 1);

        // Reset pipeline to succeed, then retry manually.
        pipeline.failCount = 0;
        await service.retryJob(service.jobs.first);

        expect(executor.enqueuedPrepTools.length, 2);
        final retryCall = executor.enqueuedPrepTools[1];
        expect(retryCall.feature, PrepCategory.pdfIngestion.taskTypeKey);
        expect(retryCall.taskType, PrepCategory.pdfIngestion.taskTypeKey);
        expect(retryCall.subjectId, 'math');
      });
    });

    group('per-subject opt-in deferral', () {
      test('BulkIngestionService defers bulk ingestion for student-disabled subject',
          () async {
        // Uses the real IdleExecutor logic with an isPrepEnabledForSubject gate
        // (vision §4.2 per-syllabus opt-in): tokens must never be spent on a
        // syllabus the student toggled off.
        final realExecutor = IdleExecutor(
          isPrepEnabledForSubject: (subjectId) => subjectId != 'chemistry',
        );
        final deferredService = BulkIngestionService(
          pipeline: pipeline,
          idleExecutor: realExecutor,
        );

        await deferredService.enqueueBulk(
          files: [
            BulkUploadFile(
              filePath: '/test/opts_out.pdf',
              fileName: 'opts_out.pdf',
              title: 'Opts Out',
              sourceType: SourceType.pdf,
              subjectId: 'chemistry',
            ),
          ],
          studentId: 's',
          classificationModelId: 'c',
          summarizationModelId: 's2',
          generationModelId: 'g',
        );

        // The real IdleExecutor deferred the chemistry task — pipeline never
        // called, job still pending, task stays in the queue.
        expect(pipeline.callCount, 0,
            reason: 'No tokens may be spent on a disabled subject');
        expect(deferredService.jobs.first.isPending, isTrue);
        expect(
            realExecutor.queue.any((t) => t.subjectId == 'chemistry'), isTrue);

        realExecutor.dispose();
      });
    });
  });
}
