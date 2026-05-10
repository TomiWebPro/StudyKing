import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/settings/data/models/settings_box.dart';
import 'features/settings/data/repositories/settings_repository.dart';
import 'core/data/data.dart';
import 'features/settings/presentation/api_config_screen.dart';
import 'features/settings/presentation/profile_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/subjects/presentation/subject_list_view.dart';
import 'features/practice/presentation/practice_screen.dart';

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
final apiBaseUrlProvider = StateProvider<String>((ref) => 'https://openrouter.ai/api/v1');

// Selected model provider
final selectedModelProvider = StateProvider<String>((ref) => '');

class SettingsController extends StateNotifier<SettingsBox> {
  final SettingsRepository _repository;
  bool _hasLoadedOnce = false;
  
  SettingsController(this._repository) : super(SettingsBox()) {
    // Don't auto-load in constructor to avoid race conditions
    // The loading will be triggered when needed by the widget tree
  }

  Future<void> _loadSettings() async {
    if (_hasLoadedOnce) return;
    try {
      _hasLoadedOnce = true;
      final settings = await _repository.getSettings();
      state = settings;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> updateSettings({
    String? apiKey,
    String? apiBaseUrl,
    String? selectedModel,
    ThemeMode? themeMode,
    double? fontSize,
  }) async {
    try {
      await _repository.updateSettings(
        apiKey: apiKey ?? state.apiKey,
        apiBaseUrl: apiBaseUrl ?? state.apiBaseUrl,
        selectedModel: selectedModel ?? state.selectedModel,
        themeMode: themeMode ?? state.themeModeEnum,
        fontSize: fontSize ?? state.fontSize,
      );
      state = await _repository.getSettings();
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
  }

  Future<void> saveApiKey(String key) async {
    try {
      await _repository.saveApiKey(service: 'default', key: key);
      await _loadSettings();
    } catch (e) {
      debugPrint('Error saving API key: $e');
    }
  }

  Future<void> updateTheme(ThemeMode mode) async {
    try {
      await _repository.updateSettings(themeMode: mode);
      state = await _repository.getSettings();
    } catch (e) {
      debugPrint('Error updating theme: $e');
    }
  }

  Future<void> updateFontSize(double size) async {
    try {
      await _repository.updateSettings(fontSize: size);
      state = await _repository.getSettings();
    } catch (e) {
      debugPrint('Error updating font size: $e');
    }
  }

  Future<void> updateModel(String model) async {
    try {
      await _repository.updateSettings(selectedModel: model);
      state = await _repository.getSettings();
    } catch (e) {
      debugPrint('Error updating model: $e');
    }
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
      debugPrint('Error updating stats: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive database
    Hive.initFlutter();
    
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
      debugPrint('Error loading initial settings: $e');
    }
    
    // Initialize other providers with saved values
    // Note: These will be properly loaded by SettingsController in the widget tree
    
    runApp(StudyKingApp());
  } catch (e, stackTrace) {
    debugPrint('❌ Error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

class StudyKingApp extends ConsumerWidget {
  const StudyKingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to settings changes
    final settings = ref.watch(settingsProvider);
    final isLoading = ref.watch(settingsLoadingProvider);
    
    // Initialize providers with saved values from main()
    if (isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(apiKeyProvider.notifier).state = settings.apiKey;
        ref.read(apiBaseUrlProvider.notifier).state = settings.apiBaseUrl;
        ref.read(selectedModelProvider.notifier).state = settings.selectedModel;
        // Mark as loaded - providers will sync on changes now
      });
    }
    
    return MaterialApp(
      title: 'StudyKing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: settings.fontSize, height: 1.5),
          bodyMedium: TextStyle(fontSize: settings.fontSize, height: 1.4),
          bodySmall: TextStyle(fontSize: settings.fontSize * 0.875, height: 1.3),
          titleLarge: TextStyle(fontSize: settings.fontSize * 1.5, height: 1.3),
          titleMedium: TextStyle(fontSize: settings.fontSize * 1.25, height: 1.35),
          titleSmall: TextStyle(fontSize: settings.fontSize * 1.125, height: 1.35),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: settings.fontSize, height: 1.5),
          bodyMedium: TextStyle(fontSize: settings.fontSize, height: 1.4),
          bodySmall: TextStyle(fontSize: settings.fontSize * 0.875, height: 1.3),
          titleLarge: TextStyle(fontSize: settings.fontSize * 1.5, height: 1.3),
          titleMedium: TextStyle(fontSize: settings.fontSize * 1.25, height: 1.35),
          titleSmall: TextStyle(fontSize: settings.fontSize * 1.125, height: 1.35),
        ),
      ),
      themeMode: settings.themeModeEnum,
      home: const MainScreen(),
      routes: {
        '/api-config': (context) => const ApiConfigScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
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
    return Scaffold(
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_arrow_outlined),
            selectedIcon: Icon(Icons.play_arrow),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
