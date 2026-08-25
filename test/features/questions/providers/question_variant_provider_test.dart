import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart' show selectedModelProvider;
import 'package:studyking/core/providers/llm_providers.dart' show llmServiceProvider;
import 'package:studyking/features/questions/providers/question_providers.dart'
    show questionRepositoryProvider, questionVariantServiceProvider;
import 'package:studyking/features/questions/services/question_variant_service.dart';

import '../services/question_variant_service_test.dart'
    show FakeQuestionRepository, FakeLlmService, buildSourceQuestion, validVariantJson;

void main() {
  test('questionVariantServiceProvider wires deps and persists variants', () async {
    final fakeRepo = FakeQuestionRepository();
    final fakeLlm = FakeLlmService(
      queuedResponses: [Result.success(validVariantJson)],
    );

    final container = ProviderContainer(overrides: [
      questionRepositoryProvider.overrideWithValue(fakeRepo),
      llmServiceProvider.overrideWithValue(fakeLlm),
      selectedModelProvider.overrideWith((ref) => 'model-x'),
    ]);

    final service = container.read(questionVariantServiceProvider);
    expect(service, isA<QuestionVariantService>());

    // Behavioral assertion: the injected fake repo is used by the service.
    final result = await service.generateVariants(buildSourceQuestion(), count: 2);

    expect(result.isSuccess, isTrue);
    expect(fakeRepo.created.length, 2);
    expect(fakeLlm.requestedMessages.single,
        contains('generate practice VARIANTS'));
  });
}
