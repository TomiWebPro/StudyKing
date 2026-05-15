import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/data/models/source_model.dart';
import 'package:studyking/features/ingestion/data/repositories/source_repository.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/models/subject_model.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.preselectedSubjectId;
    _loadSubjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
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

  Future<void> _captureFromCamera() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1920);
      if (!mounted) return;
      if (photo != null) {
        setState(() {
          _contentController.text = '${l10n.imageCaptured}: ${photo.path}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.imageCaptured)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cameraError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitContent() async {
    final title = _titleController.text.trim();
    final content = _useUrlInput ? _urlController.text.trim() : _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.fillRequiredFields);
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
      _success = null;
    });

    try {
      final pipeline = widget.pipeline;
      if (pipeline != null) {
        final result = await pipeline.processUpload(
          title: title,
          content: content,
          type: SourceType.externalResource,
          studentId: '',
          subjectId: _selectedSubjectId ?? '',
          sourceUrl: _useUrlInput ? content : '',
        );
        if (result.isFailure) {
          setState(() {
            _error = AppLocalizations.of(context)!.uploadFailed(result.error ?? '');
            _isUploading = false;
          });
          return;
        }
      } else {
        await _sourceRepo.init();
        await _sourceRepo.create(
          Source(
            id: 'src_${DateTime.now().millisecondsSinceEpoch}',
            title: title,
            content: content,
            type: SourceType.externalResource,
            studentId: '',
            subjectId: _selectedSubjectId ?? '',
            sourceUrl: _useUrlInput ? content : '',
          ),
        );
      }

      setState(() {
        _success = AppLocalizations.of(context)!.contentUploadedSuccessfully;
        _isUploading = false;
        _titleController.clear();
        _contentController.clear();
        _urlController.clear();
      });
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context)!.uploadFailed(e.toString());
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.uploadContent),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: FocusTraversalGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.addStudyMaterials,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.titleRequired,
                    hintText: AppLocalizations.of(context)!.titleHint,
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
                    labelText: AppLocalizations.of(context)!.subjectOptional,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: '', child: Text(AppLocalizations.of(context)!.none)),
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
                child: Semantics(
                  label: _useUrlInput ? AppLocalizations.of(context)!.urlLink : AppLocalizations.of(context)!.pasteText,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text(AppLocalizations.of(context)!.pasteText),
                        selected: !_useUrlInput,
                        onSelected: (_) => setState(() => _useUrlInput = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(AppLocalizations.of(context)!.urlLink),
                        selected: _useUrlInput,
                        onSelected: (_) => setState(() => _useUrlInput = true),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        button: true,
                        label: AppLocalizations.of(context)!.camera,
                        child: ActionChip(
                          avatar: const Icon(Icons.camera_alt, size: 18),
                          label: Text(AppLocalizations.of(context)!.camera),
                          onPressed: _captureFromCamera,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

            FocusTraversalOrder(
              order: const NumericFocusOrder(4),
              child: _useUrlInput
                  ? TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.urlRequired,
                        hintText: AppLocalizations.of(context)!.urlHint,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    )
                  : TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.contentRequired,
                        hintText: AppLocalizations.of(context)!.contentHint,
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
                    Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  ],
                ),
              ),
            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_success!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
                  onPressed: _isUploading ? null : _submitContent,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isUploading ? AppLocalizations.of(context)!.uploading : AppLocalizations.of(context)!.uploadContent),
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
