import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/models/dynamic_lesson_types.dart';
import 'package:studyking/models/llm_models.dart';

void main() {
  group('ModelPrice and DynamicModel', () {
    test('parses model price json with fallback defaults', () {
      final parsed = ModelPrice.fromJson({
        'modelId': 'm1',
        'inputPrice': '0.5',
        'outputPrice': 1.5,
        'cacheReadPrice': null,
      });

      expect(parsed.modelId, 'm1');
      expect(parsed.inputPrice, 0.5);
      expect(parsed.outputPrice, 1.5);
      expect(parsed.cacheReadPrice, 0.0);
      expect(parsed.contextWindow, 4096);
      expect(parsed.toJson()['modelId'], 'm1');
    });

    test('getBestPrice and calculateCost handle empty and non-empty prices', () {
      final empty = DynamicModel(
        provider: 'openrouter',
        modelName: 'm-empty',
        providerDisplayName: 'Empty',
      );

      final priced = DynamicModel(
        provider: 'openrouter',
        modelName: 'm-priced',
        providerDisplayName: 'Priced',
        prices: const [
          ModelPrice(modelId: 'p1', inputPrice: 0.8, outputPrice: 0.9, cacheReadPrice: 0.0, contextWindow: 1000),
          ModelPrice(modelId: 'p2', inputPrice: 0.4, outputPrice: 0.4, cacheReadPrice: 0.0, contextWindow: 2000),
        ],
      );

      expect(empty.getBestPrice().modelId, 'm-empty');
      expect(empty.calculateCost(1000, 1000), 0.0);

      final best = priced.getBestPrice();
      expect(best.modelId, 'p2');
      expect(priced.calculateCost(500000, 500000), closeTo(0.4, 1e-10));
      expect(priced.toString(), contains('fetched:false'));
    });
  });

  group('OpenRouter request/response models', () {
    test('OpenRouterRequest serializes optional fields correctly', () {
      const full = OpenRouterRequest(
        model: 'm1',
        messages: [
          {'role': 'user', 'content': 'Hello'}
        ],
        temperature: 0.4,
        maxTokens: 256,
        topP: 0.9,
        stream: true,
      );
      const minimal = OpenRouterRequest(
        model: 'm2',
        messages: [],
      );

      final fullJson = full.toJson();
      final minimalJson = minimal.toJson();

      expect(fullJson['max_tokens'], 256);
      expect(fullJson['top_p'], 0.9);
      expect(fullJson['stream'], isTrue);

      expect(minimalJson.containsKey('max_tokens'), isFalse);
      expect(minimalJson.containsKey('top_p'), isFalse);
      expect(minimalJson['temperature'], 0.7);
      expect(minimal.toString(), contains('messages: 0'));
    });

    test('OpenRouterResponse and Message parse with defaults', () {
      final response = OpenRouterResponse.fromJson({
        'id': 'r1',
        'choices': [
          {'role': 'assistant', 'content': 'Answer'}
        ],
      });

      final empty = OpenRouterResponse.fromJson({'id': 'r2'});
      final message = Message.fromJson({});

      expect(response.object, 'chat.completion');
      expect(response.created, 0);
      expect(response.getAssistantResponse()?.content, 'Answer');
      expect(response.toString(), contains('choices: 1'));

      expect(empty.choices, isEmpty);
      expect(empty.getAssistantResponse(), isNull);

      expect(message.role, 'unknown');
      expect(message.content, '');
      expect(message.toString(), contains('0 chars'));
    });
  });

  group('DBLessonTypes', () {
    test('stores, lists, removes, and clears lesson types', () {
      final store = DBLessonTypes();

      store.setLessonType('math', 'Mathematics');
      store.setLessonType('phy', 'Physics');

      expect(store.getAllLessonTypes(), containsAll(['math', 'phy']));
      expect(store.getAllLessonTypesWithMeta().map((e) => e.name), containsAll(['Mathematics', 'Physics']));

      final unmodifiable = store.getStore();
      expect(() => unmodifiable['new'] = 'X', throwsUnsupportedError);

      store.removeFromStore('math');
      expect(store.getAllLessonTypes(), isNot(contains('math')));

      store.clearStore();
      expect(store.getAllLessonTypes(), isEmpty);
    });
  });
}
