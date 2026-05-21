import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/database_service.dart';
import 'package:studyking/core/data/repositories/attempt_repository.dart';
import 'package:studyking/core/data/repositories/session_repository.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';
import 'package:studyking/features/questions/data/repositories/question_repository.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';
import 'package:studyking/features/teaching/data/repositories/conversation_repository.dart';
import 'package:studyking/features/teaching/data/repositories/tutor_session_repository.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import 'package:studyking/core/utils/logger.dart';

DatabaseService? _databaseService;

final databaseProvider = Provider<DatabaseService>((ref) {
  return _databaseService ?? DatabaseService(
    topicRepository: TopicRepository(),
    questionRepository: QuestionRepository(),
    attemptRepository: AttemptRepository(),
    lessonRepository: LessonRepository(),
    sessionRepository: SessionRepository(),
    subjectRepository: SubjectRepository(),
    conversationRepository: ConversationRepository(),
    tutorSessionRepository: TutorSessionRepository(),
  );
});

void initDatabaseService(DatabaseService db) {
  _databaseService = db;
}

SettingsRepository? _settingsRepo;

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return _settingsRepo!;
});

void initSettingsRepository(SettingsRepository repo) {
  _settingsRepo = repo;
}

class SettingsController extends StateNotifier<SettingsBox> {
  static final Logger _logger = const Logger('SettingsController');
  final SettingsRepository _repository;
  bool _hasLoadedOnce = false;

  SettingsController(this._repository) : super(SettingsBox()) {
    _loadSettings();
  }

  SettingsBox get currentState => state;

  Future<void> _loadSettings() async {
    if (_hasLoadedOnce) return;
    _hasLoadedOnce = true;
    final result = await _repository.getSettings();
    if (result.isSuccess) {
      state = result.data!;
    } else {
      _logger.w('Error loading settings: ${result.error}');
    }
  }

  Future<void> updateSettings(SettingsUpdate update, {LlmProvider? llmProvider}) async {
    final updateResult = await _repository.updateSettings(update);
    if (updateResult.isFailure) {
      _logger.w('Error updating settings: ${updateResult.error}');
      return;
    }
    if (llmProvider != null) {
      await _repository.saveProvider(llmProvider);
    }
    final settingsResult = await _repository.getSettings();
    if (settingsResult.isSuccess) {
      state = settingsResult.data!;
    } else {
      _logger.w('Error loading settings after update: ${settingsResult.error}');
    }
  }

  Future<void> saveApiKey(String key) async {
    final result = await _repository.saveApiKey(service: 'default', key: key);
    if (result.isFailure) {
      _logger.w('Error saving API key: ${result.error}');
      return;
    }
    await _loadSettings();
  }

  Future<void> updateStats({
    int? sessionCount,
    int? studyTimeMs,
    int? questions,
  }) async {
    final statsResult = await _repository.updateStats(
      sessionCount: sessionCount,
      studyTimeMs: studyTimeMs,
      questions: questions,
    );
    if (statsResult.isFailure) {
      _logger.w('Error updating stats: ${statsResult.error}');
      return;
    }
    final settingsResult = await _repository.getSettings();
    if (settingsResult.isSuccess) {
      state = settingsResult.data!;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, SettingsBox>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider));
});

final llmProviderProvider = StateProvider<LlmProvider>((ref) => LlmProvider.openRouter);

String? _initialLanguageCode;

void setInitialLanguageCode(String code) {
  _initialLanguageCode = code;
}

final _localeLogger = const Logger('localeProvider');

final localeProvider = StateProvider<Locale>((ref) {
  try {
    if (_initialLanguageCode != null && _initialLanguageCode!.isNotEmpty) {
      return Locale(_initialLanguageCode!);
    }
    if (Hive.isBoxOpen(HiveBoxNames.profile)) {
      final box = Hive.box(HiveBoxNames.profile);
      final lang = box.get('language', defaultValue: '') as String;
      if (lang.isNotEmpty) {
        return Locale(lang);
      }
    }
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == deviceLocale.languageCode) {
        return supported;
      }
    }
  } catch (e) {
    _localeLogger.w('Failed to get device locale', e);
  }
  _localeLogger.w('Falling back to en locale');
  return const Locale('en');
});

final l10nProvider = StateProvider<AppLocalizations?>((ref) => null);
