import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/config/locale_config.dart';
import 'core/utils/logger.dart';
import 'core/utils/error_boundary.dart';
import 'core/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/providers/app_providers.dart';
import 'core/services/llm/llm_chat_service.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/responsive.dart';
import 'core/data/data.dart';
import 'core/services/student_id_service.dart';
import 'package:studyking/features/practice/data/adapters/mastery_improvement_adapter.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/subjects/data/repositories/topic_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/practice/data/repositories/attempt_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/sessions/data/repositories/session_repository.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';

import 'core/routes/app_router.dart';
import 'core/routes/tab_navigator.dart';
import 'core/services/engagement_scheduler.dart';
import 'core/services/study_progress_tracker.dart';
import 'core/services/mastery_graph_service.dart';
import 'core/services/plan_adherence_orchestrator.dart';
import 'features/planner/data/repositories/engagement_nudge_repository.dart';
import 'features/planner/data/repositories/plan_adherence_repository.dart';
import 'features/planner/services/planner_service.dart';
import 'features/settings/data/models/user_profile_model.dart';
import 'features/settings/data/models/accessibility_preferences.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/subjects/presentation/subject_list_screen.dart';
import 'features/practice/presentation/screens/practice_screen.dart';
import 'features/mentor/presentation/mentor_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/focus_mode/presentation/focus_timer_screen.dart';
import 'features/onboarding/presentation/onboarding_dialog.dart';
import 'features/onboarding/services/onboarding_service.dart';

final Logger _mainLogger = const Logger('App');

EngagementScheduler? _engagementScheduler;

EngagementScheduler? getEngagementScheduler() => _engagementScheduler;

Future<void> _runAutoBackupCheck() async {
  try {
    if (!Hive.isBoxOpen(HiveBoxNames.settings)) return;
    final box = Hive.box(HiveBoxNames.settings);
    final intervalDays = box.get('autoBackupIntervalDays', defaultValue: 0) as int;
    if (intervalDays <= 0) return;
    final lastBackupStr = box.get('lastAutoBackupDate', defaultValue: '') as String;
    if (lastBackupStr.isEmpty) {
      box.put('lastAutoBackupDate', DateTime.now().toIso8601String());
      return;
    }
    final lastBackup = DateTime.tryParse(lastBackupStr);
    if (lastBackup == null) return;
    final nextBackup = lastBackup.add(Duration(days: intervalDays));
    if (DateTime.now().isAfter(nextBackup)) {
      final boxData = <String, List<Map<String, dynamic>>>{};
      final boxNames = [
        HiveBoxNames.subjects, HiveBoxNames.topics, HiveBoxNames.questions,
        HiveBoxNames.answers, HiveBoxNames.sources, HiveBoxNames.attempts,
        HiveBoxNames.lessons, HiveBoxNames.lessonBlocks, HiveBoxNames.sessions,
        HiveBoxNames.sessionsTyped, HiveBoxNames.progress, HiveBoxNames.tasks,
        HiveBoxNames.conversations, HiveBoxNames.tutorSessions,
        HiveBoxNames.masteryStates, HiveBoxNames.questionMasteryStates,
        HiveBoxNames.questionEvaluations, HiveBoxNames.learningPlans,
        HiveBoxNames.planAdherence, HiveBoxNames.planAdherenceMetrics,
        HiveBoxNames.masteryImprovementMetrics, HiveBoxNames.roadmaps,
        HiveBoxNames.pendingActions, HiveBoxNames.engagementNudges,
        HiveBoxNames.badges, HiveBoxNames.focusSessions,
        HiveBoxNames.studentAvailability, HiveBoxNames.topicDependencies,
        HiveBoxNames.profile, HiveBoxNames.llmTasks, HiveBoxNames.llmUsageRecords,
      ];
      for (final boxName in boxNames) {
        if (!Hive.isBoxOpen(boxName)) continue;
        final hiveBox = Hive.box(boxName);
        final records = <Map<String, dynamic>>[];
        for (final value in hiveBox.values) {
          if (value == null) continue;
          if (value is Map<String, dynamic>) {
            records.add(value);
          } else {
            try {
              final obj = value as dynamic;
              records.add(obj.toJson() as Map<String, dynamic>);
            } catch (_) {}
          }
        }
        if (records.isNotEmpty) boxData[boxName] = records;
      }
      boxData.remove(HiveBoxNames.settings);
      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'boxes': boxData,
      };
      final json = const JsonEncoder.withIndent('  ').convert(backup);
      if (kIsWeb) {
        box.put('lastAutoBackupDate', DateTime.now().toIso8601String());
        _mainLogger.i('Auto-backup skipped: not supported on web');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/studyking_backup.json');
        await file.writeAsString(json);
        box.put('lastAutoBackupDate', DateTime.now().toIso8601String());
        box.put('lastAutoBackupPath', file.path);
        _mainLogger.i('Auto-backup completed at startup: ${file.path}');
      }
    }
  } catch (e) {
    _mainLogger.e('Auto-backup check at startup failed', e);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = AppErrorWidgetBuilder.build;

  PlatformDispatcher.instance.onError = (error, stack) {
    _mainLogger.e('Unhandled platform error', error, stack);
    return true;
  };
  
  try {
    SecurityConfig.enforceStartupGuards();
    AppConstants.initialize();

    // Initialize Hive database
    Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(AccessibilityPreferencesAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(MasteryImprovementMetricAdapter());
    
      // Run database migrations and open all boxes
    await HiveInitializer.initialize();
    
    // Initialize all repositories through DatabaseService
    final mainDb = DatabaseService(
      topicRepository: TopicRepository(),
      questionRepository: QuestionRepository(),
      attemptRepository: AttemptRepository(),
      lessonRepository: LessonRepository(),
      sessionRepository: SessionRepository(),
      subjectRepository: SubjectRepository(),
      conversationRepository: ConversationRepository(),
      tutorSessionRepository: TutorSessionRepository(),
    );
    final dbInitResult = await mainDb.init();
    if (dbInitResult.isFailure) {
      _mainLogger.e('Failed to init database: ${dbInitResult.error}');
    }
    
    // Initialize settings repository
    final initSettingsRepo = SettingsRepository();
    initSettingsRepository(initSettingsRepo);
    final initResult = await initSettingsRepo.init();
    if (initResult.isFailure) {
      _mainLogger.e('Failed to init settings: ${initResult.error}');
    }

    // Load saved locale before runApp to prevent locale flicker
    try {
      final initProfileResult = await initSettingsRepo.getProfileData();
      if (initProfileResult.isSuccess) {
        final profile = initProfileResult.data;
        if (profile != null && profile.language.isNotEmpty) {
          setInitialLanguageCode(profile.language);
        }
      } else {
        _mainLogger.e('Error loading profile: ${initProfileResult.error}');
      }
    } catch (e, stackTrace) {
      _mainLogger.e('Error loading profile locale', e, stackTrace);
    }

    // Initialize student ID service (generates UUID on first launch)
    StudentIdService(); // ensure singleton is initialized
    await StudentIdService().init();
    await StudentIdService().updateLastActivity();

    try {
      final masteryService = MasteryGraphService();
      final defaultL10n = lookupAppLocalizations(const Locale('en'));
      final schedulerRef = EngagementScheduler(
        tracker: StudyProgressTracker(
          attemptRepo: mainDb.attemptRepository,
          masteryService: masteryService,
          sessionRepo: mainDb.sessionRepository,
          l10n: defaultL10n,
        ),
        masteryService: masteryService,
        nudgeRepository: EngagementNudgeRepository(),
        adherenceRepository: PlanAdherenceRepository(),
        planOrchestrator: PlanAdherenceOrchestrator(),
        sessionRepository: mainDb.sessionRepository,
        plannerService: PlannerService(),
        l10n: defaultL10n,
      );
      await schedulerRef.init();
      _engagementScheduler = schedulerRef;
    } catch (e) {
      _mainLogger.w('Failed to init EngagementScheduler: $e');
    }
    
    // Load initial settings to sync with providers
    final settingsResult = await initSettingsRepo.getSettings();
    if (settingsResult.isSuccess) {
      _engagementScheduler?.updateSettings(settingsResult.data!);
    } else {
      _mainLogger.e('Error loading initial settings: ${settingsResult.error}');
    }

    // Run auto-backup check on startup (moved from SettingsScreen initState)
    _runAutoBackupCheck();

    runApp(StudyKingApp());
  } catch (e, stackTrace) {
    _mainLogger.e('Error during initialization', e, stackTrace);
  }
}

class _CloseDialogIntent extends Intent {
  const _CloseDialogIntent();
}

class DestinationData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String tooltip;

  const DestinationData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.tooltip,
  });
}

List<DestinationData> _buildDestinations(AppLocalizations l10n) => [
  DestinationData(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: l10n.dashboard,
    tooltip: l10n.dashboard,
  ),
  DestinationData(
    icon: Icons.school_outlined,
    selectedIcon: Icons.school,
    label: l10n.subjects,
    tooltip: l10n.subjects,
  ),
  DestinationData(
    icon: Icons.play_arrow_outlined,
    selectedIcon: Icons.play_arrow,
    label: l10n.practice,
    tooltip: l10n.practice,
  ),
  DestinationData(
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome,
    label: l10n.mentor,
    tooltip: l10n.mentor,
  ),
  DestinationData(
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
    label: l10n.focusMode,
    tooltip: l10n.focusMode,
  ),
  DestinationData(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: l10n.settings,
    tooltip: l10n.settings,
  ),
];

class StudyKingApp extends ConsumerStatefulWidget {
  const StudyKingApp({super.key});

  @override
  ConsumerState<StudyKingApp> createState() => _StudyKingAppState();
}

class _StudyKingAppState extends ConsumerState<StudyKingApp> {
  bool _providersInited = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _engagementScheduler?.updateSettings(settings);
      if (!_providersInited) {
        _providersInited = true;
        ref.read(apiKeyProvider.notifier).state = settings.apiKey;
        ref.read(apiBaseUrlProvider.notifier).state = settings.apiBaseUrl;
        ref.read(selectedModelProvider.notifier).state = settings.selectedModel;
        final providerName = settings.llmProviderName;
        if (providerName.isNotEmpty) {
          ref.read(llmProviderProvider.notifier).state = LlmProvider.values.firstWhere(
            (p) => p.name == providerName,
            orElse: () => LlmProvider.openRouter,
          );
        }
      }
    });
    final locale = ref.watch(localeProvider);
    
    final systemBoldText = MediaQuery.boldTextOf(context);
    final systemHighContrast = MediaQuery.highContrastOf(context);

    final effectiveFontSize = settings.fontSize.clamp(10.0, 30.0);

    final useHighContrast = systemHighContrast || settings.highContrastEnabled;

    return MaterialApp(
      locale: locale,
      title: AppLocalizations.of(context)?.appTitle ?? 'StudyKing',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocale.supportedLocales,
      localeResolutionCallback: AppLocale.resolveLocale,
      builder: (context, child) {
        final systemTextScale = MediaQuery.textScalerOf(context).scale(1.0);
        final scaledFontSize = effectiveFontSize / 16.0;
        final totalScale =
            (systemTextScale * scaledFontSize).clamp(1.0, 2.0);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            boldText: systemBoldText,
            textScaler: TextScaler.linear(totalScale),
          ),
          child: child!,
        );
      },
      scrollBehavior: const _AppScrollBehavior(),
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const _CloseDialogIntent(),
      },
      actions: {
        _CloseDialogIntent: CallbackAction<_CloseDialogIntent>(
          onInvoke: (intent) {
            final navigator = Navigator.of(context, rootNavigator: true);
            if (navigator.canPop()) {
              navigator.pop();
            }
            return null;
          },
        ),
      },
      theme: useHighContrast
          ? AppTheme.highContrastLightTheme(fontSize: effectiveFontSize)
          : AppTheme.lightTheme(fontSize: effectiveFontSize),
      darkTheme: useHighContrast
          ? AppTheme.highContrastDarkTheme(fontSize: effectiveFontSize)
          : AppTheme.darkTheme(fontSize: effectiveFontSize),
      themeMode: settings.themeModeEnum,
      home: const MainScreen(),
      onGenerateRoute: onGenerateRoute,
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return child;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return Scrollbar(
          controller: details.controller,
          child: child,
        );
    }
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class MainScreen extends ConsumerStatefulWidget {
  final String? fixedStudentId;

  const MainScreen({super.key, this.fixedStudentId});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  bool _showApiKeyBanner = false;
  bool _apiKeyBannerDismissed = false;
  static const String _bannerDismissedTimeKey = 'apiKeyBannerDismissedTime';

  final _navigatorKeys = List.generate(6, (_) => GlobalKey<NavigatorState>());
  late final List<Widget> _tabNavigators;

  @override
  void initState() {
    super.initState();
    _tabNavigators = _buildTabNavigators();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleFirstLaunch());
  }

  Future<void> _handleFirstLaunch() async {
    try {
      final isFirst = await OnboardingService.isOnboardingNeeded();
      if (isFirst && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const OnboardingDialog(),
        );

        if (mounted) {
          await showDialog(
            context: context,
            builder: (_) => const LocalDataNotice(),
          );
        }
      }

      if (mounted) {
        final settingsBox = await Hive.openBox('settings');
        final apiKey = settingsBox.get('apiKey', defaultValue: '') as String;
        final dismissedTime = settingsBox.get(_bannerDismissedTimeKey) as int?;
        final shouldShow = apiKey.isEmpty && (dismissedTime == null ||
            DateTime.now().millisecondsSinceEpoch - dismissedTime > Timeouts.week.inMilliseconds);
        if (shouldShow) {
          setState(() => _showApiKeyBanner = true);
        }
      }
    } catch (e) {
      _mainLogger.e('_handleFirstLaunch failed', e);
    }
  }

  List<Widget> _buildTabNavigators() {
    return [
      TabNavigator(
        key: const ValueKey('tab_dashboard'),
        rootScreen: DashboardScreen(studentId: StudentIdService().getStudentId()),
        navigatorKey: _navigatorKeys[0],
      ),
      TabNavigator(
        key: const ValueKey('tab_subjects'),
        rootScreen: const SubjectListScreen(),
        navigatorKey: _navigatorKeys[1],
      ),
      TabNavigator(
        key: const ValueKey('tab_practice'),
        rootScreen: const PracticeScreen(),
        navigatorKey: _navigatorKeys[2],
      ),
      TabNavigator(
        key: const ValueKey('tab_mentor'),
        rootScreen: const MentorScreen(),
        navigatorKey: _navigatorKeys[3],
      ),
      TabNavigator(
        key: const ValueKey('tab_study'),
        rootScreen: const FocusTimerScreen(),
        navigatorKey: _navigatorKeys[4],
      ),
      TabNavigator(
        key: const ValueKey('tab_settings'),
        rootScreen: const SettingsScreen(),
        navigatorKey: _navigatorKeys[5],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWideScreen = ResponsiveUtils.breakpointOf(context).isTablet;
    final reduceMotion = ref.watch(settingsProvider).reduceMotion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _engagementScheduler?.updateLocalization(l10n);
      ref.read(l10nProvider.notifier).state = l10n;
    });

    final bodyContent = reduceMotion
        ? KeyedSubtree(
            key: ValueKey(_selectedIndex),
            child: RepaintBoundary(
              child: _tabNavigators[_selectedIndex],
            ),
          )
        : AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: KeyedSubtree(
              key: ValueKey(_selectedIndex),
              child: RepaintBoundary(
                child: _tabNavigators[_selectedIndex],
              ),
            ),
          );

    return Semantics(
      explicitChildNodes: true,
      child: Scaffold(
        body: Column(
          children: [
            if (_showApiKeyBanner && !_apiKeyBannerDismissed)
              ApiKeyBanner(
                onDismiss: () {
                  setState(() => _apiKeyBannerDismissed = true);
                  Hive.openBox('settings').then((box) {
                    box.put(_bannerDismissedTimeKey, DateTime.now().millisecondsSinceEpoch);
                  });
                },
                onDontShowAgain: () {
                  setState(() => _apiKeyBannerDismissed = true);
                  Hive.openBox('settings').then((box) {
                    box.put(_bannerDismissedTimeKey, DateTime.now().millisecondsSinceEpoch);
                  });
                },
              ),
            Expanded(
              child: isWideScreen
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          labelType: NavigationRailLabelType.all,
                          destinations: _buildDestinations(l10n).map((d) {
                            return NavigationRailDestination(
                              icon: Tooltip(message: d.tooltip, child: Icon(d.icon)),
                              selectedIcon: Tooltip(message: d.tooltip, child: Icon(d.selectedIcon)),
                              label: Text(d.label),
                            );
                          }).toList(),
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(child: bodyContent),
                      ],
                    )
                  : bodyContent,
            ),
          ],
        ),
        bottomNavigationBar: isWideScreen
            ? null
            : NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: _buildDestinations(l10n).map((d) {
                  return NavigationDestination(
                    icon: Tooltip(message: d.tooltip, child: Icon(d.icon)),
                    selectedIcon: Tooltip(message: d.tooltip, child: Icon(d.selectedIcon)),
                    label: d.label,
                  );
                }).toList(),
              ),
      ),
    );
  }
}
