import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart' show settingsRepository;
import '../data/models/settings_box.dart';

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

  String? _avatarIconKey;
  bool _isSaving = false;
  String _profileId = 'default_profile';
  bool _notificationsEnabled = true;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get the settings repository from main
      final repository = settingsRepository;
      final profileData = await repository.getProfileData();
      
      if (profileData != null && mounted) {
        setState(() {
          _profileId = profileData.id;
          _avatarIconKey = profileData.avatarIcon;
          _nameController.text = profileData.name;
          _studentIdController.text = profileData.studentId ?? '';
          _learningGoalController.text = profileData.learningGoal ?? '';
          _studyTimeController.text = profileData.preferredStudyTime ?? '';
          _notificationsEnabled = profileData.notificationsEnabled;
          _language = profileData.language;
        });
      } else if (mounted) {
        setState(() {
          _avatarIconKey = 'Icons.person';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _avatarIconKey = 'Icons.person';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final trimmedName = _nameController.text.trim();
    final trimmedStudentId = _studentIdController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    if (trimmedStudentId.isNotEmpty && int.tryParse(trimmedStudentId) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student ID must be numeric')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create profile data
      final profileData = ProfileData(
        id: _profileId,
        name: trimmedName,
        studentId: trimmedStudentId.isEmpty ? null : trimmedStudentId,
        avatarIcon: _avatarIconKey,
        learningGoal: _learningGoalController.text.trim().isEmpty ? null : _learningGoalController.text.trim(),
        preferredStudyTime: _studyTimeController.text.trim().isEmpty ? null : _studyTimeController.text.trim(),
        notificationsEnabled: _notificationsEnabled,
        language: _language,
      );

      // Save to repository
      await settingsRepository.saveProfileData(profileData);

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
                  _buildAvatarChoice('Icons.face'),
                  _buildAvatarChoice('Icons.person'),
                  _buildAvatarChoice('Icons.school'),
                  _buildAvatarChoice('Icons.local_hospital'),
                  _buildAvatarChoice('Icons.leaderboard'),
                  _buildAvatarChoice('Icons.emoji_events'),
                  _buildAvatarChoice('Icons.sports_tennis'),
                  _buildAvatarChoice('Icons.coffee'),
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

  Widget _buildAvatarChoice(String iconKey) {
    IconData icon;
    switch (iconKey) {
      case 'Icons.face':
        icon = Icons.face;
        break;
      case 'Icons.school':
        icon = Icons.school;
        break;
      case 'Icons.local_hospital':
        icon = Icons.local_hospital;
        break;
      case 'Icons.leaderboard':
        icon = Icons.leaderboard;
        break;
      case 'Icons.emoji_events':
        icon = Icons.emoji_events;
        break;
      case 'Icons.sports_tennis':
        icon = Icons.sports_tennis;
        break;
      case 'Icons.coffee':
        icon = Icons.coffee;
        break;
      default:
        icon = Icons.person;
    }

    return Semantics(
      label: 'Select avatar $iconKey',
      button: true,
      child: InkWell(
        onTap: () {
          setState(() => _avatarIconKey = iconKey);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(30),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final size = 48.0 * textScale;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: _avatarIconKey == iconKey
                    ? Border.all(color: Theme.of(context).primaryColor, width: 3)
                    : null,
              ),
              child: Icon(icon, size: size * 0.533),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _learningGoalController.dispose();
    _studyTimeController.dispose();
    super.dispose();
  }

  IconData _getIconFromAvatar() {
    switch (_avatarIconKey) {
      case 'Icons.face':
        return Icons.face;
      case 'Icons.person':
        return Icons.person;
      case 'Icons.school':
        return Icons.school;
      case 'Icons.local_hospital':
        return Icons.local_hospital;
      case 'Icons.leaderboard':
        return Icons.leaderboard;
      case 'Icons.emoji_events':
        return Icons.emoji_events;
      case 'Icons.sports_tennis':
        return Icons.sports_tennis;
      case 'Icons.coffee':
        return Icons.coffee;
      default:
        return Icons.person;
    }
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
              child: InkWell(
                onTap: _pickAvatar,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ),
                  child: _avatarIconKey != null
                      ? Icon(
                          _getIconFromAvatar(),
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
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
            ),
            const SizedBox(height: 16),

            // Student ID field
            _buildTextField(
              controller: _studentIdController,
              label: 'Student ID (Optional)',
              hintText: 'Your student ID number',
              prefixIcon: Icons.badge,
              inputType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(20),
              ],
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
                      subtitle: Text(_language == 'en' ? 'English' : 'Spanish'),
                      trailing: DropdownButton<String>(
                        value: _language,
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'es', child: Text('Spanish')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _language = value);
                          }
                        },
                      ),
                    ),
                    SwitchListTile(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                      secondary: const Icon(Icons.notifications_active),
                      title: const Text('Notifications'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Delete Account Warning
            Card(
              color: _dangerColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: _dangerColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Deleting your account will permanently remove all study data',
                         style: const TextStyle(color: _dangerColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showDeleteConfirmation(context),
                      style: TextButton.styleFrom(
                         foregroundColor: _dangerColor,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your study data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
               await settingsRepository.clearProfile();
               if (!context.mounted) return;
               Navigator.pop(context);
               Navigator.maybePop(context);
            },
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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
    List<TextInputFormatter>? inputFormatters,
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
               const Text('*', style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: inputType,
          inputFormatters: inputFormatters,
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

const Color _dangerColor = Colors.redAccent;
