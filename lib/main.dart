import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import 'core/providers/llm_providers.dart';
import 'core/providers/ai_config_provider.dart';
import 'core/services/secure_api_key_service.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/responsive.dart';
import 'core/data/data.dart';
import 'package:studyking/core/providers/service_providers.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/data/adapters/mastery_improvement_adapter.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';

import 'core/routes/app_router.dart';
import 'core/routes/tab_navigator.dart';
import 'core/services/engagement_scheduler.dart';
import 'core/services/study_progress_tracker.dart';
import 'core/services/mastery_graph_service.dart';
import 'core/services/plan_adherence_orchestrator.dart';
import 'core/data/repositories/engagement_nudge_repository.dart';
import 'core/data/repositories/plan_adherence_repository.dart';
import 'features/planner/services/planner_service.dart';
import 'features/settings/data/models/user_profile_model.dart';
import 'features/settings/data/models/accessibility_preferences.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/subjects/presentation/subject_list_screen.dart';
import 'features/practice/presentation/screens/practice_screen.dart';
import 'features/mentor/presentation/mentor_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/focus_mode/presentation/focus_timer_screen.dart';
import 'features/onboarding/providers/onboarding_providers.dart';
import 'features/onboarding/presentation/onboarding_dialog.dart';
import 'core/widgets/splash_screen.dart';

final Logger _mainLogger = const Logger('App');

EngagementScheduler? _engagementScheduler;
SecureApiKeyService? _secureApiKeyService;
String _effectiveApiKey = '';
String _effectiveBackupApiKey = '';
final _appInitNotifier = ValueNotifier<bool>(false);

/// Whether app initialization (Hive, DB, etc.) has completed.
/// Widgets can listen to this to switch from splash to main screen.
bool get isAppInitialized => _appInitNotifier.value;
ValueNotifier<bool> get appInitNotifier => _appInitNotifier;

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
        HiveBoxNames.agentMemory, HiveBoxNames.examResults,
        HiveBoxNames.studentId, HiveBoxNames.dashboardLayoutPrefs,
        HiveBoxNames.dbVersion,
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
            } catch (e) {
              _mainLogger.w('Failed to serialize box entry: $e');
            }
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
    _mainLogger.w('Auto-backup check at startup failed', e);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = AppErrorWidgetBuilder.build;

  PlatformDispatcher.instance.onError = (error, stack) {
    _mainLogger.e('Unhandled platform error', error, stack);
    return true;
  };

  SecurityConfig.enforceStartupGuards();
  AppConstants.initialize();

  Hive.initFlutter();

  Hive.registerAdapter(AccessibilityPreferencesAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(MasteryImprovementMetricAdapter());

  // Show splash screen immediately; run heavy init after first frame
  runApp(StudyKingApp());
}

Future<void> _runAppInitialization(StudyKingApp appEntry) async {
  try {
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
      _mainLogger.w('Failed to init database: ${dbInitResult.error}');
    }

    // Initialize settings repository
    final initSettingsRepo = SettingsRepository();
    initSettingsRepository(initSettingsRepo);
    final initResult = await initSettingsRepo.init();
    if (initResult.isFailure) {
      _mainLogger.w('Failed to init settings: ${initResult.error}');
    }

    // Initialize secure storage for API keys
    final secureApiKeyService = SecureApiKeyService();
    _secureApiKeyService = secureApiKeyService;

    // Load saved locale
    try {
      final initProfileResult = await initSettingsRepo.getProfileData();
      if (initProfileResult.isSuccess) {
        final profile = initProfileResult.data;
        if (profile != null && profile.language.isNotEmpty) {
          setInitialLanguageCode(profile.language);
        }
      } else {
        _mainLogger.w('Error loading profile: ${initProfileResult.error}');
      }
    } catch (e, stackTrace) {
      _mainLogger.w('Error loading profile locale', e, stackTrace);
    }

    // Initialize student ID service
    StudentIdService();
    await StudentIdService().init();
    await StudentIdService().updateLastActivity();

    try {
      final masteryService = MasteryGraphService();
      _mainLogger.w('Using English locale fallback for EngagementScheduler during startup');
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

    // Load initial settings, reading API keys from secure storage if available
    var settingsResult = await initSettingsRepo.getSettings();
    if (settingsResult.isSuccess) {
      final settings = settingsResult.data!;
      final secureKey = await _secureApiKeyService!.getApiKey();
      final secureBackupKey = await _secureApiKeyService!.getBackupApiKey();
      if (secureKey.isEmpty && settings.apiKey.isNotEmpty) {
        await _secureApiKeyService!.saveApiKey(settings.apiKey);
        _mainLogger.i('Migrated API key from Hive to secure storage');
      }
      _effectiveApiKey = secureKey.isNotEmpty ? secureKey : settings.apiKey;
      _effectiveBackupApiKey = secureBackupKey.isNotEmpty ? secureBackupKey : settings.backupApiKey;
      _engagementScheduler?.updateSettings(settings);
    } else {
      _mainLogger.w('Error loading initial settings: ${settingsResult.error}');
    }

    // Run auto-backup check
    _runAutoBackupCheck();

    _appInitNotifier.value = true;
  } catch (e, stackTrace) {
    _mainLogger.w('Error during initialization', e, stackTrace);
    _appInitNotifier.value = true;
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

List<DestinationData> _buildDestinations(AppLocalizations l10n, {bool isWideScreen = false}) {
  final all = [
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
  return all;
}

class StudyKingApp extends ConsumerStatefulWidget {
  const StudyKingApp({super.key});

  @override
  ConsumerState<StudyKingApp> createState() => _StudyKingAppState();
}

class _StudyKingAppState extends ConsumerState<StudyKingApp> with WidgetsBindingObserver {
  bool _providersInited = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAppInitialization(const StudyKingApp()).then((_) {
        if (mounted) setState(() => _initialized = true);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _initialized) {
      _runAutoBackupCheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(message: 'Loading...'),
      );
    }

    final settings = ref.watch(settingsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _engagementScheduler?.updateSettings(settings);
      if (!_providersInited) {
        _providersInited = true;
        ref.read(apiKeyProvider.notifier).state = _effectiveApiKey.isNotEmpty ? _effectiveApiKey : settings.apiKey;
        ref.read(apiBaseUrlProvider.notifier).state = settings.apiBaseUrl;
        ref.read(selectedModelProvider.notifier).state = settings.selectedModel;
        final providerName = settings.llmProviderName;
        if (providerName.isNotEmpty) {
          ref.read(llmProviderProvider.notifier).state = LlmProvider.values.firstWhere(
            (p) => p.name == providerName,
            orElse: () => LlmProvider.openRouter,
          );
        }
        final backupProviderName = settings.backupLlmProviderName;
        if (backupProviderName.isNotEmpty) {
          ref.read(backupLlmProviderProvider.notifier).state = LlmProvider.values.firstWhere(
            (p) => p.name == backupProviderName,
            orElse: () => LlmProvider.openRouter,
          );
        }
        final effectiveBackupApiKey = _effectiveBackupApiKey.isNotEmpty ? _effectiveBackupApiKey : settings.backupApiKey;
        if (effectiveBackupApiKey.isNotEmpty) {
          ref.read(backupApiKeyProvider.notifier).state = effectiveBackupApiKey;
        }
        if (settings.backupBaseUrl.isNotEmpty) {
          ref.read(backupBaseUrlProvider.notifier).state = settings.backupBaseUrl;
        }
        if (settings.backupModel.isNotEmpty) {
          ref.read(backupModelProvider.notifier).state = settings.backupModel;
        }
        markAiConfigReady();
      }
    });
    final locale = ref.watch(localeProvider);
    
    final systemBoldText = MediaQuery.boldTextOf(context) || settings.boldText;
    final systemHighContrast = MediaQuery.highContrastOf(context);

    final effectiveFontSize = settings.fontSize.clamp(UiConfig.minFontSize, UiConfig.maxFontSize);

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
          ? AppTheme.highContrastLightTheme(fontSize: effectiveFontSize, largeTouchTargets: settings.largeTouchTargets)
          : AppTheme.lightTheme(fontSize: effectiveFontSize, largeTouchTargets: settings.largeTouchTargets),
      darkTheme: useHighContrast
          ? AppTheme.highContrastDarkTheme(fontSize: effectiveFontSize, largeTouchTargets: settings.largeTouchTargets)
          : AppTheme.darkTheme(fontSize: effectiveFontSize, largeTouchTargets: settings.largeTouchTargets),
      themeMode: settings.themeModeEnum,
      home: const MainScreen(),
      onGenerateRoute: (settings) => onGenerateRoute(settings, ref.read(studentIdServiceProvider)),
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
  static const String _bannerPermanentlyDismissedKey = 'apiKeyBannerPermanentlyDismissed';

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
      final result = await ref.read(onboardingServiceProvider).isOnboardingNeeded();
      final isFirst = result.data ?? false;
      if (isFirst && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const OnboardingDialog(),
        );
      }

      if (mounted) {
        final settingsBox = await Hive.openBox(HiveBoxNames.settings);
        final apiKey = settingsBox.get('apiKey', defaultValue: '') as String;
        final permanentlyDismissed = settingsBox.get(_bannerPermanentlyDismissedKey, defaultValue: false) as bool;
        final dismissedTime = settingsBox.get(_bannerDismissedTimeKey) as int?;
        final shouldShow = apiKey.isEmpty &&
            !permanentlyDismissed &&
            (dismissedTime == null ||
                DateTime.now().millisecondsSinceEpoch - dismissedTime > Timeouts.week.inMilliseconds);
        if (shouldShow) {
          setState(() => _showApiKeyBanner = true);
        }
      }

      if (mounted) {
        await _checkOrphanedSessions();
      }

      if (mounted) {
        await _checkPlanAutoExtension();
      }
    } catch (e) {
      _mainLogger.w('_handleFirstLaunch failed', e);
    }
  }

  Future<void> _checkPlanAutoExtension() async {
    try {
      final daysSinceLastActivity = StudentIdService().getDaysSinceLastActivity();
      if (daysSinceLastActivity < 7) return;

      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;

      final studentId = StudentIdService().getStudentId();
      final plannerService = PlannerService();
      final planResult = await plannerService.loadExistingPlan();
      final plan = planResult.data;
      if (plan == null) return;

      if (!mounted) return;
      final needsExtension = await showDialog<bool>(
        context: context,
        builder: (ctx2) => AlertDialog(
          title: Text(l10n.absenceDetectedTitle),
          content: Text(l10n.welcomeBackDays(daysSinceLastActivity)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx2, false),
              child: Text(l10n.noThanks),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx2, true),
              child: Text(l10n.catchUpExtend(daysSinceLastActivity)),
            ),
          ],
        ),
      );

      if (needsExtension == true && mounted) {
        await plannerService.planService.extendPlan(studentId, daysSinceLastActivity);
      }
    } catch (e) {
      _mainLogger.w('Plan auto-extension check failed: $e');
    }
  }

  Future<void> _checkOrphanedSessions() async {
    try {
      final db = ref.read(databaseProvider);
      final activeResult = await db.tutorSessionRepository.getActiveSessions();
      final sessions = activeResult.data ?? [];
      if (sessions.isEmpty || !mounted) return;

      final session = sessions.first;
      final l10n = AppLocalizations.of(context)!;
      final timeStr = DateFormat.jm(l10n.localeName).format(session.startTime.toLocal());

      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.orphanedSessionFound),
          content: Text(l10n.orphanedSessionMessage(session.topicTitle, timeStr)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'dismiss'),
              child: Text(l10n.dismiss),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              child: Text(l10n.discardAndExit),
            ),
          ],
        ),
      );

      if (action == 'discard' && mounted) {
        final cancelled = session.copyWith(
          status: SessionStatus.cancelled,
          endTime: DateTime.now(),
        );
        await db.tutorSessionRepository.saveSession(cancelled);
      }
    } catch (e) {
      _mainLogger.w('Orphaned session cleanup check failed: $e');
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
                  Hive.openBox(HiveBoxNames.settings).then((box) {
                    box.put(_bannerDismissedTimeKey, DateTime.now().millisecondsSinceEpoch);
                  });
                },
                onDontShowAgain: () {
                  setState(() => _apiKeyBannerDismissed = true);
                  Hive.openBox(HiveBoxNames.settings).then((box) {
                    box.put(_bannerPermanentlyDismissedKey, true);
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
                          destinations: _buildDestinations(l10n, isWideScreen: true).map((d) {
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
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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
