import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_config_screen.dart';
import 'package:studyking/main.dart' show SettingsManager;
import 'package:studyking/core/services/ai_model_service.dart';

class AIConfigurationSection extends ConsumerWidget {
  final String selectedModel;

  const AIConfigurationSection({super.key, required this.selectedModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModelData = ref.watch(aiModelsProvider.select((state) {
      return state.models.firstWhere(
        (m) => m.id == selectedModel,
        orElse: () => AiModel.fromId(selectedModel),
      );
    }));

    return _section(
      context: context,
      title: 'AI Configuration',
      icon: Icons.settings,
      children: [
        _buildTile(
          context: context,
          icon: Icons.key,
          color: Colors.green,
          title: 'API Keys',
          subtitle: 'Manage credentials',
          onTap: () => Navigator.pushNamed(context, '/api-config'),
        ),
        _buildTile(
          context: context,
          icon: Icons.chat,
          color: Colors.teal,
          title: 'AI Model',
          subtitle: aiModelLabel(selectedModelData),
          onTap: () => _showModelSelection(context, selectedModelData, ref),
        ),
        _buildTile(
          context: context,
          icon: Icons.bolt,
          color: Colors.amber,
          title: 'Request Timeout',
          subtitle: '120 seconds',
          onTap: () => _showTimeoutDialog(context),
        ),
      ],
    );
  }

  String aiModelLabel(AiModel model) {
    return model.name;
  }

  ListTile _buildTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _section({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  void _showModelSelection(BuildContext context, AiModel currentModel, WidgetRef ref) {
    final state = ref.read(aiModelsProvider);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primary,
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'Select AI Model',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (state.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => ref.read(aiModelsProvider.notifier).fetchModels(),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(aiModelsProvider.notifier).fetchModels(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${state.error}', style: TextStyle(color: Colors.red)),
                    ),
                  ...state.models.map((model) => _ModelOption(
                    model: model,
                    isSelected: model.id == currentModel.id,
                    onTap: () {
                      SettingsManager.updateModel(model.id);
                      Navigator.pop(context);
                    },
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Timeout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Adjust timeout for API requests (seconds):'),
            const SizedBox(height: 16),
            Slider(
              value: 120.0,
              min: 30.0,
              max: 300.0,
              divisions: 10,
              label: '120 sec',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }
}

/// Provider for AI models
final aiModelsProvider = StateNotifierProvider<AiModelsNotifier, AiModelsState>((ref) {
  return AiModelsNotifier();
});

class AiModelsNotifier extends StateNotifier<AiModelsState> {
  AiModelsNotifier() : super(const AiModelsState());

  Future<void> fetchModels() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final service = AiModelService(apiKey: ''); // Will be set from settings
      final models = await service.fetchAvailableModels();
      state = state.copyWith(models: models, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  @override
  void onClose() {
    fetchModels(); // Load models on initialization
  }
}

class AiModelsState {
  final List<AiModel> models;
  final bool isLoading;
  final String? error;

  const AiModelsState({
    this.models = const [],
    this.isLoading = true,
    this.error,
  });

  AiModelsState copyWith({
    List<AiModel>? models,
    bool? isLoading,
    String? error,
  }) {
    return AiModelsState(
      models: models ?? this.models,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class _ModelOption extends StatelessWidget {
  final AiModel model;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModelOption({
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      model.provider,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
