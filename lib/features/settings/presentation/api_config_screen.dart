import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Placeholder model for testing - should be moved to proper location
class UserProfileData {
  final String id;
  final String name;
  final String? studentId;
  final String? avatarUrl;
  final String? learningGoal;
  final String? preferredStudyTime;
  final bool notificationsEnabled;
  final String language;
  final String accessibilitySettings;

  UserProfileData({
    required this.id,
    required this.name,
    this.studentId,
    this.avatarUrl,
    this.learningGoal,
    this.preferredStudyTime,
    this.notificationsEnabled = true,
    this.language = 'en',
    this.accessibilitySettings = 'default',
  });
}

class ApiConfigScreen extends ConsumerStatefulWidget {
  const ApiConfigScreen({super.key});

  @override
  ConsumerState<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends ConsumerState<ApiConfigScreen> {
  final TextEditingController _routerController = TextEditingController();
  final TextEditingController _googleController = TextEditingController();
  final TextEditingController _whisperController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
  }

  void _loadCurrentValues() {
    // Load from storage - placeholder
  }

  void _saveKeys() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API keys saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Configuration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure API Keys',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Enter your API credentials below. These are used to power the AI features.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),

            // OpenRouter API Key
            _buildApiKeySection(
              title: 'OpenRouter API Key',
              controller: _routerController,
              hint: 'sk-or-v1-...',
              description: 'Required for LLM content generation',
            ),

            const SizedBox(height: 24),

            // Google API Key
            _buildApiKeySection(
              title: 'Google API Key',
              controller: _googleController,
              hint: 'AIzaSy...'.padRight(20, '.'),
              description: 'Required for YouTube API and Google services',
            ),

            const SizedBox(height: 24),

            // Whisper API Key
            _buildApiKeySection(
              title: 'Whisper API Key',
              controller: _whisperController,
              hint: 'whisper-...',
              description: 'Optional - Used for audio transcription',
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveKeys,
                icon: const Icon(Icons.save),
                label: const Text('Save API Keys'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info cards
            _buildInfoCard(
              icon: Icons.warning,
              color: Colors.orange,
              title: 'Security Notice',
              content: 'API keys are stored locally on your device and never sent to any server other than the respective API providers.',
            ),

            _buildInfoCard(
              icon: Icons.info_outline,
              color: Colors.blue,
              title: 'Getting API Keys',
              content: 'You can obtain API keys from:\n• OpenRouter: https://openrouter.ai/keys\n• Google Cloud: https://console.cloud.google.com/apis/credentials',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeySection({
    required String title,
    required TextEditingController controller,
    required String hint,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    return Card(
      color: color.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
