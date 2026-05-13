import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/data/enums.dart';
import '../../../core/data/repositories/source_repository.dart';
import '../../../core/utils/responsive.dart';
import '../../subjects/data/repositories/subject_repository.dart';
import '../../subjects/data/models/subject_model.dart';
import '../services/content_pipeline.dart';
import '../../../l10n/generated/app_localizations.dart';

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
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1920);
      if (!mounted) return;
      if (photo != null) {
        setState(() {
          _contentController.text = 'Image captured: ${photo.path}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image captured. You can add notes in the content field above.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e'), backgroundColor: Colors.red),
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
            _error = result.error;
            _isUploading = false;
          });
          return;
        }
      } else {
        await _sourceRepo.init();
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
    return       Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.uploadContent),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.addStudyMaterials,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.titleRequired,
                hintText: AppLocalizations.of(context)!.titleHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
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
            const SizedBox(height: 16),

            Row(
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
                ChoiceChip(
                  label: Text(AppLocalizations.of(context)!.camera),
                  selected: false,
                  onSelected: (_) => _captureFromCamera(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_useUrlInput)
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.urlRequired,
                  hintText: AppLocalizations.of(context)!.urlHint,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              )
            else
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.contentRequired,
                  hintText: AppLocalizations.of(context)!.contentHint,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
              ),
            const SizedBox(height: 24),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_success!, style: const TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ),
            if (_error != null || _success != null)
              const SizedBox(height: 16),

            SizedBox(
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
          ],
        ),
      ),
    );
  }
}
