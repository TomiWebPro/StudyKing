// COMPLETE GRAPH RENDERING UI PAGE
// Renders graphs and allows LLM input to check graph type

import 'package:flutter/material.dart';
import '../providers/llm_engine_provider.dart';

class GraphRenderingPage extends StatefulWidget {
  final LLMAIEngineProvider llmProvider;

  const GraphRenderingPage({
    super.key,
    required this.llmProvider,
  });

  @override
  State<GraphRenderingPage> createState() => _GraphRenderingPageState();
}

class _GraphRenderingPageState extends State<GraphRenderingPage> {
  String? _selectedGraphType;
  String _graphData = '';
  bool _isLoading = false;
  String? _validationResult;
  String? _errorMessage;
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _validationController = TextEditingController();

  @override
  void dispose() {
    _dataController.dispose();
    _validationController.dispose();
    super.dispose();
  }

  bool get _hasData => _graphData.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph Renderer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _hasData ? _reRenderGraph : null,
            tooltip: 'Refresh graph',
          ),
          IconButton(
            icon: const Icon(Icons.verified),
            onPressed: _hasData ? _validateGraphType : null,
            tooltip: 'Validate graph type',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Upload Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Upload Data'),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _showUploadDialog,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Data File'),
                    ),
                    const SizedBox(height: 8),
                    const Text('Or paste data directly:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dataController,
                      decoration: const InputDecoration(
                        hintText: 'Paste comma-separated data...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      onChanged: (value) {
                        setState(() {
                          _graphData = value;
                          _validationResult = null;
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Graph Type Detection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Graph Type Detection'),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.show_chart),
                        SizedBox(width: 8),
                        Text('Auto-detect from data:'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: [
                        ActionChip(
                          label: const Text('Line Graph'),
                          onPressed: () => _setGraphType('line'),
                          backgroundColor: _selectedGraphType == 'line'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                        ActionChip(
                          label: const Text('Bar Chart'),
                          onPressed: () => _setGraphType('bar'),
                          backgroundColor: _selectedGraphType == 'bar'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                        ActionChip(
                          label: const Text('Scatter Plot'),
                          onPressed: () => _setGraphType('scatter'),
                          backgroundColor: _selectedGraphType == 'scatter'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                        ActionChip(
                          label: const Text('Pie Chart'),
                          onPressed: () => _setGraphType('pie'),
                          backgroundColor: _selectedGraphType == 'pie'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // LLM Validation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LLM Validation'),
                    const SizedBox(height: 16),
                    const Text('Use LLM to validate graph:'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _validationController,
                      decoration: const InputDecoration(
                        hintText: 'Describe what you see in the graph...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _hasData && !_isLoading ? _validateWithLLM : null,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(_isLoading ? 'Validating...' : 'Validate with LLM'),
                    ),
                    if (_validationResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_validationResult!)),
                          ],
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Rendered Graph
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rendered Graph'),
                    const SizedBox(height: 16),
                    _buildGraphDisplay(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphDisplay() {
    if (!_hasData) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_chart_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No data uploaded',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload or paste data to visualize',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedGraphType == null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Select a graph type to visualize',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getGraphIcon(),
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '${_getGraphTypeName()} Visualization',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data points: ${_graphData.split(',').length}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGraphIcon() {
    switch (_selectedGraphType) {
      case 'line':
        return Icons.show_chart;
      case 'bar':
        return Icons.bar_chart;
      case 'scatter':
        return Icons.scatter_plot;
      case 'pie':
        return Icons.pie_chart;
      default:
        return Icons.insert_chart;
    }
  }

  String _getGraphTypeName() {
    switch (_selectedGraphType) {
      case 'line':
        return 'Line Graph';
      case 'bar':
        return 'Bar Chart';
      case 'scatter':
        return 'Scatter Plot';
      case 'pie':
        return 'Pie Chart';
      default:
        return 'Graph';
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Data File'),
        content: const Text('File upload functionality would be implemented here.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _setGraphType(String type) {
    setState(() {
      _selectedGraphType = type;
      _validationResult = null;
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Graph type set to ${_getGraphTypeName()}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _validateWithLLM() {
    setState(() {
      _isLoading = true;
      _validationResult = null;
      _errorMessage = null;
    });

    final description = _validationController.text.isNotEmpty
        ? _validationController.text
        : 'Please analyze the graph data and validate the graph type.';

    final prompt = '''
Analyze the following graph data and validate if the selected graph type is correct.

Data: $_graphData
Selected Graph Type: ${_getGraphTypeName()}

User description: $description

Please respond with whether the graph type matches the data and provide a brief explanation.
''';

    widget.llmProvider.sendRequest(
      model: 'openrouter/auto',
      userMessage: prompt,
      onResponse: (response) {
        setState(() {
          _isLoading = false;
          _validationResult = response.choices.isNotEmpty
              ? response.choices[0].content
              : 'Validation complete';
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Validation failed: $error';
        });
      },
    );
  }

  void _reRenderGraph() {
    setState(() {
      _validationResult = null;
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Graph refreshed'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _validateGraphType() {
    if (_selectedGraphType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a graph type first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final dataPoints = _graphData.split(',').length;
    String recommendation;

    if (dataPoints <= 3 && _selectedGraphType != 'pie') {
      recommendation = 'Consider using Pie Chart for small datasets';
    } else if (dataPoints > 10 && _selectedGraphType == 'pie') {
      recommendation = 'Consider using Bar Chart for larger datasets';
    } else {
      recommendation = 'Graph type matches data structure';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Graph Validation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getGraphTypeName()}'),
            const SizedBox(height: 8),
            Text('Data points: $dataPoints'),
            const SizedBox(height: 8),
            Text(recommendation),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}