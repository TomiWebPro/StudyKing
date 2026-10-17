import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/providers/llm_providers.dart' show modelRouterProvider;
import 'package:studyking/core/services/llm/model_router.dart' show LlmTaskType;
import 'package:studyking/core/providers/ocr_provider.dart';
import 'package:studyking/core/data/extraction/ocr_engine.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/features/ingestion/providers/ingestion_providers.dart';
import 'package:studyking/features/ingestion/services/bulk_ingestion_service.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class UploadScreen extends ConsumerStatefulWidget {
  final String? preselectedSubjectId;
  final ContentPipeline? pipeline;
  final BulkIngestionService? bulkIngestionService;
  final String? fixedStudentId;
  final String? fixedModelId;

  const UploadScreen({
    super.key,
    this.preselectedSubjectId,
    this.pipeline,
    this.bulkIngestionService,
    this.fixedStudentId,
    this.fixedModelId,
  });

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  static final Logger _logger = const Logger('UploadScreen');
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();

  String? _selectedSubjectId;
  List<Subject> _subjects = [];
  bool _isUploading = false;
  _UploadError? _error;
  String _errorDetail = '';
  bool _uploadSucceeded = false;
  bool _useUrlInput = false;
  bool _useFilePicker = false;
  bool _generateQuestions = true;
  bool _generateLessons = false;
  bool _isSyllabus = false;
  List<XFile> _selectedFiles = [];
  ProcessingStatus? _processingStage;
  String _processingStageDescription = '';
  String? _lastSourceId;
  int _processingStageIndex = 0;
  int _processingTotalStages = 6;
  final Stopwatch _processingStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.preselectedSubjectId;
    _loadSubjects();
    // Subscribe to the background queue so the UI rebuilds as jobs transition
    // through states (pending → running → completed/failed). Only subscribe
    // when the service is injected via the widget constructor — reading from
    // the provider during initState (in tests without an override) can
    // create a real service that then gets disposed, causing use-after-free.
    widget.bulkIngestionService?.addListener(_onBulkIngestionChanged);
  }

  void _onBulkIngestionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _processingStopwatch.stop();
    widget.bulkIngestionService?.removeListener(_onBulkIngestionChanged);
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final repo = SubjectRepository();
      await repo.init();
      final subjectsResult = await repo.getAll();
      if (mounted) {
        setState(() {
          _subjects = subjectsResult.data ?? [];
        });
      }
    } catch (e) {
      _logger.w('Failed to load subjects: $e');
    }
  }

  /// Resolves the current upload error against [l10n] at build time so the
  /// message follows a locale switch instead of caching the old translation.
  String _errorMessage(AppLocalizations l10n) {
    switch (_error) {
      case _UploadError.fillRequiredFields:
        return l10n.fillRequiredFields;
      case _UploadError.modelNotConfigured:
        return l10n.modelNotConfigured;
      case _UploadError.uploadFailed:
        return l10n.uploadFailed(_errorDetail);
      case null:
        return '';
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'txt', 'md', 'jpg', 'jpeg', 'png', 'docx', 'epub',
          'mp3', 'mp4', 'wav', 'm4a', 'ogg', 'webm',
        ],
        withData: false,
        allowMultiple: true,
      );

      if (!mounted) return;
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.files
              .map((pf) => XFile(pf.path ?? '', name: pf.name))
              .toList();
          _useFilePicker = true;
        });
      }
    } catch (e) {
      _logger.w('File picker failed', e);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.filePickerError('')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
      );
      if (!mounted) return;
      if (photo != null) {
        setState(() {
          _selectedFiles = [photo];
          _useFilePicker = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.imageCaptured)),
        );
      }
    } catch (e) {
      _logger.w('Camera capture failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.cameraError(''),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  ContentPipeline _getPipeline() {
    if (widget.pipeline != null) return widget.pipeline!;
    return ref.read(contentPipelineProvider);
  }

  BulkIngestionService? _getBulkIngestionService() {
    if (widget.bulkIngestionService != null) {
      return widget.bulkIngestionService!;
    }
    // In production, read from the provider. In tests that don't override
    // the provider, this may be unavailable — fall back silently so the
    // legacy single-file pipeline path still works.
    try {
      return ref.read(bulkIngestionServiceProvider);
    } catch (e) {
      _logger.w('BulkIngestionService not available via provider: $e', e);
      return null;
    }
  }

  /// Enqueues selected files into the background queue via
  /// [BulkIngestionService]. Shows a snackbar with the count and allows
  /// the student to navigate away — processing continues in the background.
  Future<void> _enqueueBulkFiles(
    String studentId, {
    bool fullPipeline = true,
  }) async {
    final service = _getBulkIngestionService();
    if (service == null) {
      // Should not reach here — _submitContent checks service availability
      // before calling this method. But guard to avoid silent no-ops.
      _logger.w('BulkIngestionService unavailable; cannot enqueue.');
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final router = ref.read(modelRouterProvider);
    final fixedModelId = widget.fixedModelId;
    final classificationModelId =
        fixedModelId ?? router.resolve(LlmTaskType.classification);
    final summarizationModelId =
        fixedModelId ?? router.resolve(LlmTaskType.summarization);
    final generationModelId =
        fixedModelId ?? router.resolve(LlmTaskType.generation);

    List<String> possibleTopics = [];
    if (_selectedSubjectId != null && _selectedSubjectId!.isNotEmpty) {
      try {
        final topicRepo = TopicRepository();
        await topicRepo.init();
        final topicsResult = await topicRepo.getBySubject(_selectedSubjectId!);
        possibleTopics = (topicsResult.data ?? [])
            .map((t) => t.title)
            .where((t) => t.isNotEmpty)
            .toList();
      } catch (e) {
        _logger.w('Failed to load topics: $e', e);
      }
    }

    final files = _selectedFiles.map((f) {
      final fileName = f.name;
      final sourceType = _inferSourceType(fileName);
      return BulkUploadFile(
        filePath: f.path,
        fileName: fileName,
        title: _titleController.text.trim(),
        sourceType: sourceType,
        subjectId: _selectedSubjectId ?? '',
        generateQuestions: _generateQuestions,
        generateLessons: _generateLessons,
        fullPipeline: fullPipeline,
      );
    }).where((f) => f.filePath.isNotEmpty).toList();

    if (files.isEmpty) {
      setState(() => _error = _UploadError.fillRequiredFields);
      return;
    }

    final jobs = await service.enqueueBulk(
      files: files,
      studentId: studentId,
      classificationModelId: classificationModelId,
      summarizationModelId: summarizationModelId,
      generationModelId: generationModelId,
      possibleTopics: possibleTopics,
    );

    // Clear the form — files are now in the background queue.
    setState(() {
      _selectedFiles = [];
      _useFilePicker = false;
      _titleController.clear();
      _contentController.clear();
      _urlController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bulkUploadEnqueued(
            jobs.length,
            service.totalCount,
          )),
          duration: Timeouts.snackbarSuccess,
          action: SnackBarAction(
            label: l10n.viewQueue,
            onPressed: () {
              // Scroll to the background queue section
            },
          ),
          showCloseIcon: true,
        ),
      );
    }
  }

  Future<void> _fetchUrlContent(String url) async {
    final pipeline = _getPipeline();

    try {
      final result = await pipeline.fetchAndScrapeUrl(url);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      if (result.isSuccess && result.data != null) {
        setState(() {
          _contentController.text = result.data!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.urlFetchSuccess)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.urlFetchFailed(result.error ?? l10n.unknownError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      _logger.w('URL content fetch failed', e);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.urlFetchError('')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submitContent({bool fullPipeline = false}) async {
    final title = _titleController.text.trim();
    final content = _useUrlInput
        ? _urlController.text.trim()
        : _contentController.text.trim();

    // If files are selected and the background service is available, enqueue
    // them for off-period processing. Otherwise fall through to the legacy
    // single-file pipeline path (backward compatible with tests that don't
    // override `bulkIngestionServiceProvider`).
    if (_useFilePicker && _selectedFiles.isNotEmpty) {
      final service = _getBulkIngestionService();
      if (service != null) {
        final studentId = widget.fixedStudentId ??
            (ref.read(studentIdServiceProvider).getStudentId().data ?? '');
        if (studentId.isEmpty) {
          setState(() => _error = _UploadError.fillRequiredFields);
          return;
        }
        await _enqueueBulkFiles(studentId, fullPipeline: fullPipeline);
        return;
      }
      // No bulk service — fall through to legacy single-file processing.
    }

    if (title.isEmpty ||
        (!_useFilePicker && content.isEmpty)) {
      setState(() => _error = _UploadError.fillRequiredFields);
      return;
    }

    setState(() {
      _isUploading = true;
      _processingStage = null;
      _processingStageDescription = '';
      _processingStageIndex = 0;
      _processingTotalStages = 6;
      _error = null;
      _uploadSucceeded = false;
      _lastSourceId = null;
    });
    _processingStopwatch
      ..reset()
      ..start();

    try {
      final l10n = AppLocalizations.of(context)!;
      final pipeline = _getPipeline();
      final inferredType = _useFilePicker && _selectedFiles.isNotEmpty
          ? _inferSourceType(_selectedFiles.first.name)
          : _useUrlInput
              ? _inferSourceType(content)
              : SourceType.externalResource;
      final sourceType = _isSyllabus ? SourceType.syllabus : inferredType;

      if (fullPipeline || _generateQuestions || _generateLessons) {
        // Per-task model routing: classification, summarization and
        // generation each resolve through the model router (honoring
        // any per-task configuration) instead of always using the
        // globally selected model. `fixedModelId` (test hook) pins
        // all three to a single model when provided.
        final router = ref.read(modelRouterProvider);
        final fixedModelId = widget.fixedModelId;
        final classificationModelId =
            fixedModelId ?? router.resolve(LlmTaskType.classification);
        final summarizationModelId =
            fixedModelId ?? router.resolve(LlmTaskType.summarization);
        final generationModelId =
            fixedModelId ?? router.resolve(LlmTaskType.generation);
        if ((_generateQuestions || _generateLessons) &&
            (classificationModelId.isEmpty ||
                summarizationModelId.isEmpty ||
                generationModelId.isEmpty)) {
          setState(() {
            _error = _UploadError.modelNotConfigured;
            _isUploading = false;
          });
          return;
        }

        final isImage = sourceType == SourceType.image;
        final isAudioOrVideo = sourceType == SourceType.audio ||
            sourceType == SourceType.video;
        final asrEngine = ref.read(whisperAsrEngineProvider);
        final hasAsrEngine = asrEngine.isAvailable;
        // Images are processed by the on-device OCR engine unless the user
        // explicitly chose the AI-only (accurate) mode, so only warn about
        // image OCR when it actually depends on a vision-capable model.
        final ocrDependsOnAi = ref.read(ocrModeProvider) == OcrMode.accurate;
        final shouldWarn =
            (isImage && ocrDependsOnAi) || (isAudioOrVideo && !hasAsrEngine);
        if (shouldWarn && classificationModelId.isNotEmpty && mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.modelCapabilityWarningTitle),
              content: Text(l10n.modelCapabilityWarningBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.proceedAnyway),
                ),
              ],
            ),
          );
          if (!mounted) return;
          if (proceed != true) {
            setState(() {
              _error = null;
              _isUploading = false;
            });
            return;
          }
        }

        List<String> possibleTopics = [];
        if (_selectedSubjectId != null && _selectedSubjectId!.isNotEmpty) {
          try {
            final topicRepo = TopicRepository();
            await topicRepo.init();
            final topicsResult = await topicRepo.getBySubject(_selectedSubjectId!);
            possibleTopics = (topicsResult.data ?? [])
                .map((t) => t.title)
                .where((t) => t.isNotEmpty)
                .toList();
          } catch (e) {
            _logger.w('Failed to load topics: $e');
          }
        }

        final actualContent = (_useFilePicker && _selectedFiles.isNotEmpty)
            ? 'file://${_selectedFiles.first.path}'
            : content;

        final stageOrder = ProcessingStatus.values
            .where((s) => s != ProcessingStatus.pending && s != ProcessingStatus.failed)
            .map((s) => s.name)
            .toList();
        final result = await pipeline.processFullPipeline(
          title: title,
          content: actualContent,
          type: sourceType,
          studentId: widget.fixedStudentId ?? (ref.read(studentIdServiceProvider).getStudentId().data ?? ''),
          classificationModelId: classificationModelId,
          summarizationModelId: summarizationModelId,
          generationModelId: generationModelId,
          subjectId: _selectedSubjectId ?? '',
          sourceUrl: _useUrlInput ? content : '',
          possibleTopics: possibleTopics,
          generateQuestions: _generateQuestions,
          generateLessons: _generateLessons,
          onProgress: (status, description) {
            if (mounted) {
              setState(() {
                _processingStage = status;
                _processingStageDescription = description;
                _processingStageIndex = stageOrder.indexOf(status.name).clamp(0, stageOrder.length - 1);
                _processingTotalStages = stageOrder.length;
              });
            }
          },
        );
        if (!mounted) return;
        if (result.isFailure) {
          setState(() {
            _error = _UploadError.uploadFailed;
            _errorDetail = result.error ?? '';
            _isUploading = false;
          });
          _processingStopwatch.stop();
          return;
        }
        if (result.isSuccess && result.data != null) {
          _lastSourceId = result.data!.id;
        }
      } else {
        final actualContent = (_useFilePicker && _selectedFiles.isNotEmpty)
            ? 'file://${_selectedFiles.first.path}'
            : content;

        final result = await pipeline.processUpload(
          title: title,
          content: actualContent,
          type: sourceType,
          studentId: widget.fixedStudentId ?? (ref.read(studentIdServiceProvider).getStudentId().data ?? ''),
          subjectId: _selectedSubjectId ?? '',
          sourceUrl: _useUrlInput ? content : '',
        );
        if (!mounted) return;
        if (result.isFailure) {
          setState(() {
            _error = _UploadError.uploadFailed;
            _errorDetail = result.error ?? '';
            _isUploading = false;
          });
          _processingStopwatch.stop();
          return;
        }
        if (result.isSuccess && result.data != null) {
          _lastSourceId = result.data!.id;
        }
      }

      if (!mounted) return;
      _processingStopwatch.stop();
      setState(() {
        _uploadSucceeded = true;
        _isUploading = false;
        _processingStage = null;
        _processingStageDescription = '';
        _titleController.clear();
        _contentController.clear();
        _urlController.clear();
        _selectedFiles = [];
        _useFilePicker = false;
      });
      if (mounted) {
        final sourceId = _lastSourceId;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.contentUploadedSuccessfully),
            duration: Timeouts.snackbarSuccess,
            action: SnackBarAction(
              label: l10n.contentLibrary,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.contentLibrary),
            ),
            showCloseIcon: true,
          ),
        );
        if (sourceId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.postUploadGuidance),
              duration: Timeouts.snackbarSuccess,
              action: SnackBarAction(
                label: l10n.startPractice,
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.practiceSession,
                  arguments: PracticeSessionArgs(
                    subjectId: _selectedSubjectId ?? '',
                    sourceId: sourceId,
                  ),
                ),
              ),
              showCloseIcon: true,
            ),
          );
        }
        setState(() => _uploadSucceeded = false);
      }
    } catch (e) {
      _logger.w('Upload failed', e);
      _processingStopwatch.stop();
      if (!mounted) return;
      setState(() {
        _error = _UploadError.uploadFailed;
        _errorDetail = '';
        _isUploading = false;
        _processingStage = null;
        _processingStageDescription = '';
      });
    }
  }

  SourceType _inferSourceType(String name) {
    final lower = name.normalized;
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return SourceType.video;
    }
    final ext = name.split('.').last.normalized;
    switch (ext) {
      case 'pdf':
        return SourceType.pdf;
      case 'docx':
      case 'epub':
      case 'md':
        return SourceType.document;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return SourceType.image;
      case 'mp3':
      case 'wav':
      case 'm4a':
      case 'ogg':
        return SourceType.audio;
      case 'mp4':
      case 'webm':
        return SourceType.video;
      case 'txt':
        return SourceType.externalResource;
      default:
        return SourceType.externalResource;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_isUploading,
      // Navigation is blocked only during a foreground (single-file) upload.
      // Background-bulk uploads return immediately, so the student can freely
      // navigate away while jobs continue in the [IdleExecutor] queue.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!_isUploading) {
          if (mounted) Navigator.of(context).pop();
          return;
        }
        final navigator = Navigator.of(context);
        showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.uploadInProgressTitle),
            content: Text(l10n.uploadInProgressBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.stay),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.discard),
              ),
            ],
          ),
        ).then((confirmed) {
          if (confirmed == true && mounted) {
            final pipeline = _getPipeline();
            pipeline.cancel();
            setState(() {
              _isUploading = false;
              _processingStage = null;
              _processingStageDescription = '';
            });
            navigator.pop();
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.uploadContent),
        ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        physics: const AlwaysScrollableScrollPhysics(),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.addStudyMaterials,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.titleRequired,
                    hintText: l10n.titleHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSubjectId,
                  decoration: InputDecoration(
                    labelText: l10n.subjectOptional,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: '', child: Text(l10n.none)),
                    ..._subjects.map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedSubjectId = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              FocusTraversalOrder(
                order: const NumericFocusOrder(3),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.pasteText),
                      selected: !_useUrlInput && !_useFilePicker,
                      onSelected: (_) => setState(() {
                        _useUrlInput = false;
                        _useFilePicker = false;
                      }),
                    ),
                    ChoiceChip(
                      label: Text(l10n.urlLink),
                      selected: _useUrlInput,
                      onSelected: (_) => setState(() {
                        _useUrlInput = true;
                        _useFilePicker = false;
                      }),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.upload_file, size: 18),
                      label: Text(l10n.file),
                      onPressed: _pickFile,
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.camera_alt, size: 18),
                      label: Text(l10n.camera),
                      onPressed: _captureFromCamera,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_useFilePicker && _selectedFiles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_selectedFiles.length} file(s) selected',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      ..._selectedFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return Row(
                          children: [
                            const Icon(Icons.insert_drive_file, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_selectedFiles.length > 1 || index == 0)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: l10n.removeFile,
                                onPressed: () => setState(() {
                                  _selectedFiles.removeAt(index);
                                  if (_selectedFiles.isEmpty) {
                                    _useFilePicker = false;
                                  }
                                }),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

              if (!_useFilePicker)
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: _useUrlInput
                      ? Column(
                          children: [
                            TextField(
                              controller: _urlController,
                              decoration: InputDecoration(
                                labelText: l10n.urlRequired,
                                hintText: l10n.urlHint,
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton.icon(
                                icon: const Icon(Icons.download, size: 18),
                                label: Text(l10n.fetchAndScrape),
                                onPressed: () {
                                  final url = _urlController.text.trim();
                                  if (url.isNotEmpty) _fetchUrlContent(url);
                                },
                              ),
                            ),
                          ],
                        )
                      : TextField(
                          controller: _contentController,
                          decoration: InputDecoration(
                            labelText: l10n.contentRequired,
                            hintText: l10n.contentHint,
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 8,
                        ),
                ),
              const SizedBox(height: 16),

              CheckboxListTile(
                title: Text(l10n.generateQuestionsFromContent),
                subtitle: Text(l10n.generateQuestionsFromContentHint),
                value: _generateQuestions,
                onChanged: (val) {
                  setState(() => _generateQuestions = val ?? true);
                },
                controlAffinity: ListTileControlAffinity.platform,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: Text(l10n.syllabusUploadToggle),
                subtitle: Text(l10n.syllabusUploadToggleHint),
                value: _isSyllabus,
                onChanged: (val) {
                  setState(() => _isSyllabus = val ?? false);
                },
                controlAffinity: ListTileControlAffinity.platform,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: Text(l10n.generateLessonFromContent),
                subtitle: Text(l10n.generateLessonFromContentHint),
                value: _generateLessons,
                onChanged: (val) {
                  setState(() => _generateLessons = val ?? true);
                },
                controlAffinity: ListTileControlAffinity.platform,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              if (_error != null)
                Semantics(
                  liveRegion: true,
                  label: l10n.errorOccurred,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage(l10n),
                              style:
                                  TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_uploadSucceeded)
                Semantics(
                  liveRegion: true,
                  label: l10n.uploaded,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(l10n.contentUploadedSuccessfully,
                              style:
                                  TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_error != null || _uploadSucceeded)
                const SizedBox(height: 16),

              FocusTraversalOrder(
                order: const NumericFocusOrder(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isUploading ? null : () => _submitContent(fullPipeline: true),
                        icon: _isUploading
                            ? ResponsiveUtils.loaderInTouchTarget()
                            : const Icon(Icons.cloud_upload),
                        label: Text(_isUploading
                            ? l10n.uploading
                            : l10n.uploadAndAnalyze),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading
                            ? null
                            : () => _submitContent(fullPipeline: false),
                        icon: const Icon(Icons.save),
                        label: Text(l10n.saveOnly),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUploading && _processingStage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LinearProgressIndicator(
                            value: _processingTotalStages > 0
                                ? (_processingStageIndex + 1) / _processingTotalStages
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${l10n.progressStageLabel(_processingStageIndex + 1, _processingTotalStages)} — $_processingStageDescription',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.processingElapsed(_processingStopwatch.elapsed.inSeconds),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ResponsiveUtils.loaderInTouchTarget(size: 16),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _processingStageDescription,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.close, size: 18),
                                label: Text(l10n.cancel),
                                  onPressed: () {
                                    _getPipeline().cancel();
                                    setState(() {
                                      _isUploading = false;
                                      _processingStage = null;
                                      _processingStageDescription = '';
                                    });
                                  },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Background ingestion jobs — always visible when a service
              // is present so the student can see progress after navigating
              // away and returning.
              if (_getBulkIngestionService() != null) _buildBackgroundJobsSection(),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildBackgroundJobsSection() {
    final service = _getBulkIngestionService();
    if (service == null) return const SizedBox.shrink();

    final jobs = service.jobs;
    if (jobs.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.backgroundQueue,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final job = jobs[index];
            return _buildJobTile(job);
          },
        ),
      ],
    );
  }

  Widget _buildJobTile(BulkIngestionJob job) {
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = job.isCompleted;
    final isFailed = job.isFailed;
    final isRunning = job.isRunning;
    final isPending = job.isPending;

    Color? bgColor;
    if (isCompleted) {
      bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    } else if (isFailed) {
      bgColor = Theme.of(context).colorScheme.errorContainer;
    } else if (isRunning) {
      bgColor = Theme.of(context)
          .colorScheme
          .primaryContainer
          .withValues(alpha: 0.3);
    } else if (isPending) {
      bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    }

    IconData statusIcon;
    if (isCompleted) {
      statusIcon = Icons.check_circle;
    } else if (isFailed) {
      statusIcon = Icons.error;
    } else if (isRunning) {
      statusIcon = Icons.sync;
    } else {
      statusIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                size: 20,
                color: isFailed
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.fileName,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPending || isRunning)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: l10n.cancel,
                  onPressed: () {
                    _getBulkIngestionService()?.cancelJob(job.id);
                  },
                ),
            ],
          ),
          if (job.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                job.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          if (isFailed && !job.isCancelled)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.retry),
                  onPressed: () {
                    _getBulkIngestionService()?.retryJob(job);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _UploadError { fillRequiredFields, modelNotConfigured, uploadFailed }
