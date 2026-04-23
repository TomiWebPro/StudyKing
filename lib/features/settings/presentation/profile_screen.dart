import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _learningGoalController = TextEditingController();
  final TextEditingController _studyTimeController = TextEditingController();

  IconData? _avatarIcon;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Load from storage - placeholder
    if (mounted) {
      setState(() {
        _avatarIcon = Icons.person;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save to storage - placeholder
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _pickAvatar() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Avatar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildAvatarChoice(Icons.face),
                  _buildAvatarChoice(Icons.person),
                  _buildAvatarChoice(Icons.school),
                  _buildAvatarChoice(Icons.local_hospital),
                  _buildAvatarChoice(Icons.leaderboard),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarChoice(IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() => _avatarIcon = icon);
        Navigator.pop(context);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: _avatarIcon == icon
              ? Border.all(color: Theme.of(context).primaryColor, width: 3)
              : null,
        ),
        child: Icon(icon, size: 32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isSaving)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                  child: _avatarIcon != null
                      ? Icon(
                          _avatarIcon!,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        )
                      : const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Name field
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hintText: 'Enter your name',
              prefixIcon: Icons.person,
              required: true,
            ),
            const SizedBox(height: 16),

            // Student ID field
            _buildTextField(
              controller: _studentIdController,
              label: 'Student ID (Optional)',
              hintText: 'Your student ID number',
              prefixIcon: Icons.badge,
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Learning Goal
            _buildTextField(
              controller: _learningGoalController,
              label: 'Learning Goal',
              hintText: 'e.g., Final Exams, Certifications',
              prefixIcon: Icons.school,
              inputType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            // Preferred Study Time
            _buildTextField(
              controller: _studyTimeController,
              label: 'Preferred Study Time',
              hintText: 'e.g., Evening (6-9 PM)',
              prefixIcon: Icons.access_time,
            ),
            const SizedBox(height: 32),

            // Account Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Language'),
                      subtitle: const Text('English'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Delete Account Warning
            Card(
              color: Colors.redAccent.withAlpha(25),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.redAccent),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Deleting your account will permanently remove all study data',
                        style: TextStyle(color: Colors.redAccent),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    TextInputType inputType = TextInputType.text,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text('*', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: inputType,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(prefixIcon),
          ),
        ),
      ],
    );
  }
}
