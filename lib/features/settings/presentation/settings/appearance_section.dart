import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/main.dart' show SettingsManager;

class AppearanceSection extends StatelessWidget {
  final ThemeMode themeMode;
  final double fontSize;

  const AppearanceSection({
    super.key,
    required this.themeMode,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return _section(
      context: context,
      title: 'Appearance',
      icon: Icons.palette,
      children: [
        _buildTile(
          context: context,
          icon: Icons.dark_mode,
          color: Colors.indigo,
          title: 'Theme',
          subtitle: _getThemeLabel(themeMode),
          onTap: () => _showThemeDialog(context),
        ),
        _buildTile(
          context: context,
          icon: Icons.text_fields,
          color: Colors.pink,
          title: 'Font Size',
          subtitle: _getFontSizeLabel(fontSize),
          onTap: () => _showFontSizeDialog(context),
        ),
      ],
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

  void _showThemeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.3,
        maxChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Theme', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _ThemeOption(
                context: context,
                title: 'Light',
                icon: Icons.light_mode,
                isSelected: themeMode == ThemeMode.light,
                onTap: () {
                  SettingsManager.updateTheme(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                context: context,
                title: 'Dark',
                icon: Icons.dark_mode,
                isSelected: themeMode == ThemeMode.dark,
                onTap: () {
                  SettingsManager.updateTheme(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                context: context,
                title: 'System',
                icon: Icons.devices,
                isSelected: themeMode == ThemeMode.system,
                onTap: () {
                  SettingsManager.updateTheme(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.35,
        maxChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Font Size', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Current: ${fontSize.round()}px', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Slider(
                value: fontSize,
                min: 12,
                max: 24,
                divisions: 12,
                label: fontSize.round().toString(),
                onChanged: (value) {
                  SettingsManager.updateFontSize(value);
                },
              ),
              const SizedBox(height: 16),
              _FontSizeOption(context: context, value: '12px', onTap: () {
                SettingsManager.updateFontSize(12);
                Navigator.pop(context);
              }),
              _FontSizeOption(context: context, value: '14px', onTap: () {
                SettingsManager.updateFontSize(14);
                Navigator.pop(context);
              }),
              _FontSizeOption(context: context, value: '16px', onTap: () {
                SettingsManager.updateFontSize(16);
                Navigator.pop(context);
              }),
              _FontSizeOption(context: context, value: '18px', onTap: () {
                SettingsManager.updateFontSize(18);
                Navigator.pop(context);
              }),
              _FontSizeOption(context: context, value: '20px', onTap: () {
                SettingsManager.updateFontSize(20);
                Navigator.pop(context);
              }),
              _FontSizeOption(context: context, value: '22px', onTap: () {
                SettingsManager.updateFontSize(22);
                Navigator.pop(context);
              }),
              _FontSizeOption(context: context, value: '24px', onTap: () {
                SettingsManager.updateFontSize(24);
                Navigator.pop(context);
              }),
              const SizedBox(height: 16),
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

  const _ThemeOption({
    required this.context,
    required this.title,
    required this.icon,
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
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
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

  const _FontSizeOption({
    required this.context,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.text_fields, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
