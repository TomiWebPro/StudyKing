import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/subject_model.dart';
import 'package:studyking/features/ingestion/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/ingestion/services/content_pipeline.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class UploadScreen extends StatefulWidget {
  final String? preselectedSubjectId;
  final ContentPipeline? pipeline;

  const UploadScreen({
    super.key,
    this.preselectedSubjectId,
    this.pipeline,
  });

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  final _sourceRepo = SourceRepository();

  String? _selectedSubjectId;
  List<Subject> _subjects = [];
  bool _isUploading = false;
  String? _error;
  String? _success;
  bool _useUrlInput = false;
  bool _useFilePicker = false;
  String? _selectedFilePath;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.preselectedSubjectId;
    _loadSubjects();
}

  Future<void> _loadSubjects() async {
    try {
      final repo = SubjectRepository();
      await repo.init();
      final subjects = await repo.getAll();
      if (mounted) {
        setState(() {
          _subjects = subjects;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'jpg', 'jpeg', 'png', 'docx', 'epub'],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File picker error: $e'),
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
              AppLocalizations.of(context)!.cameraError(e.toString()),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _fetchUrlContent(String url) async {
    final pipeline = widget.pipeline;
    if (pipeline == null) return;

    try {
      final result = await pipeline.fetchAndScrapeUrl(url);
      if (!mounted) return;
      if (result.isSuccess && result.data != null) {
        setState(() {
          _contentController.text = result.data!;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL content fetched successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch URL: ${result.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL fetch error: $e'),
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
      _error = null;
      _success = null;
    });

    try {
      final l10n = AppLocalizations.of(context)!;
      final pipeline = widget.pipeline;
      final sourceType = _useFilePicker
          ? _inferSourceType(_selectedFileName ?? '')
          : _useUrlInput
              ? SourceType.webPage
              : SourceType.externalResource;

      if (pipeline != null) {
        final actualContent = _useFilePicker && _selectedFilePath != null
            ? 'file://$_selectedFilePath'
            : content;

        if (fullPipeline) {
          final result = await pipeline.processFullPipeline(
            title: title,
            content: actualContent,
            type: sourceType,
            studentId: '',
            modelId: '',
            subjectId: _selectedSubjectId ?? '',
            sourceUrl: _useUrlInput ? content : '',
            possibleTopics: [],
            generateQuestions: false,
          );
          if (result.isFailure) {
            setState(() {
              _error = l10n.uploadFailed(result.error ?? '');
              _isUploading = false;
            });
            return;
          }
        } else {
          final result = await pipeline.processUpload(
            title: title,
            content: actualContent,
            type: sourceType,
            studentId: '',
            subjectId: _selectedSubjectId ?? '',
            sourceUrl: _useUrlInput ? content : '',
          );
          if (result.isFailure) {
            setState(() {
              _error = l10n.uploadFailed(result.error ?? '');
              _isUploading = false;
            });
            return;
          }
        }
      } else {
        await _sourceRepo.init();
        await _sourceRepo.create(
          Source(
            id: 'src_${DateTime.now().millisecondsSinceEpoch}',
            title: title,
            content: _useFilePicker && _selectedFilePath != null
                ? 'file://$_selectedFilePath'
                : content,
            type: sourceType,
            studentId: '',
            subjectId: _selectedSubjectId ?? '',
            sourceUrl: _useUrlInput ? content : '',
          ),
        );
      }

      setState(() {
        _success = l10n.contentUploadedSuccessfully;
        _isUploading = false;
        _titleController.clear();
        _contentController.clear();
        _urlController.clear();
        _selectedFilePath = null;
        _selectedFileName = null;
        _useFilePicker = false;
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.uploadFailed(e.toString());
        _isUploading = false;
      });
    }
  }

  SourceType _inferSourceType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
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
      case 'txt':
        return SourceType.externalResource;
      default:
        return SourceType.externalResource;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.uploadContent),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.addStudyMaterials,
                style: const TextStyle(fontSize: 16),
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
                      label: const Text('File'),
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
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('Fetch & Scrape'),
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
              const SizedBox(height: 24),

              if (_error != null)
                Container(
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
              if (_success != null)
                Container(
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
              if (_error != null || _success != null)
                const SizedBox(height: 16),

              FocusTraversalOrder(
                order: const NumericFocusOrder(5),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : () => _submitContent(),
                    icon: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isUploading
                        ? l10n.uploading
                        : l10n.uploadContent),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
