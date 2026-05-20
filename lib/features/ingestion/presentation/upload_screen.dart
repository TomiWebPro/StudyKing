import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studyking/core/utils/string_extensions.dart';
import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/core/providers/app_providers.dart' show selectedModelProvider;
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/features/ingestion/providers/ingestion_providers.dart' show contentPipelineProvider;
import 'package:studyking/l10n/generated/app_localizations.dart';

class UploadScreen extends ConsumerStatefulWidget {
  final String? preselectedSubjectId;
  final ContentPipeline? pipeline;
  final String? fixedStudentId;
  final String? fixedModelId;

  const UploadScreen({
    super.key,
    this.preselectedSubjectId,
    this.pipeline,
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
  String? _error;
  String? _success;
  bool _useUrlInput = false;
  bool _useFilePicker = false;
  bool _generateQuestions = true;
  bool _generateLessons = false;
  bool _isSyllabus = false;
  String? _selectedFilePath;
  String? _selectedFileName;
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
  }

  @override
  void dispose() {
    _processingStopwatch.stop();
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'txt', 'md', 'jpg', 'jpeg', 'png', 'docx', 'epub',
          'mp3', 'mp4', 'wav', 'm4a', 'ogg', 'webm',
        ],
        withData: false,
      );

      if (!mounted) return;
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
          _useFilePicker = true;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.filePickerError('')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
          _selectedFilePath = photo.path;
          _selectedFileName = photo.name;
          _useFilePicker = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.imageCaptured)),
        );
      }
    } catch (e) {
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

    if (title.isEmpty ||
        (!_useFilePicker && content.isEmpty) ||
        (_useFilePicker && _selectedFilePath == null)) {
      setState(() => _error = AppLocalizations.of(context)!.fillRequiredFields);
      return;
    }

    setState(() {
      _isUploading = true;
      _processingStage = null;
      _processingStageDescription = '';
      _processingStageIndex = 0;
      _processingTotalStages = 6;
      _error = null;
      _success = null;
      _lastSourceId = null;
    });
    _processingStopwatch
      ..reset()
      ..start();

    try {
      final l10n = AppLocalizations.of(context)!;
      final pipeline = _getPipeline();
      final inferredType = _useFilePicker
          ? _inferSourceType(_selectedFileName ?? '')
          : _useUrlInput
              ? _inferSourceType(content)
              : SourceType.externalResource;
      final sourceType = _isSyllabus ? SourceType.syllabus : inferredType;

      if (fullPipeline || _generateQuestions || _generateLessons) {
        final resolvedModelId = widget.fixedModelId != null
            ? widget.fixedModelId!
            : ref.read(selectedModelProvider);
        if ((_generateQuestions || _generateLessons) && resolvedModelId.isEmpty) {
          setState(() {
            _error = l10n.modelNotConfigured;
            _isUploading = false;
          });
          return;
        }

        final isImageOrAudio = sourceType == SourceType.image ||
            sourceType == SourceType.audio ||
            sourceType == SourceType.video;
        if (isImageOrAudio && resolvedModelId.isNotEmpty && mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.modelCapabilityWarningTitle),
              content: Text(isImageOrAudio
                  ? l10n.modelCapabilityWarningBody
                  : l10n.modelCapabilityWarningBody),
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

        final actualContent = _useFilePicker && _selectedFilePath != null
            ? 'file://$_selectedFilePath'
            : content;

        final stageOrder = [
          'extracting', 'classifying', 'summarizing',
          'generatingQuestions', 'validating', 'completed',
        ];
        final result = await pipeline.processFullPipeline(
          title: title,
          content: actualContent,
          type: sourceType,
          studentId: widget.fixedStudentId ?? ref.read(studentIdServiceProvider).getStudentId(),
          modelId: resolvedModelId,
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
        if (result.isFailure) {
          setState(() {
            _error = l10n.uploadFailed(result.error ?? '');
            _isUploading = false;
          });
          _processingStopwatch.stop();
          return;
        }
        if (result.isSuccess && result.data != null) {
          _lastSourceId = result.data!.id;
        }
      } else {
        final actualContent = _useFilePicker && _selectedFilePath != null
            ? 'file://$_selectedFilePath'
            : content;

        final result = await pipeline.processUpload(
          title: title,
          content: actualContent,
          type: sourceType,
          studentId: widget.fixedStudentId ?? ref.read(studentIdServiceProvider).getStudentId(),
          subjectId: _selectedSubjectId ?? '',
          sourceUrl: _useUrlInput ? content : '',
        );
        if (result.isFailure) {
          setState(() {
            _error = l10n.uploadFailed(result.error ?? '');
            _isUploading = false;
          });
          _processingStopwatch.stop();
          return;
        }
        if (result.isSuccess && result.data != null) {
          _lastSourceId = result.data!.id;
        }
      }

      _processingStopwatch.stop();
      setState(() {
        _success = l10n.contentUploadedSuccessfully;
        _isUploading = false;
        _processingStage = null;
        _processingStageDescription = '';
        _titleController.clear();
        _contentController.clear();
        _urlController.clear();
        _selectedFilePath = null;
        _selectedFileName = null;
        _useFilePicker = false;
      });
      if (mounted) {
        final sourceId = _lastSourceId;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_success!),
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
        setState(() => _success = null);
      }
    } catch (e) {
      _processingStopwatch.stop();
      setState(() {
        _error = AppLocalizations.of(context)!.uploadFailed('');
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

              if (_useFilePicker && _selectedFileName != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFileName!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: l10n.close,
                        onPressed: () => setState(() {
                          _selectedFilePath = null;
                          _selectedFileName = null;
                          _useFilePicker = false;
                        }),
                      ),
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
                          child: Text(_error!,
                              style:
                                  TextStyle(color: Theme.of(context).colorScheme.error)),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_success != null)
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
                          child: Text(_success!,
                              style:
                                  TextStyle(color: Theme.of(context).colorScheme.primary)),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_error != null || _success != null)
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
