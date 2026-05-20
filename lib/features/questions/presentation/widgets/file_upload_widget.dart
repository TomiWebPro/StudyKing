import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class FileUploadWidget extends StatefulWidget {
  final String? currentAnswer;
  final bool isSubmitted;
  final ValueChanged<String?> onAnswerChanged;

  const FileUploadWidget({
    super.key,
    this.currentAnswer,
    this.isSubmitted = false,
    required this.onAnswerChanged,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  String? _localAnswer;

  @override
  void initState() {
    super.initState();
    _localAnswer = widget.currentAnswer;
  }

  @override
  void didUpdateWidget(covariant FileUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAnswer != widget.currentAnswer) {
      _localAnswer = widget.currentAnswer;
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        final filePath = file.path;
        final answer = filePath != null ? '$fileName||$filePath' : fileName;
        setState(() => _localAnswer = answer);
        widget.onAnswerChanged(answer);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasFile = _localAnswer != null && _localAnswer!.isNotEmpty;
    final fileName = hasFile ? _localAnswer!.split('||').first : null;
    return Semantics(
      button: true,
      label: l10n.uploadFile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: widget.isSubmitted ? null : _pickFile,
            icon: Icon(hasFile ? Icons.check_circle : Icons.upload_file),
            label: Text(hasFile ? l10n.fileAttached : l10n.uploadFile),
          ),
          if (hasFile && fileName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                fileName,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
