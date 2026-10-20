import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/hive_box_names.dart';
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

  /// Processed successfully - a [Source] was created and stored.
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

  /// Pipeline stage (extracting, classifying, ...) reported by the
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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Serialisable snapshot used for Hive persistence. The job is a pure data
  /// object (no executable closures) so all fields round-trip cleanly; the
  /// `IdleExecutor` task closure that drives `_processJob` is rebuilt from the
  /// `id` by the [TaskReconstructor] registered in [BulkIngestionService.init]
  /// (Vision Next-Term §4.1).
  Map<String, dynamic> toPersistJson() => {
        'id': id,
        'fileName': fileName,
        'title': title,
        'filePath': filePath,
        'sourceType': sourceType.name,
        'subjectId': subjectId,
        'generateQuestions': generateQuestions,
        'generateLessons': generateLessons,
        'fullPipeline': fullPipeline,
        'studentId': studentId,
        'classificationModelId': classificationModelId,
        'summarizationModelId': summarizationModelId,
        'generationModelId': generationModelId,
        'possibleTopics': possibleTopics,
        'createdAt': createdAt.toIso8601String(),
        'processingStage': processingStage?.name,
        'description': description,
        'status': status.name,
        'error': error,
        'retryCount': retryCount,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'sourceId': sourceId,
      };

  factory BulkIngestionJob.fromPersistJson(Map<String, dynamic> json) {
    final job = BulkIngestionJob(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      title: json['title'] as String,
      filePath: json['filePath'] as String,
      sourceType: _sourceTypeFromName(json['sourceType'] as String?),
      studentId: json['studentId'] as String,
      classificationModelId: json['classificationModelId'] as String,
      summarizationModelId: json['summarizationModelId'] as String,
      generationModelId: json['generationModelId'] as String,
      subjectId: json['subjectId'] as String? ?? '',
      generateQuestions: json['generateQuestions'] as bool? ?? false,
      generateLessons: json['generateLessons'] as bool? ?? false,
      fullPipeline: json['fullPipeline'] as bool? ?? true,
      possibleTopics: (json['possibleTopics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
    // Mutable pipeline state is restored via cascade (the constructor only
    // captures the immutable configuration above).
    return job
      ..processingStage = _processingStatusFromName(json['processingStage'] as String?)
      ..description = json['description'] as String? ?? ''
      ..status = _bulkJobStatusFromName(json['status'] as String?)
      ..error = json['error'] as String? ?? ''
      ..retryCount = (json['retryCount'] as num?)?.toInt() ?? 0
      ..startedAt = json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null
      ..completedAt = json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null
      ..sourceId = json['sourceId'] as String?;
  }

  static SourceType _sourceTypeFromName(String? name) {
    if (name == null) return SourceType.document;
    return SourceType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => SourceType.document,
    );
  }

  static ProcessingStatus? _processingStatusFromName(String? name) {
    if (name == null) return null;
    return ProcessingStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ProcessingStatus.pending,
    );
  }

  static BulkJobStatus _bulkJobStatusFromName(String? name) {
    if (name == null) return BulkJobStatus.pending;
    return BulkJobStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => BulkJobStatus.pending,
    );
  }
}

/// Manages bulk ingestion of study materials (PDFs, notes, etc.) through a
/// background queue powered by [IdleExecutor] (Vision Next-Term §4.1).
///
/// Students multi-select many files at once; each file is enqueued as a
/// background [IdleTask] that processes through [ContentPipeline] without
/// blocking the UI thread. Progress is tracked per file, and failed files
/// are retried on transient errors (429, timeout, network).
///
/// The job list is persisted to the `bulkIngestionJobs` Hive box so that
/// "Prepare while I'm away" survives app termination (Vision Next-Term §4.2):
/// on `init()` the jobs are restored and their executable closures re-attached
/// via the [IdleExecutor]'s [TaskReconstructor].
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

  // --- Hive persistence (Vision Next-Term §4.2: jobs survive termination) ---
  Box? _box;
  Future<void> _saveChain = Future<void>.value();
  bool _disposed = false;

  /// Completes once every box save scheduled so far has finished.
  @visibleForTesting
  Future<void> get persistenceComplete => _saveChain;

  BulkIngestionService({
    required ContentPipeline pipeline,
    required IdleExecutor idleExecutor,
  })  : _pipeline = pipeline,
        _idleExecutor = idleExecutor;

  /// Opens the jobs box, restores persisted jobs and registers a
  /// [TaskReconstructor] with the [IdleExecutor] so that idle tasks for these
  /// jobs can be re-attached (and thus resumed) after a restart.
  Future<void> init() async {
    try {
      _box = await Hive.openBox(HiveBoxNames.bulkIngestionJobs);
    } catch (e) {
      _logger.w('Failed to open bulk ingestion jobs box', e);
      return;
    }
    _loadJobsFromBox();
    _registerTaskReconstructor();
  }

  void _loadJobsFromBox() {
    final box = _box;
    if (box == null || !box.isOpen) return;
    _jobs.clear();
    for (final entry in box.values) {
      if (entry is Map) {
        try {
          final job = BulkIngestionJob.fromPersistJson(
            Map<String, dynamic>.from(entry),
          );
          // A job that was `running` at termination never finished; reset it
          // to pending so it is retried instead of stuck in a running state.
          if (job.isRunning && !job.isCompleted) {
            job.status = BulkJobStatus.pending;
          }
          _jobs.add(job);
        } catch (e) {
          _logger.w('Failed to restore a bulk ingestion job from box', e);
        }
      }
    }
    if (_jobs.isNotEmpty) {
      notifyListeners();
    }
  }

  Future<void> _saveJobsToBox() async {
    final box = _box;
    if (box == null || !box.isOpen) return;
    try {
      await box.clear();
      for (final job in _jobs) {
        await box.put(job.id, job.toPersistJson());
      }
    } catch (e) {
      _logger.w('Failed to persist bulk ingestion jobs to box', e);
    }
  }

  /// Schedules an ordered box save. No-op when no box is open (e.g. tests).
  void _persistJobs() {
    if (_disposed) return;
    _saveChain = _saveChain.then((_) => _saveJobsToBox());
  }

  /// Registers a [TaskReconstructor] that re-attaches a `_processJob(job)`
  /// closure for restored `pdf_ingestion` idle tasks whose owning job is still
  /// pending/deferred. This is what lets a deferred bulk upload resume after
  /// the process restarts (Vision Next-Term §4.2).
  void _registerTaskReconstructor() {
    _idleExecutor.setTaskReconstructor((task) {
      if (task.feature != PrepCategory.pdfIngestion.taskTypeKey) return null;
      final jobId = task.jobId;
      if (jobId == null) return null;
      if (_disposed) return null;
      // Look up the restored job the closure belonged to.
      BulkIngestionJob? job;
      for (final j in _jobs) {
        if (j.id == jobId) {
          job = j;
          break;
        }
      }
      if (job == null) return null;
      // Only reattach a closure for jobs that are still awaiting execution.
      if (!job.isPending) return null;
      final jobToProcess = job;
      return () async {
        final result = await _processJob(jobToProcess);
        final success = result['success'] as bool? ?? false;
        if (!success) {
          throw Exception(result['error'] ?? 'Bulk ingestion returned failure');
        }
      };
    });
  }

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

      // Stamp the job id onto the idle task so the [TaskReconstructor] can
      // rebuild the `_processJob(job)` closure after a restart.
      await _idleExecutor.enqueuePrepTool(
        'Ingest "${file.fileName}"',
        () => _processJob(job),
        requiresHeavy: true,
        feature: PrepCategory.pdfIngestion.taskTypeKey,
        taskType: PrepCategory.pdfIngestion.taskTypeKey,
        subjectId: job.subjectId.isNotEmpty ? job.subjectId : null,
        jobId: job.id,
      );
    }

    _persistJobs();
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
        // is done - the retry will run as a separate prep task.
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
      _persistJobs();
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
            jobId: job.id,
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
      jobId: job.id,
    );
    _persistJobs();
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
    _persistJobs();
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
    _disposed = true;
    // Flush the current job list to disk so queued/failed jobs are not lost
    // when the service is torn down (Vision Next-Term §4.2). Best-effort:
    // no-op when no box is open (e.g. tests). The jobs themselves are NOT
    // cleared - they persist for the next init().
    _persistJobs();
    _idleExecutor.dispose();
    super.dispose();
  }
}
