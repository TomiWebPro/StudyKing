import 'package:flutter/material.dart';
import '../providers/llm_engine_provider.dart';

/// Main PDF ingestion page with upload and processing UI
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Ingestion Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _showUploadDialog(context, llmProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Configure PDF Processing Settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            // Model Selection
            Card(
              child: ListTile(
                leading: const Icon(Icons.memory),
                title: const Text('Select LLM Model'),
                subtitle: const Text('Choose the model for PDF processing'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    llmProvider.setApiKey('YOUR_API_KEY');
                  },
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem(value: 'claude', child: Text('Claude 3.5 Sonnet')),
                      const PopupMenuItem(value: 'gemini', child: Text('Gemini 1.5 Pro')),
                      const PopupMenuItem(value: 'llama', child: Text('Llama 3.1 405B')),
                    ];
                  },
                ),
              ),
            ),
            // Batch Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history),
                        SizedBox(width: 8),
                        Text('Batch Processing Settings'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Pages per batch:'),
                    Slider(
                      value: 10,
                      min: 1,
                      max: 16,
                      divisions: 15,
                      onChanged: (value) {
                        _updateContextWindow(value.round());
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('Processing queue:'),
                    Row(
                      children: [
                        Slider(
                          value: 50,
                          max: 200,
                          divisions: 150,
                          onChanged: (val) {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context, LLMAIEngineProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload PDF Study Material'),
        content: const Text('Select PDF file to process...'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _updateContextWindow(int batchSize) {
    // Adjust context window based on batch size
  }
}
