import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/config/locale_config.dart';
import 'core/utils/logger.dart';
import 'core/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/providers/app_providers.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/responsive.dart';
import 'core/data/data.dart';
import 'core/services/student_id_service.dart';
import 'package:studyking/features/planner/data/adapters/plan_adherence_adapter.dart';
import 'package:studyking/features/practice/data/adapters/mastery_improvement_adapter.dart';

import 'core/routes/app_router.dart';
import 'core/routes/tab_navigator.dart';
import 'features/settings/data/models/user_profile_model.dart';
import 'features/settings/data/models/accessibility_preferences.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/subjects/presentation/subject_list_screen.dart';
import 'features/practice/presentation/practice_screen.dart';
import 'features/mentor/presentation/mentor_screen.dart';
import 'features/focus_mode/presentation/focus_timer_screen.dart';

final Logger _mainLogger = const Logger('App');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    SecurityConfig.enforceStartupGuards();
    AppConstants.initialize();

    // Initialize Hive database
    Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(AccessibilityPreferencesAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(PlanAdherenceMetricAdapter());
    Hive.registerAdapter(MasteryImprovementMetricAdapter());
    
      // Run database migrations and open all boxes
    await HiveInitializer.initialize();
    
    // Initialize all repositories through DatabaseService
    await database.init();
    
    // Initialize settings repository
    await settingsRepository.init();
    
    // Initialize student ID service (generates UUID on first launch)
    StudentIdService(); // ensure singleton is initialized
    await StudentIdService().init();
    
    // Load initial settings to sync with providers
    try {
      await settingsRepository.getSettings();
    } catch (e) {
      _mainLogger.e('Error loading initial settings', e);
    }
    
    runApp(StudyKingApp());
  } catch (e, stackTrace) {
    _mainLogger.e('Error during initialization', e, stackTrace);
  }
}

class _CloseDialogIntent extends Intent {
  const _CloseDialogIntent();
}

class StudyKingApp extends ConsumerStatefulWidget {
  const StudyKingApp({super.key});

  @override
  ConsumerState<StudyKingApp> createState() => _StudyKingAppState();
}

class _StudyKingAppState extends ConsumerState<StudyKingApp> {
  bool _hasLoadedProfile = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isLoading = ref.watch(settingsLoadingProvider);
    final locale = ref.watch(localeProvider);

    if (!_hasLoadedProfile) {
      _hasLoadedProfile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final profile = await settingsRepository.getProfileData();
          if (profile != null && profile.language.isNotEmpty && mounted) {
            ref.read(localeProvider.notifier).state = Locale(profile.language);
          }
        } catch (_) {}
      });
    }
    
    if (isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(apiKeyProvider.notifier).state = settings.apiKey;
        ref.read(apiBaseUrlProvider.notifier).state = settings.apiBaseUrl;
        ref.read(selectedModelProvider.notifier).state = settings.selectedModel;
      });
    }
    
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

class MainScreen extends StatefulWidget {
  final String? fixedStudentId;

  const MainScreen({super.key, this.fixedStudentId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());
  late final List<Widget> _tabNavigators;

  @override
  void initState() {
    super.initState();
    _tabNavigators = _buildTabNavigators();
  }

  List<Widget> _buildTabNavigators() {
    return [
      TabNavigator(
        key: const ValueKey('tab_subjects'),
        rootScreen: const SubjectListScreen(),
        navigatorKey: _navigatorKeys[0],
      ),
      TabNavigator(
        key: const ValueKey('tab_practice'),
        rootScreen: const PracticeScreen(),
        navigatorKey: _navigatorKeys[1],
      ),
      TabNavigator(
        key: const ValueKey('tab_mentor'),
        rootScreen: const MentorScreen(),
        navigatorKey: _navigatorKeys[2],
      ),
      TabNavigator(
        key: const ValueKey('tab_focus_mode'),
        rootScreen: const FocusTimerScreen(),
        navigatorKey: _navigatorKeys[3],
      ),
      TabNavigator(
        key: const ValueKey('tab_settings'),
        rootScreen: const SettingsScreen(),
        navigatorKey: _navigatorKeys[4],
      ),
    ];
  }

  void _openDashboard() {
    _navigatorKeys[_selectedIndex].currentState?.pushNamed(
      AppRoutes.dashboard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWideScreen = ResponsiveUtils.breakpointOf(context).isTablet;

    final bodyContent = Stack(
      children: [
        for (int i = 0; i < _navigatorKeys.length; i++)
          Offstage(
            offstage: i != _selectedIndex,
            child: TickerMode(
              enabled: i == _selectedIndex,
              child: _tabNavigators[i],
            ),
          ),
      ],
    );

    return Semantics(
      explicitChildNodes: true,
      child: Scaffold(
        body: isWideScreen
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    leading: FloatingActionButton.small(
                      onPressed: () => _openDashboard(),
                      tooltip: l10n.dashboard,
                      child: const Icon(Icons.dashboard),
                    ),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.school_outlined),
                        selectedIcon: Icon(Icons.school),
                        label: Text(l10n.subjects),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.play_arrow_outlined),
                        selectedIcon: Icon(Icons.play_arrow),
                        label: Text(l10n.practice),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.auto_awesome_outlined),
                        selectedIcon: Icon(Icons.auto_awesome),
                        label: Text(l10n.mentor),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.timer_outlined),
                        selectedIcon: Icon(Icons.timer),
                        label: Text(l10n.focusMode),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: Text(l10n.settings),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: bodyContent),
                ],
              )
            : bodyContent,
        floatingActionButton: isWideScreen
            ? null
            : Semantics(
                button: true,
                label: l10n.dashboard,
                child: FloatingActionButton.small(
                  onPressed: () => _openDashboard(),
                  tooltip: l10n.dashboard,
                  child: const Icon(Icons.dashboard),
                ),
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
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.school_outlined),
                    selectedIcon: Icon(Icons.school),
                    label: l10n.subjects,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.play_arrow_outlined),
                    selectedIcon: Icon(Icons.play_arrow),
                    label: l10n.practice,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(Icons.auto_awesome),
                    label: l10n.mentor,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.timer_outlined),
                    selectedIcon: Icon(Icons.timer),
                    label: l10n.focusMode,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: l10n.settings,
                  ),
                ],
              ),
      ),
    );
  }
}
