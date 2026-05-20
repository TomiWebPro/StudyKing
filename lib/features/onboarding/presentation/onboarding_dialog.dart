import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/providers/app_providers.dart' show settingsProvider;
import 'package:studyking/core/routes/app_router.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../services/onboarding_service.dart';

class OnboardingDialog extends ConsumerStatefulWidget {
  final OnboardingService? service;

  const OnboardingDialog({super.key, this.service});

  @override
  ConsumerState<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends ConsumerState<OnboardingDialog> {
  static final Logger _logger = const Logger('OnboardingDialog');
  bool _dontShowAgain = false;
  final _pageController = PageController();
  int _currentPage = 0;
  bool _apiKeyExpanded = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  OnboardingService get _service =>
      widget.service ?? OnboardingService();

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final service = _service;
    try {
      if (_dontShowAgain) {
        await service.markDontShowAgain();
      } else {
        await service.markCompleted();
      }
    } catch (e) {
      _logger.w('Failed to complete onboarding', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.somethingWentWrong ?? 'Something went wrong')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final reduceMotion = ref.watch(settingsProvider).reduceMotion;
    final pages = _buildPages(l10n, theme);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 360,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: pages,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  return Semantics(
                    label: l10n.pageIndicatorAria(i + 1, pages.length),
                    selected: _currentPage == i,
                    child: reduceMotion
                        ? Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            await _completeOnboarding();
                            if (!context.mounted) return;
                            Navigator.pushNamed(context, AppRoutes.dashboard);
                          },
                    child: _isSaving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.skip),
                  ),
                  Row(
                    children: [
                      if (_currentPage < pages.length - 1)
                        FilledButton(
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: Text(l10n.next),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  await _completeOnboarding();
                                  if (!context.mounted) return;
                                  Navigator.pushNamed(context, AppRoutes.dashboard);
                                },
                          icon: _isSaving
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                                )
                              : const Icon(Icons.rocket_launch),
                          label: Text(_isSaving ? l10n.pleaseWait : l10n.getStarted),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPages(AppLocalizations l10n, ThemeData theme) {
    return [
      _buildPage(
        icon: Icons.school,
        title: l10n.subjects,
        description: l10n.onboardingSubjectsDesc,
        theme: theme,
      ),
      _buildPage(
        icon: Icons.play_arrow,
        title: l10n.practice,
        description: l10n.onboardingPracticeDesc,
        theme: theme,
      ),
      _buildPage(
        icon: Icons.auto_awesome,
        title: l10n.mentor,
        description: l10n.onboardingMentorDesc,
        theme: theme,
      ),
      _buildApiKeyPage(l10n, theme),
      _buildPage(
        icon: Icons.menu_book,
        title: l10n.focusMode,
        description: l10n.onboardingFocusDesc,
        theme: theme,
      ),
      _buildPage(
        icon: Icons.settings,
        title: l10n.settings,
        description: l10n.onboardingSettingsDesc,
        theme: theme,
      ),
    ];
  }

  Widget _buildApiKeyPage(AppLocalizations l10n, ThemeData theme) {
    final expanded = _apiKeyExpanded;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.key, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            l10n.aiConfiguration,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.needApiKeyNotice,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _apiKeyExpanded = !_apiKeyExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.whatIsApiKey,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.whatIsApiKeyDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ApiKeyBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback? onDontShowAgain;

  const ApiKeyBanner({super.key, required this.onDismiss, this.onDontShowAgain});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.key, color: theme.colorScheme.error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.apiKeyNeeded,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.apiConfig);
                },
                child: Text(l10n.configureNow),
              ),
              if (onDontShowAgain != null)
                TextButton(
                  onPressed: onDontShowAgain,
                  child: Text(l10n.dontShowAgain),
                ),
              TextButton(
                onPressed: onDismiss,
                child: Text(l10n.dismiss),
              ),
            ],
          ),
        ],
      ),
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
      content: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SafeArea(
          child: Text(l10n.dataStorageDescription),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.iUnderstand),
        ),
      ],
    );
  }
}
