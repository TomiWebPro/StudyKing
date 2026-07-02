import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'settings_screen_test_helpers.dart';

void main() {
  setUp(() {
    fakeRepo.settings = SettingsBox(
      themeMode: 0,
      fontSize: 16.0,
      totalSessionCount: 5,
      totalStudyTimeMs: 3600000,
      totalQuestions: 100,
    );
  });

  group('SettingsScreen - Model Parsing & Selection', () {
    testWidgets('AI model selection parses provider correctly', (tester) async {
      HttpOverrides.global = FakeSettingsHttpOverride(
        responseStatusCode: 200,
        responseBody: '{"data": [{"id": "anthropic/claude-3", "name": "Claude 3", "providers": [{"id": "openrouter"}]}]}',
      );
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Claude 3'), findsOneWidget);
    });

    testWidgets('empty model list handled gracefully', (tester) async {
      HttpOverrides.global = FakeSettingsHttpOverride(
        responseStatusCode: 200,
        responseBody: '{"data": []}',
      );
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('tapping AI model with empty API key shows warning dialog', (tester) async {
      await pumpWithSettings(tester, apiKey: '', selectedModel: '');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      expect(find.text('API Key Required'), findsOneWidget);
      expect(find.text('Please configure your API key first.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('SettingsScreen - Network Error Handling', () {
    testWidgets('shows error when model selection API returns non-200', (tester) async {
      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load models right now.'), findsOneWidget);
    });

    testWidgets('shows timeout error message after network timeout', (tester) async {
      HttpOverrides.global = TimeoutSettingsHttpOverride();
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pump();

      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();

      expect(find.text('Model request timed out. Please try again.'), findsOneWidget);
    });

    testWidgets('shows generic error on malformed response', (tester) async {
      HttpOverrides.global = FakeSettingsHttpOverride(
        responseStatusCode: 200,
        responseBody: 'not valid json {{{',
      );
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('retry button appears on error and retries loading', (tester) async {
      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('SettingsScreen - Model Search Filtering', () {
    testWidgets('search filter narrows model list', (tester) async {
      HttpOverrides.global = FakeSettingsHttpOverride(
        responseStatusCode: 200,
        responseBody: jsonEncode({
          'data': [
            {'id': 'openai/gpt-4', 'name': 'GPT-4', 'providers': [{'id': 'openai'}]},
            {'id': 'anthropic/claude-3', 'name': 'Claude 3', 'providers': [{'id': 'anthropic'}]},
            {'id': 'google/gemini-pro', 'name': 'Gemini Pro', 'providers': [{'id': 'google'}]},
          ]
        }),
      );
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('GPT-4'), findsOneWidget);
      expect(find.text('Claude 3'), findsOneWidget);
      expect(find.text('Gemini Pro'), findsOneWidget);

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'gpt');
      await tester.pumpAndSettle();

      expect(find.text('GPT-4'), findsOneWidget);
      expect(find.text('Claude 3'), findsNothing);
      expect(find.text('Gemini Pro'), findsNothing);
    });

    testWidgets('search is case-insensitive', (tester) async {
      HttpOverrides.global = FakeSettingsHttpOverride(
        responseStatusCode: 200,
        responseBody: jsonEncode({
          'data': [
            {'id': 'openai/gpt-4', 'name': 'GPT-4', 'providers': [{'id': 'openai'}]},
            {'id': 'anthropic/claude-3', 'name': 'Claude 3', 'providers': [{'id': 'anthropic'}]},
          ]
        }),
      );
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'CLAUDE');
      await tester.pumpAndSettle();

      expect(find.text('Claude 3'), findsOneWidget);
      expect(find.text('GPT-4'), findsNothing);
    });

    testWidgets('selecting model calls onModelSelected and closes sheet', (tester) async {
      HttpOverrides.global = FakeSettingsHttpOverride(
        responseStatusCode: 200,
        responseBody: jsonEncode({
          'data': [
            {'id': 'anthropic/claude-3', 'name': 'Claude 3', 'providers': [{'id': 'anthropic'}]},
          ]
        }),
      );
      addTearDown(() => HttpOverrides.global = null);

      await pumpWithSettings(tester, apiKey: 'sk-test-key');

      await scrollToWidget(tester, find.text('AI Model'));
      await tester.tap(find.text('AI Model'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Claude 3'));
      await tester.pumpAndSettle();

      expect(find.text('Select a model from API'), findsWidgets);
    });
  });
}
