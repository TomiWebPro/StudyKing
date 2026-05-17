import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _dontShowAgainKey = 'onboarding_dont_show_again';

  static Future<bool> isOnboardingNeeded() async {
    final box = await Hive.openBox(HiveBoxNames.settings);
    final completed = box.get(_onboardingKey, defaultValue: false) as bool;
    final dontShow = box.get(_dontShowAgainKey, defaultValue: false) as bool;
    return !completed && !dontShow;
  }

  static Future<void> markCompleted() async {
    final box = await Hive.openBox(HiveBoxNames.settings);
    await box.put(_onboardingKey, true);
  }

  static Future<void> markDontShowAgain() async {
    final box = await Hive.openBox(HiveBoxNames.settings);
    await box.put(_dontShowAgainKey, true);
  }

  static Future<bool> isFirstLaunch() async {
    final box = await Hive.openBox(HiveBoxNames.settings);
    return !(box.get(_onboardingKey, defaultValue: false) as bool);
  }
}

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.rocket_launch, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(l10n.welcomeToStudyKing),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.onboardingDescription),
            const SizedBox(height: 16),
            _buildFeature(l10n.subjects, l10n.onboardingSubjectsDesc, Icons.school),
            const SizedBox(height: 8),
            _buildFeature(l10n.practice, l10n.onboardingPracticeDesc, Icons.play_arrow),
            const SizedBox(height: 8),
            _buildFeature(l10n.mentor, l10n.onboardingMentorDesc, Icons.auto_awesome),
            const SizedBox(height: 8),
            _buildFeature(l10n.focusMode, l10n.onboardingFocusDesc, Icons.timer),
            const SizedBox(height: 8),
            _buildFeature(l10n.settings, l10n.onboardingSettingsDesc, Icons.settings),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.needApiKeyNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Semantics(
          button: true,
          checked: _dontShowAgain,
          label: l10n.dontShowAgain,
          child: CheckboxListTile(
            value: _dontShowAgain,
            onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
            title: Text(l10n.dontShowAgain, style: theme.textTheme.bodySmall),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        FocusTraversalGroup(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  if (_dontShowAgain) {
                    await OnboardingService.markDontShowAgain();
                  } else {
                    await OnboardingService.markCompleted();
                  }
                  if (!context.mounted) return;
                  Navigator.pushNamed(context, AppRoutes.subjectSelection);
                },
                child: Text(l10n.addSubject),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  if (_dontShowAgain) {
                    await OnboardingService.markDontShowAgain();
                  } else {
                    await OnboardingService.markCompleted();
                  }
                  if (!context.mounted) return;
                  Navigator.pushNamed(context, AppRoutes.quickGuide);
                },
                child: Text(l10n.quickGuide),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () async {
                  await OnboardingService.markCompleted();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: Text(l10n.getStarted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(String title, String description, IconData icon) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: title,
                  child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Semantics(
                  label: description,
                  child: Text(description, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ApiKeyBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const ApiKeyBanner({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MaterialBanner(
      content: Text(l10n.apiKeyNeeded),
      leading: const Icon(Icons.key, color: Colors.orange),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.apiConfig);
          },
          child: Text(l10n.configureNow),
        ),
        TextButton(
          onPressed: onDismiss,
          child: Text(l10n.dismiss),
        ),
      ],
    );
  }
}

class LocalDataNotice extends StatelessWidget {
  const LocalDataNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.dataStorageNotice),
      content: Text(l10n.dataStorageDescription),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.iUnderstand),
        ),
      ],
    );
  }
}
