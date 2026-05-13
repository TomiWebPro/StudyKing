import 'package:flutter/material.dart';
import '../../../core/data/enums.dart';
import '../../../core/data/repositories/source_repository.dart';
import '../../../core/utils/responsive.dart';
import '../../subjects/data/repositories/subject_repository.dart';
import '../../subjects/models/subject_model.dart';
import '../services/content_pipeline.dart';

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

  Future<void> _submitContent() async {
    final title = _titleController.text.trim();
    final content = _useUrlInput ? _urlController.text.trim() : _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
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
        _success = 'Content uploaded successfully!';
        _isUploading = false;
        _titleController.clear();
        _contentController.clear();
        _urlController.clear();
      });
    } catch (e) {
      setState(() {
        _error = 'Upload failed: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add study materials to your library',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g. Chapter 5 Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedSubjectId,
              decoration: const InputDecoration(
                labelText: 'Subject (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('None')),
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
                  label: const Text('Paste Text'),
                  selected: !_useUrlInput,
                  onSelected: (_) => setState(() => _useUrlInput = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('URL / Link'),
                  selected: _useUrlInput,
                  onSelected: (_) => setState(() => _useUrlInput = true),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_useUrlInput)
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL *',
                  hintText: 'https://example.com/notes',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              )
            else
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  hintText: 'Paste your study material here...',
                  border: OutlineInputBorder(),
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
                label: Text(_isUploading ? 'Uploading...' : 'Upload Content'),
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
