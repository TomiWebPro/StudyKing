import 'package:flutter/material.dart';
import '../../models/llm_config.dart';
import '../../providers/llm_engine_provider.dart';
import 'package:provider/provider.dart';

class LLMSettingsScreen extends StatefulWidget {
  final LLMEngineProvider engineProvider;

  const LLMSettingsScreen({
    Key? key,
    required this.engineProvider,
  }) : super(key: key);

  @override
  State<LLMSettingsScreen> createState() => _LLMSettingsScreenState();
}

class _LLMSettingsScreenState extends State<LLMSettingsScreen> {
  final _apiKeysController = TextEditingController();
  final _baseUrlController = TextEditingController();

  @override
  void dispose() {
    _apiKeysController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<LLMEngineProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Settings
            _buildSectionTitle('Connection Settings'),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Radio<String>(
                        value: 'openrouter',
                        groupValue: 'openrouter',
                        onChanged: (v) => switchToOpenRouter(context),
                      ),
                      const Text('OpenRouter'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _apiKeysController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'OpenRouter API Key',
                      hintText: 'sk-or-...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: engine.configureEndpoint,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Use Saved API Key'),
                    value: engine.apiKeyConfigured,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Model Settings
            _buildSectionTitle('Model Selection'),
            _buildCard(
              child: Consumer<LLMEngineProvider>(
                builder: (context, engine, _) {
                  final models = AvailableModels.openrouterModels;

                  return Container(
                    height: 300,
                    child: ListView(
                      children: models.map((model) {
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(model.providerDisplayName[0]),
                          ),
                          title: Text(model.providerDisplayName),
                          subtitle: Text(model.formatPricing()),
                          selected: engine.selectedModel?.modelName ==
                              model.modelName,
                          onTap: () {
                            engine.setSelectedModel(model);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${model.providerDisplayName} selected'),
                      ...[truncated]
                        },
                      ).toList();
                    },
                  ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Usage Statistics
            _buildSectionTitle('Usage Statistics'),
            _buildCard(
              child: Consumer<LLMEngineProvider>(
                builder: (context, engine, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (engine.usageSummary.totalRequests > 0) ...[
                        _buildUsageRow('Requests: ${engine.usageSummary.totalRequests}'),
                        _buildUsageRow('Total Tokens: ${engine.usageSummary.totalTokens}'),
                        _buildUsageRow(
                          'Input Tokens: ${engine.usageSummary.totalInputTokens}',
                        ),
                        _buildUsageRow(
                          'Output Tokens: ${engine.usageSummary.totalOutputTokens}',
                        ),
                        _buildUsageRow(
                          'Total Cost: \$${engine.usageSummary.totalCost.toStringAsFixed(4)}',
                          isPrice: true,
                        ),
                        const SizedBox(height: 12),
                        _buildUsageRow(
                          'Avg Cost/tokens: \\\${engine.usageSummary.costPerToken.toStringAsFixed(10)}',
                        ),
                      ] else ...[
                        const Text('No usage data yet. Make a request to see statistics.'),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(context, widget.engineProvider),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildCard({Widget? child}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildUsageRow(String text, {bool isPrice = false}) {
    return Text(
      text,
      style: TextStyle(
        color: isPrice ? Theme.of(context).colorScheme.primary : null,
        fontWeight: isPrice ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, LLMEngineProvider engine) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextButton.icon(
            onPressed: () => engine.clearUsageHistory(),
            icon: const Icon(Icons.delete),
            label: const Text('Clear Usage History'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextButton.icon(
            onPressed: () => engine.resetConfiguration(),
            icon: const Icon(Icons.delete),
            label: const Text('Reset Configuration'),
          ),
        ),
      ],
    );
  }
}
