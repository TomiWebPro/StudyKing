// COMPLETE GRAPH RENDERING UI PAGE
// Renders graphs and allows LLM input to check graph type

import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.graphRenderer),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _hasData ? _reRenderGraph : null,
            tooltip: l10n.refreshGraph,
          ),
          IconButton(
            icon: const Icon(Icons.verified),
            onPressed: _hasData ? _validateGraphType : null,
            tooltip: l10n.validateGraphType,
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
                    Text(l10n.uploadData),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _showUploadDialog,
                      icon: const Icon(Icons.upload_file),
                      label: Text(l10n.uploadDataFile),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.orPasteDataDirectly),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dataController,
                      decoration: InputDecoration(
                        hintText: l10n.pasteDataHint,
                        border: const OutlineInputBorder(),
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
                    Text(l10n.graphTypeDetection),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.show_chart),
                        const SizedBox(width: 8),
                        Text(l10n.autoDetectFromData),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: [
                        ActionChip(
                          label: Text(l10n.lineGraph),
                          onPressed: () => _setGraphType('line'),
                          backgroundColor: _selectedGraphType == 'line'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                        ActionChip(
                          label: Text(l10n.barChart),
                          onPressed: () => _setGraphType('bar'),
                          backgroundColor: _selectedGraphType == 'bar'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                        ActionChip(
                          label: Text(l10n.scatterPlot),
                          onPressed: () => _setGraphType('scatter'),
                          backgroundColor: _selectedGraphType == 'scatter'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                        ActionChip(
                          label: Text(l10n.pieChart),
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
                    Text(l10n.llmValidation),
                    const SizedBox(height: 16),
                    Text(l10n.useLlmToValidateGraph),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _validationController,
                      decoration: InputDecoration(
                        hintText: l10n.describeWhatYouSee,
                        border: const OutlineInputBorder(),
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
                      label: Text(_isLoading ? l10n.validating : l10n.validateWithLlm),
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
                    Text(l10n.renderedGraph),
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
    final l10n = AppLocalizations.of(context)!;
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
                l10n.noDataUploaded,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.uploadOrPasteData,
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
                l10n.selectGraphType,
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
              l10n.graphVisualization(_getGraphTypeName()),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dataPointsCount(_graphData.split(',').length),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.uploadDataFileDialog),
        content: Text(l10n.fileUploadImplemented),
        actions: [
          TextButton(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _setGraphType(String type) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _selectedGraphType = type;
      _validationResult = null;
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.graphTypeSetTo(_getGraphTypeName())),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _validateWithLLM() {
    final l10n = AppLocalizations.of(context)!;
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
              : l10n.validationComplete;
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.validationFailed(error.toString());
        });
      },
    );
  }

  void _reRenderGraph() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _validationResult = null;
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.graphRefreshed),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _validateGraphType() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedGraphType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectGraphType),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final dataPoints = _graphData.split(',').length;
    String recommendation;

    if (dataPoints <= 3 && _selectedGraphType != 'pie') {
      recommendation = l10n.considerUsingPieChart;
    } else if (dataPoints > 10 && _selectedGraphType == 'pie') {
      recommendation = l10n.considerUsingBarChart;
    } else {
      recommendation = l10n.graphTypeMatchesData;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.graphValidation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.typeLabel(_getGraphTypeName())),
            const SizedBox(height: 8),
            Text(l10n.dataPointsCount(dataPoints)),
            const SizedBox(height: 8),
            Text(recommendation),
          ],
        ),
        actions: [
          TextButton(
            child: Text(l10n.ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}