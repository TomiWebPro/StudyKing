import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/models/dynamic_lesson_types.dart';

void main() {
  group('DynamicLessonTypes', () {
    test('fetchLessonTypes populates map on successful response', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((options) {
        if (options.path == '/models/platform/database.json') {
          return ResponseBody.fromString(
            jsonEncode({
              'types': [
                {'math': 'Mathematics'},
                {'phy': 'Physics'},
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        throw StateError('Unexpected path: ${options.path}');
      });

      final service = DynamicLessonTypes(dio: dio);
      await service.fetchLessonTypes();

      expect(service.getLessonTypes(), containsAll(['math', 'phy']));
      expect(service.getLessonTypeById('math'), 'Mathematics');
      expect(service.containsLessonType('phy'), isTrue);
    });

    test('fetchLessonTypes clears map on network error', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((_) => throw DioException(requestOptions: RequestOptions(path: '/x')));

      final service = DynamicLessonTypes(dio: dio);
      await service.fetchLessonTypes();

      expect(service.getLessonTypes(), isEmpty);
      expect(service.containsLessonType('math'), isFalse);
    });

    test('fetchLessonTypes handles non-200 status codes', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((options) {
        if (options.path == '/models/platform/database.json') {
          return ResponseBody.fromString(
            jsonEncode({'types': []}),
            404,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        throw StateError('Unexpected path: ${options.path}');
      });

      final service = DynamicLessonTypes(dio: dio);
      await service.fetchLessonTypes();

      expect(service.getLessonTypes(), isEmpty);
    });

    test('fetchLessonTypes handles non-Map response data', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((options) {
        if (options.path == '/models/platform/database.json') {
          return ResponseBody.fromString(
            jsonEncode({'types': 'not-a-map'}),
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        throw StateError('Unexpected path: ${options.path}');
      });

      final service = DynamicLessonTypes(dio: dio);
      await service.fetchLessonTypes();

      expect(service.getLessonTypes(), isEmpty);
    });

    test('fetchLessonTypes handles non-List types', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((options) {
        if (options.path == '/models/platform/database.json') {
          return ResponseBody.fromString(
            jsonEncode({'types': {'math': 'Mathematics'}}),
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        throw StateError('Unexpected path: ${options.path}');
      });

      final service = DynamicLessonTypes(dio: dio);
      await service.fetchLessonTypes();

      expect(service.getLessonTypes(), isEmpty);
    });

    test('fetchLessonType returns parsed model and wraps errors', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((options) {
        if (options.path == '/api/v1/lesson/types') {
          return ResponseBody.fromString(
            jsonEncode({
              'id': 'math',
              'name': 'Mathematics',
              'description': 'Math lessons',
              'config': {'level': 'advanced'},
              'created_at': '2026-05-11T00:00:00.000Z',
            }),
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        }
        throw DioException(requestOptions: options, message: 'not found');
      });

      final service = DynamicLessonTypes(dio: dio);
      final lesson = await service.fetchLessonType('math');

      expect(lesson.id, 'math');
      expect(lesson.config?['level'], 'advanced');

      final errorDio = Dio();
      errorDio.httpClientAdapter = _FakeAdapter((options) => throw DioException(requestOptions: options, message: 'boom'));
      final failing = DynamicLessonTypes(dio: errorDio);

      expect(
        () => failing.fetchLessonType('x'),
        throwsA(isA<LessonTypeError>()),
      );
    });

    test('addLessonType and removeLessonType swallow network errors', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((options) {
        if (options.method == 'POST' || options.method == 'DELETE') {
          throw DioException(requestOptions: options, message: 'network failed');
        }
        return ResponseBody.fromString('', 200);
      });

      final service = DynamicLessonTypes(dio: dio);

      await service.addLessonType('a', 'A');
      await service.removeLessonType('a');
    });

    test('getLessonTypeById returns null for non-existent type', () {
      final service = DynamicLessonTypes();
      expect(service.getLessonTypeById('nonexistent'), isNull);
    });

    test('containsLessonType returns false for non-existent type', () {
      final service = DynamicLessonTypes();
      expect(service.containsLessonType('nonexistent'), isFalse);
    });
  });

  group('LessonType', () {
    test('json conversion and copyWith preserve/override fields', () {
      final source = LessonType.fromJson({
        'id': 'bio',
        'name': 'Biology',
        'description': 'Bio desc',
        'config': {'topic': 'cells'},
        'created_at': '2026-05-11T00:00:00.000Z',
      });

      final copy = source.copyWith(name: 'Biology 2');

      expect(source.toJson()['id'], 'bio');
      expect(source.createdAt, DateTime.parse('2026-05-11T00:00:00.000Z'));
      expect(copy.name, 'Biology 2');
      expect(copy.id, 'bio');
      expect(LessonTypeError('x').toString(), 'x');
    });

    test('LessonType handles null config in json', () {
      final lesson = LessonType.fromJson({
        'id': 'chem',
        'name': 'Chemistry',
        'description': null,
        'config': null,
        'created_at': null,
      });

      expect(lesson.id, 'chem');
      expect(lesson.description, isNull);
      expect(lesson.config, isNull);
      expect(lesson.createdAt, isNull);
    });

    test('LessonType copyWith preserves all fields', () {
      final source = LessonType(
        id: 'test-id',
        name: 'Test Name',
        description: 'Test Description',
        config: {'key': 'value'},
        createdAt: DateTime(2026, 1, 1),
      );

      final copyId = source.copyWith(id: 'new-id');
      expect(copyId.id, 'new-id');
      expect(copyId.name, source.name);

      final copyName = source.copyWith(name: 'New Name');
      expect(copyName.name, 'New Name');
      expect(copyName.id, source.id);

      final copyDescription = source.copyWith(description: 'New Desc');
      expect(copyDescription.description, 'New Desc');

      final copyConfig = source.copyWith(config: {'new': 'config'});
      expect(copyConfig.config, {'new': 'config'});

      final copyCreatedAt = source.copyWith(createdAt: DateTime(2026, 6, 1));
      expect(copyCreatedAt.createdAt, DateTime(2026, 6, 1));
    });

    test('LessonType toJson handles all fields correctly', () {
      final lesson = LessonType(
        id: 'test-id',
        name: 'Test Name',
        description: 'Test Desc',
        config: {'key': 'value'},
        createdAt: DateTime(2026, 5, 11, 12, 30, 0),
      );

      final json = lesson.toJson();

      expect(json['id'], 'test-id');
      expect(json['name'], 'Test Name');
      expect(json['description'], 'Test Desc');
      expect(json['config'], {'key': 'value'});
      expect(json['created_at'], '2026-05-11T12:30:00.000');
    });

    test('LessonTypeError toString returns message', () {
      final error = LessonTypeError('Test error message');
      expect(error.toString(), 'Test error message');
      expect(error.message, 'Test error message');
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

    test('getAllLessonTypesWithMeta returns LessonType objects', () {
      final store = DBLessonTypes();
      store.setLessonType('chem', 'Chemistry');

      final lessons = store.getAllLessonTypesWithMeta();
      expect(lessons.length, 1);
      expect(lessons.first.id, 'chem');
      expect(lessons.first.name, 'Chemistry');
    });

    test('removeFromStore handles non-existent key', () {
      final store = DBLessonTypes();
      store.setLessonType('math', 'Math');

      store.removeFromStore('nonexistent');
      expect(store.getAllLessonTypes(), contains('math'));
    });

    test('getStore returns unmodifiable map', () {
      final store = DBLessonTypes();
      store.setLessonType('bio', 'Biology');

      final storeMap = store.getStore();
      expect(() => storeMap.clear(), throwsUnsupportedError);
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }
}
