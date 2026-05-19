import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/settings.dart';

void main() {
  group('settings barrel', () {
    test('AccessibilityPreferences can be constructed with properties', () {
      final prefs = AccessibilityPreferences(
        boldText: true,
        highContrast: true,
        reduceMotion: false,
        largeTouchTargets: true,
      );
      expect(prefs.boldText, isTrue);
      expect(prefs.highContrast, isTrue);
      expect(prefs.reduceMotion, isFalse);
      expect(prefs.largeTouchTargets, isTrue);
    });

    test('SettingsBox can be constructed with default values', () {
      final box = SettingsBox();
      expect(box.fontSize, SettingsBox.defaultFontSize);
      expect(box.themeModeEnum, ThemeMode.system);
    });

    test('ModelPrice can be constructed and serialized', () {
      final price = ModelPrice(
        modelId: 'gpt-4',
        inputPrice: 10.0,
        outputPrice: 30.0,
        cacheReadPrice: 5.0,
        contextWindow: 8192,
      );
      expect(price.modelId, 'gpt-4');
      expect(price.inputPrice, 10.0);
      expect(price.toJson()['modelId'], 'gpt-4');
    });

    test('DynamicModel getBestPrice returns fallback when prices empty', () {
      final model = DynamicModel(
        provider: 'openai',
        modelName: 'gpt-4',
        providerDisplayName: 'OpenAI',
      );
      final best = model.getBestPrice();
      expect(best.inputPrice, 0.0);
      expect(best.modelId, 'gpt-4');
    });

    test('DynamicModel calculateCost uses best price', () {
      final model = DynamicModel(
        provider: 'openai',
        modelName: 'gpt-4',
        providerDisplayName: 'OpenAI',
        prices: [
          ModelPrice(
            modelId: 'gpt-4',
            inputPrice: 10.0,
            outputPrice: 30.0,
            cacheReadPrice: 5.0,
            contextWindow: 8192,
          ),
        ],
      );
      final cost = model.calculateCost(1000, 500);
      expect(cost, greaterThan(0));
    });

    test('OpenRouterRequest can be constructed and serialized', () {
      final request = OpenRouterRequest(
        model: 'gpt-4',
        messages: [
          {'role': 'user', 'content': 'Hello'},
        ],
        temperature: 0.5,
        maxTokens: 100,
        stream: false,
      );
      final json = request.toJson();
      expect(json['model'], 'gpt-4');
      expect(json['temperature'], 0.5);
      expect(json['max_tokens'], 100);
    });

    test('Message can be constructed from JSON', () {
      final msg = Message.fromJson({
        'role': 'assistant',
        'content': 'Hello world',
      });
      expect(msg.role, 'assistant');
      expect(msg.content, 'Hello world');
    });

    test('OpenRouterResponse getAssistantResponse returns first choice', () {
      final response = OpenRouterResponse(
        id: 'resp1',
        object: 'chat.completion',
        created: 12345,
        choices: [
          Message(role: 'assistant', content: 'Hi'),
        ],
        usage: {'prompt_tokens': 10, 'completion_tokens': 5},
        effectiveDurationMs: 100,
        promptTokensDetails: {},
      );
      expect(response.getAssistantResponse()?.content, 'Hi');
    });

    test('SettingsAPIKey can be constructed and compared', () {
      final key1 = SettingsAPIKey(provider: 'openrouter', key: 'sk-123');
      final key2 = SettingsAPIKey(provider: 'openrouter', key: 'sk-123');
      final key3 = SettingsAPIKey(provider: 'openai', key: 'sk-456');
      expect(key1, equals(key2));
      expect(key1 == key3, isFalse);
    });

    test('UsageRecord calculates totalTokens correctly', () {
      final record = UsageRecord(
        id: 'rec1',
        timestamp: DateTime(2024, 1, 1),
        provider: 'openai',
        modelId: 'gpt-4',
        inputTokens: 100,
        outputTokens: 50,
        totalCost: 0.002,
      );
      expect(record.totalTokens, 150);
      expect(record.inputTokens, 100);
    });

    test('LLMSettingsModel can manage API keys and usage', () {
      final model = LLMSettingsModel();
      expect(model.hasApiKey, isFalse);
      model.addApiKey('openrouter', 'sk-123');
      expect(model.hasApiKey, isTrue);
      expect(model.apiKey!.provider, 'openrouter');

      model.removeApiKey();
      expect(model.hasApiKey, isFalse);
    });

    test('UserProfile can be constructed with properties', () {
      final profile = UserProfile(
        id: 'user1',
        name: 'Alice',
        language: 'es',
        notificationsEnabled: false,
      );
      expect(profile.name, 'Alice');
      expect(profile.language, 'es');
      expect(profile.notificationsEnabled, isFalse);
    });

    test('SettingsRepository can be constructed', () {
      final repo = SettingsRepository();
      expect(repo, isNotNull);
    });

    test('DataBackupService can be constructed', () {
      final service = DataBackupService();
      expect(service, isNotNull);
    });

    test('ApiConfigScreen can be const-constructed', () {
      expect(const ApiConfigScreen(), isA<ApiConfigScreen>());
    });

    test('ProfileScreen can be const-constructed', () {
      expect(const ProfileScreen(), isA<ProfileScreen>());
    });

    test('SettingsScreen can be const-constructed', () {
      expect(const SettingsScreen(), isA<SettingsScreen>());
    });
  });
}
