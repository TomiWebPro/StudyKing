import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/utils/logger.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/models/settings_box.dart';
import 'features/settings/data/models/accessibility_preferences.dart';
import 'features/settings/data/repositories/settings_repository.dart';
import 'core/data/data.dart';
import 'features/settings/presentation/api_config_screen.dart';
import 'features/settings/presentation/profile_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/subjects/presentation/subject_list_view.dart';
import 'features/practice/presentation/practice_screen.dart';
import 'features/quickguide/quickguide.dart';

// Global database instance
final database = DatabaseService(
  topicRepository: TopicRepository(),
  questionRepository: QuestionRepository(),
  attemptRepository: AttemptRepository(),
  lessonRepository: LessonRepository(),
  sessionRepository: StudySessionRepository(),
  subjectRepository: SubjectRepository(),
);

// Global settings repository (singleton for use outside widget tree)
final settingsRepository = SettingsRepository();

// Settings provider (uses the singleton)
final settingsProvider = StateNotifierProvider<SettingsController, SettingsBox>((ref) {
  return SettingsController(settingsRepository);
});

// Settings loading state provider to handle race condition
final settingsLoadingProvider = StateProvider<bool>((ref) => false);

// Theme mode provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Font size provider  
final fontSizeProvider = StateProvider<double>((ref) => 16.0);

// API key provider
final apiKeyProvider = StateProvider<String>((ref) => '');

// API base URL provider
final apiBaseUrlProvider = StateProvider<String>((ref) => ApiConfig.openRouterBaseUrlString);

// Selected model provider
final selectedModelProvider = StateProvider<String>((ref) => '');

// Locale provider
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

class SettingsController extends StateNotifier<SettingsBox> {
  final Logger _logger = const Logger('SettingsController');
  final SettingsRepository _repository;
  bool _hasLoadedOnce = false;
  
  SettingsController(this._repository) : super(SettingsBox());

  Future<void> _loadSettings() async {
    if (_hasLoadedOnce) return;
    try {
      _hasLoadedOnce = true;
      final settings = await _repository.getSettings();
      state = settings;
    } catch (e) {
      _logger.e('Error loading settings', e);
    }
  }

  Future<void> updateSettings({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    ThemeMode? themeMode,
    double? fontSize,
    bool? studyRemindersEnabled,
    int? requestTimeoutSeconds,
    int? sessionDurationMinutes,
    bool? highContrastEnabled,
    bool? largeTouchTargets,
  }) async {
    try {
      await _repository.updateSettings(
        apiKey: apiKey ?? state.apiKey,
        apiBaseUrl: apiBaseUrl ?? state.apiBaseUrl,
        selectedModel: selectedModel ?? state.selectedModel,
        themeMode: themeMode ?? state.themeModeEnum,
        fontSize: fontSize ?? state.fontSize,
        studyRemindersEnabled:
            studyRemindersEnabled ?? state.studyRemindersEnabled,
        requestTimeoutSeconds:
            requestTimeoutSeconds ?? state.requestTimeoutSeconds,
        sessionDurationMinutes:
            sessionDurationMinutes ?? state.sessionDurationMinutes,
        highContrastEnabled:
            highContrastEnabled ?? state.highContrastEnabled,
        largeTouchTargets:
            largeTouchTargets ?? state.largeTouchTargets,
      );
      state = await _repository.getSettings();
    } catch (e) {
      _logger.e('Error updating settings', e);
    }
  }

  Future<void> saveApiKey(String key) async {
    try {
      await _repository.saveApiKey(service: 'default', key: key);
      await _loadSettings();
    } catch (e) {
      _logger.e('Error saving API key', e);
    }
  }

  Future<void> updateTheme(ThemeMode mode) async {
    try {
      await _repository.updateSettings(themeMode: mode);
      state = await _repository.getSettings();
    } catch (e) {
      _logger.e('Error updating theme', e);
    }
  }

  Future<void> updateFontSize(double size) async {
    try {
      await _repository.updateSettings(fontSize: size);
      state = await _repository.getSettings();
    } catch (e) {
      _logger.e('Error updating font size', e);
    }
  }

  Future<void> updateModel(String model) async {
    try {
      await _repository.updateSettings(selectedModel: model);
      state = await _repository.getSettings();
    } catch (e) {
      _logger.e('Error updating model', e);
    }
  }

  Future<void> updateStudyReminders(bool enabled) async {
    await updateSettings(studyRemindersEnabled: enabled);
  }

  Future<void> updateRequestTimeout(int timeoutSeconds) async {
    await updateSettings(requestTimeoutSeconds: timeoutSeconds);
  }

  Future<void> updateSessionDuration(int minutes) async {
    await updateSettings(sessionDurationMinutes: minutes);
  }

  Future<void> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  }) async {
    try {
      await _repository.updateStats(
        sessionCount: sessionCount,
        studyTimeMs: studyTimeMs,
        questions: questions,
      );
      state = await _repository.getSettings();
    } catch (e) {
      _logger.e('Error updating stats', e);
    }
  }

  Future<void> updateHighContrast(bool enabled) async {
    await updateSettings(highContrastEnabled: enabled);
  }

  Future<void> updateLargeTouchTargets(bool enabled) async {
    await updateSettings(largeTouchTargets: enabled);
  }
}

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
    
    // Initialize all repositories
    await database.topicRepository.init();
    await database.questionRepository.init();
    await database.attemptRepository.init();
    await database.lessonRepository.init();
    await database.sessionRepository.init();
    await database.subjectRepository.init();
    
    // Initialize settings repository
    await settingsRepository.init();
    
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

class StudyKingApp extends ConsumerWidget {
  const StudyKingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isLoading = ref.watch(settingsLoadingProvider);
    final locale = ref.watch(localeProvider);
    
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
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      explicitChildNodes: true,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
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
              label: AppLocalizations.of(context)!.subjects,
              child: NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: AppLocalizations.of(context)!.subjects,
              ),
            ),
            Semantics(
              label: AppLocalizations.of(context)!.practice,
              child: NavigationDestination(
                icon: Icon(Icons.play_arrow_outlined),
                selectedIcon: Icon(Icons.play_arrow),
                label: AppLocalizations.of(context)!.practice,
              ),
            ),
            Semantics(
              label: AppLocalizations.of(context)!.settings,
              child: NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: AppLocalizations.of(context)!.settings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
