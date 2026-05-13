import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsRepository, localeProvider;
import '../data/models/settings_box.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../core/utils/logger.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final Logger _logger = const Logger('ProfileScreen');
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
        ref.read(localeProvider.notifier).state = Locale(profileData.language);
      } else if (mounted) {
        setState(() {
          _avatarIconKey = 'Icons.person';
        });
      }
    } catch (e) {
      _logger.e('Error loading profile', e);
      if (mounted) {
        setState(() {
          _avatarIconKey = 'Icons.person';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final trimmedName = _nameController.text.trim();
    final trimmedStudentId = _studentIdController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nameIsRequired)),
      );
      return;
    }
    if (trimmedStudentId.isNotEmpty && int.tryParse(trimmedStudentId) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.studentIdMustBeNumeric)),
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
          SnackBar(
            content: Text(l10n.profileSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSavingProfile(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _pickAvatar() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: ResponsiveUtils.screenPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.chooseAvatar,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarChoice(String iconKey) {
    final l10n = AppLocalizations.of(context)!;
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

    return MergeSemantics(
      child: Semantics(
        label: l10n.selectAvatar(iconKey),
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          if (_isSaving)
            ResponsiveUtils.loaderInTouchTarget()
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: l10n.save,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Semantics(
                label: l10n.chooseAvatar,
                button: true,
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
            ),
            const SizedBox(height: 32),

            // Form fields
            FocusTraversalGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: Semantics(
                      label: l10n.fullName,
                      child: _buildTextField(
                        controller: _nameController,
                        label: l10n.fullName,
                        hintText: l10n.enterYourName,
                        prefixIcon: Icons.person,
                        required: true,
                        inputFormatters: [LengthLimitingTextInputFormatter(60)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: Semantics(
                      label: l10n.studentIdOptional,
                      child: _buildTextField(
                        controller: _studentIdController,
                        label: l10n.studentIdOptional,
                        hintText: l10n.yourStudentIdNumber,
                        prefixIcon: Icons.badge,
                        inputType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: Semantics(
                      label: l10n.learningGoal,
                      child: _buildTextField(
                        controller: _learningGoalController,
                        label: l10n.learningGoal,
                        hintText: l10n.learningGoalHint,
                        prefixIcon: Icons.school,
                        inputType: TextInputType.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  FocusTraversalOrder(
                    order: const NumericFocusOrder(4),
                    child: Semantics(
                      label: l10n.preferredStudyTime,
                      child: _buildTextField(
                        controller: _studyTimeController,
                        label: l10n.preferredStudyTime,
                        hintText: l10n.preferredStudyTimeHint,
                        prefixIcon: Icons.access_time,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Account Information
            Card(
              child: Padding(
                padding: ResponsiveUtils.cardPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.accountInformation,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: l10n.language,
                      child: ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(l10n.language),
                        subtitle: Text({
                          'en': l10n.english,
                          'es': l10n.spanish,
                        }[_language] ?? _language),
                        trailing: DropdownButton<String>(
                          value: _language,
                          items: [
                            DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                            DropdownMenuItem(value: 'es', child: Text(l10n.spanish)),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _language = value);
                              ref.read(localeProvider.notifier).state = Locale(value);
                            }
                          },
                        ),
                      ),
                    ),
                    Semantics(
                      label: l10n.notifications,
                      child: SwitchListTile(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                        },
                        secondary: const Icon(Icons.notifications_active),
                        title: Text(l10n.notifications),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Delete Account Warning
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: ResponsiveUtils.cardPadding(context),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.deleteAccountWarning,
                         style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showDeleteConfirmation(context),
                      style: TextButton.styleFrom(
                         foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
               await settingsRepository.clearProfile();
               if (!context.mounted) return;
               Navigator.pop(context);
               Navigator.maybePop(context);
            },
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
