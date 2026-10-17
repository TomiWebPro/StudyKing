import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm_agent/idle_executor.dart';
import 'package:studyking/core/services/prep_budget.dart' show PrepCategory;
import 'package:studyking/core/utils/id_generator.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';

/// A file selected for bulk ingestion, carrying the metadata that
/// [ContentPipeline.processFullPipeline] needs per source.
class BulkUploadFile {
  final String filePath;
  final String fileName;
  final String title;
  final SourceType sourceType;
  final String subjectId;
  final bool generateQuestions;
  final bool generateLessons;
  final bool fullPipeline;

  const BulkUploadFile({
    required this.filePath,
    required this.fileName,
    required this.title,
    required this.sourceType,
    this.subjectId = '',
    this.generateQuestions = false,
    this.generateLessons = false,
    this.fullPipeline = true,
  });
}

/// Current state of a single file in the bulk ingestion queue.
enum BulkJobStatus {
  /// Enqueued and waiting for the [IdleExecutor] to pick it up.
  pending,

  /// Deferred because the [IdleExecutor] detected quiet-hours or
  /// CPU/battery pressure (Vision Next-Term §4.2/§4.3).
  deferred,

  /// Actively being processed through [ContentPipeline].
  running,

  /// Processed successfully — a [Source] was created and stored.
  completed,

  /// Failed and not eligible for further automatic retry.
  failed,

  /// Cancelled by the student before or during processing.
  cancelled,
}

/// Tracks the lifecycle of one file through the bulk ingestion pipeline.
///
/// The processing configuration (file path, model IDs, etc.) is captured at
/// enqueue time and stored on the job so that retries can re-submit the same
/// configuration without re-reading screen state.
class BulkIngestionJob {
  final String id;
  final String fileName;
  final String title;
  final String filePath;
  final SourceType sourceType;
  final String subjectId;
  final bool generateQuestions;
  final bool generateLessons;
  final bool fullPipeline;
  final String studentId;
  final String classificationModelId;
  final String summarizationModelId;
  final String generationModelId;
  final List<String> possibleTopics;
  final DateTime createdAt;

  /// Pipeline stage (extracting, classifying, …) reported by the
  /// pipeline's `onProgress` callback.
  ProcessingStatus? processingStage;

  /// Human-readable description of the current stage, for the UI.
  String description = '';

  BulkJobStatus status = BulkJobStatus.pending;
  String error = '';
  int retryCount = 0;
  DateTime? startedAt;
  DateTime? completedAt;
  String? sourceId;

  bool get isPending =>
      status == BulkJobStatus.pending || status == BulkJobStatus.deferred;
  bool get isRunning => status == BulkJobStatus.running;
  bool get isCompleted => status == BulkJobStatus.completed;
  bool get isFailed => status == BulkJobStatus.failed;
  bool get isCancelled => status == BulkJobStatus.cancelled;

  BulkIngestionJob({
    required this.id,
    required this.fileName,
    required this.title,
    required this.filePath,
    required this.sourceType,
    required this.studentId,
    required this.classificationModelId,
    required this.summarizationModelId,
    required this.generationModelId,
    this.subjectId = '',
    this.generateQuestions = false,
    this.generateLessons = false,
    this.fullPipeline = true,
    this.possibleTopics = const [],
  }) : createdAt = DateTime.now();
}

/// Manages bulk ingestion of study materials (PDFs, notes, etc.) through a
/// background queue powered by [IdleExecutor] (Vision Next-Term §4.1).
///
/// Students multi-select many files at once; each file is enqueued as a
/// background [IdleTask] that processes through [ContentPipeline] without
/// blocking the UI thread. Progress is tracked per file, and failed files
/// are retried on transient errors (429, timeout, network).
///
/// The service is a [ChangeNotifier] so widgets can `ref.watch` it and
/// rebuild as jobs transition through states.
class BulkIngestionService extends ChangeNotifier {
  static final Logger _logger = const Logger('BulkIngestionService');

  final ContentPipeline _pipeline;
  final IdleExecutor _idleExecutor;

  /// Maximum automatic retries per file before marking as permanently failed.
  static const int maxRetries = 3;

  /// Base delay (seconds) for exponential backoff on retry.
  static const int retryBaseDelaySeconds = 1;

  final List<BulkIngestionJob> _jobs = [];

  List<BulkIngestionJob> get jobs => List.unmodifiable(_jobs);

  int get queuedCount => _jobs.where((j) => j.isPending).length;
  int get runningCount => _jobs.where((j) => j.isRunning).length;
  int get completedCount => _jobs.where((j) => j.isCompleted).length;
  int get failedCount => _jobs.where((j) => j.isFailed).length;
  int get totalCount => _jobs.length;

  BulkIngestionService({
    required ContentPipeline pipeline,
    required IdleExecutor idleExecutor,
  })  : _pipeline = pipeline,
        _idleExecutor = idleExecutor;

  /// Enqueues a list of files for background processing.
  ///
  /// Each file is added as a [BulkIngestionJob] and then enqueued onto the
  /// [IdleExecutor] queue. The executor processes tasks sequentially, so the
  /// order of the input list is preserved in the queue.
  ///
  /// Returns the list of created jobs so callers can track them.
  Future<List<BulkIngestionJob>> enqueueBulk({
    required List<BulkUploadFile> files,
    required String studentId,
    required String classificationModelId,
    required String summarizationModelId,
    required String generationModelId,
    List<String> possibleTopics = const [],
  }) async {
    final created = <BulkIngestionJob>[];

    for (final file in files) {
      final job = BulkIngestionJob(
        id: IdGenerator.generate('bulk'),
        fileName: file.fileName,
        title: file.title,
        filePath: file.filePath,
        sourceType: file.sourceType,
        subjectId: file.subjectId,
        generateQuestions: file.generateQuestions,
        generateLessons: file.generateLessons,
        fullPipeline: file.fullPipeline,
        studentId: studentId,
        classificationModelId: classificationModelId,
        summarizationModelId: summarizationModelId,
        generationModelId: generationModelId,
        possibleTopics: possibleTopics,
      );
      _jobs.add(job);
      created.add(job);
      notifyListeners();

      await _idleExecutor.enqueuePrepTool(
        'Ingest "${file.fileName}"',
        () => _processJob(job),
        requiresHeavy: true,
        feature: PrepCategory.pdfIngestion.taskTypeKey,
        taskType: PrepCategory.pdfIngestion.taskTypeKey,
        subjectId: job.subjectId.isNotEmpty ? job.subjectId : null,
      );
    }

    return created;
  }

  /// Processes a single job through the content pipeline.
  ///
  /// On success, the job status is set to [BulkJobStatus.completed] and the
  /// created [Source.id] is stored. On transient failures (429, timeout,
  /// network), the job is retried up to [maxRetries] times with exponential
  /// backoff. On permanent failure, the job status is set to
  /// [BulkJobStatus.failed] with the error captured.
  Future<Map<String, dynamic>> _processJob(BulkIngestionJob job) async {
    job.status = BulkJobStatus.running;
    job.startedAt = DateTime.now();
    job.error = '';
    notifyListeners();

    try {
      final Result<Source> result;

      if (job.fullPipeline) {
        result = await _pipeline.processFullPipeline(
          title: job.title,
          content: 'file://${job.filePath}',
          type: job.sourceType,
          studentId: job.studentId,
          classificationModelId: job.classificationModelId,
          summarizationModelId: job.summarizationModelId,
          generationModelId: job.generationModelId,
          subjectId: job.subjectId,
          possibleTopics: job.possibleTopics,
          generateQuestions: job.generateQuestions,
          generateLessons: job.generateLessons,
          onProgress: (status, description) {
            job.processingStage = status;
            job.description = description;
            notifyListeners();
          },
        );
      } else {
        result = await _pipeline.processUpload(
          title: job.title,
          content: 'file://${job.filePath}',
          type: job.sourceType,
          studentId: job.studentId,
          subjectId: job.subjectId,
        );
      }

      if (result.isSuccess && result.data != null) {
        job.sourceId = result.data!.id;
        job.status = BulkJobStatus.completed;
        job.completedAt = DateTime.now();
        job.processingStage = null;
        job.description = 'Completed';
        return {'success': true};
      } else {
        job.error = result.error ?? 'Processing failed';
        _handleTransientFailure(job);
        if (job.isFailed) {
          return {'success': false, 'error': job.error};
        }
        // Retry was scheduled by [_handleTransientFailure]; this execution
        // is done — the retry will run as a separate prep task.
        return {'success': true};
      }
    } catch (e) {
      _logger.w('Job "${job.fileName}" failed: $e', e);
      job.error = e.toString();
      _handleTransientFailure(job);
      if (job.isFailed) {
        return {'success': false, 'error': job.error};
      }
      return {'success': true};
    } finally {
      notifyListeners();
    }
  }

  /// Determines whether [error] is a transient error worth retrying, and if
  /// so schedules a retry via the [IdleExecutor]. Otherwise marks the job
  /// as permanently failed.
  void _handleTransientFailure(BulkIngestionJob job) {
    final isTransient = _isTransientError(job.error);

    if (isTransient && job.retryCount < maxRetries) {
      job.retryCount++;
      job.status = BulkJobStatus.pending;
      job.description = 'Retrying (${job.retryCount}/$maxRetries)...';
      final delaySeconds = retryBaseDelaySeconds * (1 << (job.retryCount - 1));
      _logger.d(
        'Job "${job.fileName}" will retry in ${delaySeconds}s '
        '(attempt ${job.retryCount}/$maxRetries)',
      );
      Future.delayed(
        Duration(seconds: delaySeconds),
        () async {
          await _idleExecutor.enqueuePrepTool(
            'Retry "${job.fileName}"',
            () => _processJob(job),
            requiresHeavy: true,
            feature: PrepCategory.pdfIngestion.taskTypeKey,
            taskType: PrepCategory.pdfIngestion.taskTypeKey,
            subjectId: job.subjectId.isNotEmpty ? job.subjectId : null,
          );
        },
      );
    } else {
      job.status = BulkJobStatus.failed;
      job.completedAt = DateTime.now();
      job.description =
          isTransient ? 'Failed after $maxRetries retries' : 'Failed';
    }
  }

  /// Retry a previously failed job immediately.
  ///
  /// The job must be in [BulkJobStatus.failed] state. It is re-enqueued
  /// to the [IdleExecutor] and its retry count is incremented.
  Future<void> retryJob(BulkIngestionJob job) async {
    if (!job.isFailed) return;

    job.retryCount++;
    job.status = BulkJobStatus.pending;
    job.error = '';
    job.description = '';
    notifyListeners();

    await _idleExecutor.enqueuePrepTool(
      'Retry "${job.fileName}"',
      () => _processJob(job),
      requiresHeavy: true,
      feature: PrepCategory.pdfIngestion.taskTypeKey,
      taskType: PrepCategory.pdfIngestion.taskTypeKey,
      subjectId: job.subjectId.isNotEmpty ? job.subjectId : null,
    );
  }

  /// Cancel a job. If it is currently running, the underlying pipeline
  /// is cancelled via its cooperative cancel flag.
  void cancelJob(String jobId) {
    final job = _jobs.firstWhere(
      (j) => j.id == jobId,
      orElse: () => throw StateError('Job not found: $jobId'),
    );
    if (job.isCancelled || job.isCompleted) return;

    job.status = BulkJobStatus.cancelled;
    job.completedAt = DateTime.now();
    job.description = 'Cancelled';
    // The pipeline's cooperative cancel flag will cause the in-flight
    // pipeline to abort on its next cancellation checkpoint.
    _pipeline.cancel();
    notifyListeners();
  }

  /// Whether [error] represents a transient condition (rate limit, timeout,
  /// network blip) that warrants a retry.
  bool _isTransientError(String error) {
    final lower = error.normalized;
    return lower.contains('429') ||
        lower.contains('rate limit') ||
        lower.contains('too many requests') ||
        lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('econnrefused') ||
        lower.contains('etimedout');
  }

  @override
  void dispose() {
    _jobs.clear();
    _idleExecutor.dispose();
    super.dispose();
  }
}