import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/config/locale_config.dart';
import 'package:studyking/core/utils/responsive.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsRepositoryProvider, localeProvider;
import '../data/models/user_profile_model.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../core/utils/logger.dart';
import 'package:studyking/core/widgets/widgets.dart';

extension _AppLocaleLabel on AppLocale {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    AppLocale.en => l10n.localeEn,
    AppLocale.es => l10n.localeEs,
  };
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static final Logger _logger = const Logger('ProfileScreen');
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _learningGoalController = TextEditingController();

  String? _avatarIconKey;
  bool _isLoading = true;
  String? _error;
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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repository = ref.read(settingsRepositoryProvider);
      final profileResult = await repository.getProfileData();

      if (profileResult.isFailure) {
        _logger.w('Error loading profile: ${profileResult.error}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = profileResult.error;
            _avatarIconKey = 'Icons.person';
          });
        }
        return;
      }

      final profile = profileResult.data;
      if (profile != null && mounted) {
        setState(() {
          _isLoading = false;
          _profileId = profile.id;
          _avatarIconKey = profile.avatarIcon;
          _nameController.text = profile.name;
          _learningGoalController.text = profile.learningGoal ?? '';
          _notificationsEnabled = profile.notificationsEnabled;
          _language = profile.language;
        });
        ref.read(localeProvider.notifier).state = Locale(profile.language);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _avatarIconKey = 'Icons.person';
        });
      }
    } catch (e) {
      _logger.w('Error loading profile', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = AppLocalizations.of(context)!.somethingWentWrong;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nameIsRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Create profile data
      final profile = UserProfile(
        id: _profileId,
        name: trimmedName,
        avatarIcon: _avatarIconKey,
        learningGoal: _learningGoalController.text.trim().isEmpty ? null : _learningGoalController.text.trim(),
        notificationsEnabled: _notificationsEnabled,
        language: _language,
      );

      // Save to repository
      final saveResult = await ref.read(settingsRepositoryProvider).saveProfileData(profile);
      if (saveResult.isFailure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorSavingProfile(saveResult.error!))),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileSavedSuccessfully),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _logger.w('Error saving profile', e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.somethingWentWrong)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  static const double _avatarOptionSize = 64;
  static const double _avatarOptionSpacing = 12;

  static const Map<String, IconData> _avatarOptions = {
    'Icons.person': Icons.person,
    'Icons.face': Icons.face,
    'Icons.school': Icons.school,
    'Icons.local_hospital': Icons.local_hospital,
    'Icons.leaderboard': Icons.leaderboard,
    'Icons.emoji_events': Icons.emoji_events,
    'Icons.sports_tennis': Icons.sports_tennis,
    'Icons.coffee': Icons.coffee,
    'Icons.pets': Icons.pets,
    'Icons.science': Icons.science,
    'Icons.music_note': Icons.music_note,
    'Icons.book': Icons.book,
    'Icons.computer': Icons.computer,
    'Icons.favorite': Icons.favorite,
    'Icons.star': Icons.star,
    'Icons.work': Icons.work,
  };

  static IconData _iconForKey(String iconKey) => _avatarOptions[iconKey] ?? Icons.person;

  void _pickAvatar() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.screenPadding(context).copyWith(top: 24, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.chooseAvatar,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: _avatarOptionSpacing,
                runSpacing: _avatarOptionSpacing,
                children: [
                  for (final iconKey in _avatarOptions.keys) _buildAvatarChoice(iconKey),
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
    final l10n = AppLocalizations.of(context);
    final IconData icon = _iconForKey(iconKey);
    final bool isSelected = _avatarIconKey == iconKey;
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    return Semantics(
      label: l10n?.selectAvatar(iconKey) ?? 'Select avatar $iconKey',
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () {
          setState(() => _avatarIconKey = iconKey);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(_avatarOptionSize / 2),
        child: Container(
          width: _avatarOptionSize,
          height: _avatarOptionSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? primary : colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: isSelected ? primary : colorScheme.outlineVariant,
              width: isSelected ? 3 : 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
              if (isSelected)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.onPrimary,
                      border: Border.all(color: primary, width: 2),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _learningGoalController.dispose();
    super.dispose();
  }

  IconData _getIconFromAvatar() => _iconForKey(_avatarIconKey ?? 'Icons.person');

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: LoadingScreen());
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profile)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                l10n.somethingWentWrong,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadUserData,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

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
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Semantics(
                label: l10n.chooseAvatar,
                button: true,
                child: InkWell(
                  key: const Key('avatarPickerTrigger'),
                  onTap: _pickAvatar,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    child: _avatarIconKey != null
                        ? Icon(
                            _getIconFromAvatar(),
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : Icon(
                            Icons.person,
                            size: 50,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        subtitle: Text(
                          AppLocale.values
                              .where((l) => l.locale.languageCode == _language)
                              .firstOrNull
                              ?.displayName ?? _language),
                        trailing: DropdownButton<String>(
                          value: _language,
                          items: AppLocale.values.map((appLocale) {
                            return DropdownMenuItem(
                              value: appLocale.locale.languageCode,
                              child: Text(appLocale.localizedLabel(l10n)),
                            );
                          }).toList(),
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
              final clearResult = await ref.read(settingsRepositoryProvider).clearProfile();
              if (clearResult.isFailure) return;
              if (!context.mounted) return;
              Navigator.of(context).pop();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.profileDeleted)),
              );
              if (!context.mounted) return;
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/dashboard',
                  (route) => false,
                );
              }
            },
            style: FilledButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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
               Semantics(
                 label: AppLocalizations.of(context)!.requiredField,
                  child: Text(AppLocalizations.of(context)!.requiredFieldIndicator, style: TextStyle(color: Theme.of(context).colorScheme.error)),
               ),
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
