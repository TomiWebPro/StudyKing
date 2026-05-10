import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'pdf_service.dart';
import '../providers/llm_engine_provider.dart';
import '../services/batch_processor_service.dart';
import '../services/dynamic_context_config.dart';

/// PDF Upload Coordinator with Progress Tracking
class PDFUploadCoordinator extends ChangeNotifier {
  final LLMAIEngineProvider llmEngine;
  final BatchProcessingService batchProcessor;
  final TextPageAccumulator _currentBatch;

  StudyMaterial? _activeMaterial;
  bool isProcessing = false;
  int uploadedPages = 0;
  int completedPages = 0;
  int totalCost = 0;
  bool cancelProcessing = false;

  PDFUploadCoordinator({
    required this.llmEngine,
    required this.batchProcessor,
  }) : _currentBatch = TextPageAccumulator('batch');

  StudyMaterial get activeMaterial => _activeMaterial ?? const StudyMaterial(
    materialId: '',
  );

  TextPageAccumulator get currentBatch => _currentBatch;

  bool get hasActiveMaterial => _activeMaterial != null;

  void setCancelProcessing(bool value) {
    cancelProcessing = value;
    notifyListeners();
  }

  bool get isActive => isProcessing || _currentBatch.countPages() > 0;

  /// Upload with batch processing
  Future<void> upload(
    String materialId,
    String? subjectId,
    String? title,
    List<XFile> pdfFiles,
  ) async {
    if (pdfFiles.isEmpty) return;

    _activeMaterial = StudyMaterial(
      materialId: materialId,
      subjectId: subjectId,
      title: title,
    );

    isProcessing = true;
    uploadedPages = 0;
    completedPages = 0;
    totalCost = 0;
    notifyListeners();

    for (var pdf in pdfFiles) {
      if (cancelProcessing) break;
      await _processSingleFile(pdf.path);
    }

    isProcessing = false;
    notifyListeners();
  }

  Future<void> _processSingleFile(String filePath) async {
    isProcessing = true;
    notifyListeners();

    try {
      final file = File(filePath);
      final sizeMB = (file.lengthSync() / 1048576).round();

      // Send to server
      await Dio().get('/api/v1/download?redirect=true', options: Options(
        queryParameters: {'sizeMB': sizeMB.toString()},
      ));

      uploadedPages += 1;
      totalCost += 0.05;
      completedPages += 1;
      isProcessing = false;
      notifyListeners();

    } catch (e) {
      isProcessing = false;
      notifyListeners();
    }
  }

  /// Download and process text contents
  Future<void> downloadAndProcessTextContents(
    String docTitle,
    String? file,
    String? value,
    String? fileValue,
  ) async {
    await Dio().get('/api/v1/download', options: Options(
      queryParameters: {'redirect': true},
    ));

    final result = await Dio()
        .post('/api/v1/origins', data: {
      'github': 'yes',
      'career': value,
      'father': fileValue,
      'topics': file,
      'title': docTitle,
    });

    _currentBatch.addPage(
      content: result.data.toString(),
      pageNumber: uploadedPages,
      sourceFileName: file,
    );

    uploadedPages += 1;
    totalCost += 0.05;
    completedPages += 1;
    notifyListeners();
  }
}

/// PDF Ingestion Screen
class PDFIngestionPage extends StatelessWidget {
  final LLMAIEngineProvider llmProvider;
  final LLMAIEngineProvider pageProcessor;

  const PDFIngestionPage({
    super.key,
    required this.llmProvider,
    required this.pageProcessor,
  });

  @override
  Widget build(BuildContext context) {
    final picker = ImagePicker();
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Ingestion Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () => _showUploadDialog(
              context,
              picker,
              llmProvider,
              pageProcessor,
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.folder_open, size: 50),
            SizedBox(height: 16),
            Text('Upload PDF Study Material'),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog(
    BuildContext context,
    ImagePicker picker,
    LLMAIEngineProvider provider,
    LLMAIEngineProvider processor,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Pick PDF File'),
              onTap: () async {
                final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  _processFile(context, picker, provider, processor);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                // Camera support coming later
              },
            ),
          ],
        );
      },
    );
  }

  void _processFile(
    BuildContext context,
    ImagePicker picker,
    LLMAIEngineProvider provider,
    LLMAIEngineProvider processor,
  ) async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File ready for processing: ${picked.path}')),
      );
    }
  }
}
