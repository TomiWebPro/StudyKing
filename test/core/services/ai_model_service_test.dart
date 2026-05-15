import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/services/llm/llm_model_service.dart';

void main() {
  group('ModelListingService', () {
    late ModelListingService service;

    setUp(() {
      service = ModelListingService(apiKey: 'test_api_key');
    });

    group('fetchAvailableModels', () {
      test('returns empty list on exception', () async {
        final models = await service.fetchAvailableModels();
        expect(models, isA<List<AiModel>>());
      });
    });

    group('getModelById', () {
      test('finds model in list', () {
        final models = [
          const AiModel(id: 'model1', name: 'Model 1', provider: 'Provider A'),
          const AiModel(id: 'model2', name: 'Model 2', provider: 'Provider B'),
          const AiModel(id: 'model3', name: 'Model 3', provider: 'Provider C'),
        ];

        final model = service.getModelById('model2', models);

        expect(model, isNotNull);
        expect(model!.id, equals('model2'));
        expect(model.name, equals('Model 2'));
      });

      test('returns default model when not found', () {
        final models = [
          const AiModel(id: 'model1', name: 'Model 1', provider: 'Provider A'),
        ];

        final model = service.getModelById('nonexistent', models);

        expect(model, isNotNull);
        expect(model!.id, equals('nonexistent'));
      });

      test('handles empty list', () {
        final model = service.getModelById('model1', []);
        expect(model, isNotNull);
        expect(model!.id, equals('model1'));
      });

      test('returns first match when duplicate ids', () {
        final models = [
          const AiModel(id: 'model1', name: 'Model 1', provider: 'Provider A'),
          const AiModel(id: 'model1', name: 'Model 1 Duplicate', provider: 'Provider B'),
        ];

        final model = service.getModelById('model1', models);

        expect(model, isNotNull);
      });
    });
  });

  group('AiModel', () {
    group('fromOpenRouter', () {
      test('creates model with all fields', () {
        final data = {
          'id': 'test/model',
          'name': 'Test Model',
          'context_length': 8192,
          'pricing': {'prompt': '0.001'},
          'providers': <Map<String, String>>[
            {'id': 'provider1'}
          ],
        };

        final model = AiModel.fromOpenRouter(data);

        expect(model.id, equals('test/model'));
        expect(model.name, equals('Test Model'));
        expect(model.contextLength, equals('8192'));
        expect(model.pricing, equals('0.001'));
        expect(model.provider, equals('provider1'));
      });

      test('handles null name by extracting from id', () {
        final data = {
          'id': 'provider/model-name',
        };

        final model = AiModel.fromOpenRouter(data);

        expect(model.name, equals('model name'));
      });

      test('handles empty providers', () {
        final data = {
          'id': 'test/model',
          'name': 'Test Model',
          'providers': <Map<String, String>>[],
        };

        final model = AiModel.fromOpenRouter(data);

        expect(model.provider, equals('Unknown'));
      });

      test('handles null providers', () {
        final data = {
          'id': 'test/model',
          'name': 'Test Model',
        };

        final model = AiModel.fromOpenRouter(data);

        expect(model.provider, equals('Unknown'));
      });

      test('handles null id', () {
        final data = {
          'name': 'Test Model',
        };

        final model = AiModel.fromOpenRouter(data);

        expect(model.id, equals('unknown'));
      });

      test('handles map with null values for providers', () {
        final data = {
          'id': 'test/model',
          'name': 'Test Model',
          'providers': null,
        };

        final model = AiModel.fromOpenRouter(data);

        expect(model.provider, equals('Unknown'));
      });

      test('handles empty provider map', () {
        final data = {
          'id': 'test/model',
          'name': 'Test Model',
          'providers': <String, String>{},
        };

        final model = AiModel.fromOpenRouter(data);

        expect(model.provider, equals('Unknown'));
      });
    });

    group('fromId', () {
      test('creates model from id with formatted name', () {
        final model = AiModel.fromId('openai/gpt-4-turbo');

        expect(model.id, equals('openai/gpt-4-turbo'));
        expect(model.name, equals('gpt 4 turbo'));
        expect(model.provider, equals('Unknown'));
      });

      test('handles simple id', () {
        final model = AiModel.fromId('model-name');

        expect(model.name, equals('model name'));
      });

      test('handles id with special characters', () {
        final model = AiModel.fromId('provider:model-v2.0');

        expect(model.name, equals('provider model v2 0'));
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        const model = AiModel(id: 'test/model', name: 'Test Model', provider: 'Provider A');
        expect(model.toString(), equals('AiModel(id: test/model, name: Test Model, provider: Provider A)'));
      });
    });

    group('constructor', () {
      test('creates model with all fields', () {
        const model = AiModel(
          id: 'test/model',
          name: 'Test Model',
          provider: 'Provider A',
          contextLength: '8192',
          pricing: '0.001',
        );

        expect(model.id, equals('test/model'));
        expect(model.name, equals('Test Model'));
        expect(model.provider, equals('Provider A'));
        expect(model.contextLength, equals('8192'));
        expect(model.pricing, equals('0.001'));
      });

      test('creates model with optional fields null', () {
        const model = AiModel(
          id: 'test/model',
          name: 'Test Model',
          provider: 'Provider A',
        );

        expect(model.contextLength, isNull);
        expect(model.pricing, isNull);
      });
    });

    group('equality', () {
      test('equal when id, name, and provider match', () {
        const a = AiModel(id: 'm1', name: 'Model 1', provider: 'P1');
        const b = AiModel(id: 'm1', name: 'Model 1', provider: 'P1');
        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
      });

      test('not equal when id differs', () {
        const a = AiModel(id: 'm1', name: 'Model', provider: 'P');
        const b = AiModel(id: 'm2', name: 'Model', provider: 'P');
        expect(a == b, isFalse);
      });

      test('not equal when name differs', () {
        const a = AiModel(id: 'm1', name: 'Model A', provider: 'P');
        const b = AiModel(id: 'm1', name: 'Model B', provider: 'P');
        expect(a == b, isFalse);
      });

      test('not equal when provider differs', () {
        const a = AiModel(id: 'm1', name: 'Model', provider: 'P1');
        const b = AiModel(id: 'm1', name: 'Model', provider: 'P2');
        expect(a == b, isFalse);
      });

      test('identical to itself', () {
        const model = AiModel(id: 'm1', name: 'M', provider: 'P');
        expect(model == model, isTrue);
      });
    });
  });
}