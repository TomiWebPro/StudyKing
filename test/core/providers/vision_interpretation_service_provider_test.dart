import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart'
    show selectedModelProvider;
import 'package:studyking/core/providers/llm_providers.dart'
    show llmServiceProvider;
import 'package:studyking/core/providers/service_providers.dart'
    show visionInterpretationServiceProvider;
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/vision_interpretation_service.dart';

class _FakeLlmService extends LlmService {
  final String response;

  _FakeLlmService(this.response)
      : super(
          config: const LlmConfiguration(
            provider: LlmProvider.openRouter,
            apiKey: 'fake-key',
            backupModel: 'm',
          ),
        );

  @override
  Future<Result<String>> chat({
    required String message,
    required String modelId,
    String? systemPrompt,
    String localeName = 'en',
    ConversationMemory? memory,
    List<Map<String, String>>? history,
    String feature = 'general',
  }) async =>
      Result.success(response);
}

void main() {
  group('visionInterpretationServiceProvider', () {
    test('builds a VisionInterpretationService that routes images through OCR',
        () async {
      final container = ProviderContainer(overrides: [
        llmServiceProvider.overrideWithValue(_FakeLlmService('y = 2x')),
        selectedModelProvider.overrideWith((ref) => 'fake-model'),
      ]);

      final service = container.read(visionInterpretationServiceProvider);
      expect(service, isA<VisionInterpretationService>());

      final pngBytes = Uint8List.fromList(
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3],
      );
      final result = await service.interpretImage(pngBytes);

      expect(result.isSuccess, isTrue);
      expect(result.data, 'y = 2x');
      container.dispose();
    });

    test('reports failure when the vision model returns empty text', () async {
      final container = ProviderContainer(overrides: [
        llmServiceProvider.overrideWithValue(_FakeLlmService('   ')),
        selectedModelProvider.overrideWith((ref) => 'fake-model'),
      ]);

      final service = container.read(visionInterpretationServiceProvider);
      final result = await service.interpretImage(
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2]),
      );

      expect(result.isFailure, isTrue);
      container.dispose();
    });
  });
}
