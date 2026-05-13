import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/utils/logger.dart';
import 'core/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/providers/app_providers.dart';
import 'core/constants/app_constants.dart';
import 'core/data/data.dart';
import 'core/services/student_id_service.dart';
import 'core/services/mastery_graph_service.dart';
import 'features/settings/data/models/accessibility_preferences.dart';
import 'features/settings/presentation/api_config_screen.dart';
import 'features/settings/presentation/profile_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/subjects/presentation/subject_list_view.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/practice/presentation/practice_screen.dart';
import 'features/ingestion/presentation/upload_screen.dart';
import 'features/quickguide/quickguide.dart';
import 'features/mentor/presentation/mentor_screen.dart';

final Logger _mainLogger = const Logger('App');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    SecurityConfig.enforceStartupGuards();
    AppConstants.initialize();

    // Initialize Hive database
    Hive.initFlutter();
    
    // Register accessibility preferences adapter
    Hive.registerAdapter(AccessibilityPreferencesAdapter());
    
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
    
    final systemTextScaler = MediaQuery.textScalerOf(context);
    final systemBoldText = MediaQuery.boldTextOf(context);
    final systemHighContrast = MediaQuery.highContrastOf(context);

    final userFontSize = settings.fontSize.clamp(14.0, 30.0);
    final systemScaledSize = systemTextScaler.scale(16.0);
    final effectiveFontSize = userFontSize < systemScaledSize ? systemScaledSize : userFontSize;

    final useHighContrast = systemHighContrast || settings.highContrastEnabled;

    return MaterialApp(
      locale: locale,
      title: 'StudyKing',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            boldText: systemBoldText,
            textScaler: systemTextScaler,
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
            if (Navigator.of(context, rootNavigator: true).canPop()) {
              Navigator.of(context, rootNavigator: true).pop();
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
      routes: {
        '/api-config': (context) => const ApiConfigScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/quick-guide': (context) => const QuickGuideScreen(),
        '/mentor': (context) => const MentorScreen(),
        '/dashboard': (context) => DashboardScreen(
          studentId: StudentIdService().getStudentId(),
          masteryService: MasteryGraphService(),
        ),
        '/upload': (context) => const UploadScreen(),
      },
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
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    SubjectListView(),
    PracticeScreen(),
    MentorScreen(),
    SettingsScreen(),
  ];

  void _openDashboard() {
    final studentId = StudentIdService().getStudentId();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          studentId: studentId,
          masteryService: MasteryGraphService(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      explicitChildNodes: true,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: () => _openDashboard(),
          tooltip: 'Dashboard',
          child: const Icon(Icons.dashboard),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: [
            Semantics(
              label: l10n.subjects,
              child: NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: l10n.subjects,
              ),
            ),
            Semantics(
              label: l10n.practice,
              child: NavigationDestination(
                icon: Icon(Icons.play_arrow_outlined),
                selectedIcon: Icon(Icons.play_arrow),
                label: l10n.practice,
              ),
            ),
            Semantics(
              label: l10n.mentor,
              child: NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: l10n.mentor,
              ),
            ),
            Semantics(
              label: l10n.settings,
              child: NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: l10n.settings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
