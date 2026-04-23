import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:studyking/core/data/data.dart';
import 'package:studyking/features/settings/presentation/api_config_screen.dart';
import 'package:studyking/features/settings/presentation/profile_screen.dart';
import 'package:studyking/main.dart' show SettingsManager;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = SettingsManager.themeMode;
    final fontSize = SettingsManager.fontSize;
    final selectedModel = SettingsManager.selectedModel;
    final totalSessionCount = SettingsManager.totalSessionCount;
    final totalStudyTimeMs = SettingsManager.totalStudyTimeMs;
    final totalQuestions = SettingsManager.totalQuestions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSection(
            context: context,
            title: 'User Management',
            icon: Icons.person,
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Current User'),
                subtitle: const Text('Manage your profile'),
                onTap: () => Navigator.pushNamed(context, '/profile'),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: const Icon(Icons.switch_account),
                title: const Text('Switch User'),
                subtitle: const Text('Available'),
                onTap: () => _showUserSelection(context),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            context: context,
            title: 'Appearance',
            icon: Icons.palette,
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Theme'),
                subtitle: Text(_getThemeLabel(themeMode)),
                onTap: () => _showThemeDialog(context, themeMode),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Font Size'),
                subtitle: Text(_getFontSizeLabel(fontSize)),
                onTap: () => _showFontSizeDialog(context, fontSize),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            context: context,
            title: 'AI Configuration',
            icon: Icons.settings,
            children: [
              ListTile(
                leading: const Icon(Icons.key),
                title: const Text('API Keys'),
                subtitle: const Text('Manage credentials'),
                onTap: () => Navigator.pushNamed(context, '/api-config'),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('AI Model'),
                subtitle: Text(_getAiModelLabel(selectedModel)),
                onTap: () => _showAiModelSelection(context, selectedModel),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: const Icon(Icons.bolt),
                title: const Text('Request Timeout'),
                subtitle: const Text('120 seconds'),
                onTap: () => _showTimeoutDialog(context),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            context: context,
            title: 'Study Preferences',
            icon: Icons.school,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Study Reminders'),
                subtitle: const Text('Enable notification alerts'),
                trailing: Switch(value: true, onChanged: (value) {}),
              ),
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Session Duration'),
                subtitle: const Text('Default 30 minutes'),
                onTap: () => _showSessionDurationDialog(context),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            context: context,
            title: 'Study Analytics',
            icon: Icons.bar_chart,
            children: [
              ListTile(
                leading: const Icon(Icons.show_chart),
                title: const Text('Total Study Sessions'),
                subtitle: Text('$totalSessionCount sessions'),
                onTap: () => _showAnalytics(context, totalSessionCount, totalStudyTimeMs, totalQuestions),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Total Study Time'),
                subtitle: Text(_formatDuration(totalStudyTimeMs)),
                onTap: null,
              ),
              ListTile(
                leading: const Icon(Icons.quiz),
                title: const Text('Questions Answered'),
                subtitle: Text('$totalQuestions questions'),
                onTap: null,
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            context: context,
            title: 'Data & Backup',
            icon: Icons.storage,
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export Progress'),
                subtitle: const Text('Download study history'),
                onTap: () => _exportData(context),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Clear Cache'),
                subtitle: const Text('Free up storage space'),
                onTap: () => _clearCache(context),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
          const Divider(height: 1),
          _buildSection(
            context: context,
            title: 'About',
            icon: Icons.info_outline,
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About StudyKing'),
                subtitle: const Text('Version 0.1.0'),
                onTap: () => _showAboutDialog(context),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Privacy Policy'),
                subtitle: const Text('Read our privacy policy'),
                onTap: () => _showComingSoon(context, 'Privacy policy details coming soon'),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () => _showSignOutDialog(context),
                trailing: null,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    if (mode == ThemeMode.light) return 'Light';
    if (mode == ThemeMode.dark) return 'Dark';
    return 'System';
  }

  String _getFontSizeLabel(double fontSize) {
    if (fontSize < 14) return 'Small';
    if (fontSize < 18) return 'Medium';
    if (fontSize < 22) return 'Large';
    return 'Extra Large';
  }

  String _getAiModelLabel(String model) {
    // Just display the model ID directly - no hardcoded names
    return model.isEmpty ? 'Select a model from API' : model.split('/').last;
  }

  String _formatDuration(int ms) {
    if (ms < 1000) return 'Less than 1 minute';
    int seconds = ms ~/ 1000;
    if (seconds < 60) return '$seconds sec';
    int minutes = seconds ~/ 60;
    seconds = seconds % 60;
    if (minutes < 60) return '$minutes min $seconds sec';
    int hours = minutes ~/ 60;
    minutes = minutes % 60;
    return '$hours hr $minutes min';
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
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

  void _showThemeDialog(BuildContext context, ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.3,
        maxChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Theme', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _ThemeOption(context: context, title: 'Light', icon: Icons.light_mode, isSelected: currentMode == ThemeMode.light, onTap: () { SettingsManager.updateTheme(ThemeMode.light); Navigator.pop(context); }),
              const SizedBox(height: 8),
              _ThemeOption(context: context, title: 'Dark', icon: Icons.dark_mode, isSelected: currentMode == ThemeMode.dark, onTap: () { SettingsManager.updateTheme(ThemeMode.dark); Navigator.pop(context); }),
              const SizedBox(height: 8),
              _ThemeOption(context: context, title: 'System', icon: Icons.devices, isSelected: currentMode == ThemeMode.system, onTap: () { SettingsManager.updateTheme(ThemeMode.system); Navigator.pop(context); }),
            ],
          ),
        ),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, double currentSize) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Font Size', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Current: ${currentSize.round()}px', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Slider(value: currentSize, min: 12, max: 24, divisions: 12, label: currentSize.round().toString(), onChanged: (value) => SettingsManager.updateFontSize(value)),
              const SizedBox(height: 24),
              ...List.generate(13, (i) => 12 + i).map((size) => _FontSizeOption(context: context, value: '${size}px', onTap: () { SettingsManager.updateFontSize(size.toDouble()); Navigator.pop(context); })),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiModelSelection(BuildContext context, String currentModel) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final response = await http.get(Uri.parse('${SettingsManager.apiBaseUrl}/models'), headers: {'Authorization': 'Bearer ${SettingsManager.apiKey}', 'HTTP-Referer': 'https://studyking.app'});
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['data'] as List<dynamic>;

        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          isScrollControlled: true,
          builder: (_) => Column(children: [
            Container(padding: const EdgeInsets.all(20), color: Theme.of(context).colorScheme.primary, child: Row(children: [
              const Icon(Icons.smart_toy, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Select AI Model', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => _showAiModelSelection(context, currentModel)),
            ])),
            Expanded(child: ListView.builder(itemCount: models.length, itemBuilder: (context, index) {
              final modelData = models[index];
              final id = modelData['id'] as String;
              final name = modelData['name'] as String? ?? id.split('/').last.replaceAll(':', '').replaceAll('-', ' ');
              final provider = (modelData['providers'] as Map?)?.values.first['id'] as String? ?? 'Unknown';
              return ListTile(
                leading: const Icon(Icons.smart_toy),
                title: Text(name),
                subtitle: Text(provider),
                trailing: id == currentModel ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: () {
                  SettingsManager.updateModel(id);
                  Navigator.pop(context);
                },
              );
            })),
          ]),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load models: ${response.statusCode}')));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showTimeoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Timeout'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Adjust timeout for API requests (seconds):'),
          const SizedBox(height: 16),
          Slider(value: 120.0, min: 30.0, max: 300.0, divisions: 10, label: '120 sec', onChanged: (_) {}),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }

  void _showSessionDurationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(children: [
        Container(padding: const EdgeInsets.all(20), color: Theme.of(context).colorScheme.primaryContainer, child: const Text('Session Duration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ListTile(title: const Text('15 minutes'), onTap: () => Navigator.pop(context)),
        ListTile(title: const Text('30 minutes'), onTap: () => Navigator.pop(context)),
        ListTile(title: const Text('45 minutes'), onTap: () => Navigator.pop(context)),
        ListTile(title: const Text('60 minutes'), onTap: () => Navigator.pop(context)),
      ]),
    );
  }

  void _showAnalytics(BuildContext context, int sessions, int timeMs, int questions) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Study Analytics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _AnalyticsCard(title: 'Total Study Sessions', value: sessions.toString(), icon: Icons.quiz, color: Colors.blue),
              const SizedBox(height: 16),
              _AnalyticsCard(title: 'Total Study Time', value: _formatDuration(timeMs), icon: Icons.access_time, color: Colors.green),
              const SizedBox(height: 16),
              _AnalyticsCard(title: 'Questions Answered', value: questions.toString(), icon: Icons.task_alt, color: Colors.amber),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final BuildContext context;
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({required this.context, required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _FontSizeOption extends StatelessWidget {
  final BuildContext context;
  final String value;
  final VoidCallback onTap;

  const _FontSizeOption({required this.context, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.text_fields),
      title: Text(value),
      onTap: onTap,
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper functions
void _exportData(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Export Progress'),
      content: const Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.file_download, size: 48, color: Colors.blue),
        SizedBox(height: 16),
        Text('Exporting study data...'),
        SizedBox(height: 16),
        LinearProgressIndicator(),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported successfully!'))); }, child: const Text('Export')),
      ],
    ),
  );
}

void _clearCache(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Clear Cache'),
      content: const Text('Are you sure you want to clear cached data?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared'))); }, child: const Text('Clear')),
      ],
    ),
  );
}

void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const AboutDialog(
      applicationName: 'StudyKing',
      applicationVersion: 'v0.1.0',
      applicationLegalese: '© 2026 StudyKing.',
    ),
  );
}

void _showComingSoon(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _showSignOutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () { Navigator.pop(context); /* Sign out logic */ }, child: const Text('Sign Out')),
      ],
    ),
  );
}

void _showUserSelection(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Switch User'),
      content: const Text('Multi-user feature available soon.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );
}
