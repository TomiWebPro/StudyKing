import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/data.dart';
import 'package:studyking/features/settings/presentation/api_config_screen.dart';
import 'package:studyking/features/settings/presentation/profile_screen.dart';
import 'package:studyking/features/settings/presentation/settings_screen.dart';
import 'package:studyking/features/subjects/presentation/subject_list_view.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/practice/presentation/practice_screen.dart';

// Global database instance
final database = DatabaseService(
  topicRepository: TopicRepository(),
  questionRepository: QuestionRepository(),
  attemptRepository: AttemptRepository(),
  lessonRepository: LessonRepository(),
  sessionRepository: StudySessionRepository(),
  subjectRepository: SubjectRepository(),
);

// Global settings manager
class SettingsManager {
  static ThemeMode themeMode = ThemeMode.light;
  static double fontSize = 16.0;
  static int totalSessionCount = 0;
  static int totalStudyTimeMs = 0;
  static int totalQuestions = 0;

  static String apiBaseUrl = 'https://openrouter.ai/api/v1';
  static String apiKey = '';

  static String selectedModel = '';

  static void updateTheme(ThemeMode mode) {
    themeMode = mode;
  }

  static void updateFontSize(double size) {
    fontSize = size;
  }

  static void setApiKey(String key) {
    apiKey = key;
  }

  static void updateModel(String model) {
    selectedModel = model;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive database
  await Hive.initFlutter();
  await Hive.openBox('subjects');
  await Hive.openBox('topics');
  await Hive.openBox('questions');
  await Hive.openBox('attempts');
  await Hive.openBox('lessons');
  await Hive.openBox('sessions');
  
  runApp(const StudyKingApp());
}

class StudyKingApp extends StatelessWidget {
  const StudyKingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = SettingsManager.themeMode;
    final fontSize = SettingsManager.fontSize;
    
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
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize, height: 1.5),
          bodyMedium: TextStyle(fontSize: fontSize, height: 1.4),
          bodySmall: TextStyle(fontSize: fontSize * 0.875, height: 1.3),
          titleLarge: TextStyle(fontSize: fontSize * 1.5, height: 1.3),
          titleMedium: TextStyle(fontSize: fontSize * 1.25, height: 1.35),
          titleSmall: TextStyle(fontSize: fontSize * 1.125, height: 1.35),
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
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: fontSize, height: 1.5),
          bodyMedium: TextStyle(fontSize: fontSize, height: 1.4),
          bodySmall: TextStyle(fontSize: fontSize * 0.875, height: 1.3),
          titleLarge: TextStyle(fontSize: fontSize * 1.5, height: 1.3),
          titleMedium: TextStyle(fontSize: fontSize * 1.25, height: 1.35),
          titleSmall: TextStyle(fontSize: fontSize * 1.125, height: 1.35),
        ),
      ),
      themeMode: themeMode,
      home: const MainScreen(),
      routes: {
        '/api-config': (context) => const ApiConfigScreen(),
        '/profile': (context) => const ProfileScreen(),
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
      body: _screens[_selectedIndex],
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
