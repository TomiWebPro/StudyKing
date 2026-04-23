import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/main.dart' show SettingsManager;

class UserManagementSection extends StatelessWidget {
  const UserManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'User Management',
      icon: Icons.person,
      children: [
        _buildTile(
          context: context,
          icon: Icons.account_circle,
          color: Colors.blue,
          title: 'Current User',
          subtitle: 'Manage your profile',
          onTap: () => Navigator.pushNamed(context, '/profile'),
        ),
        _buildTile(
          context: context,
          icon: Icons.switch_account,
          color: Colors.purple,
          title: 'Switch User',
          subtitle: 'Available',
          onTap: () => _showUserSelection(context),
        ),
      ],
    );
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

  void _showUserSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch User'),
        content: const Text('Multi-user switching feature is now available. Please select a user from the login screen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
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
}
