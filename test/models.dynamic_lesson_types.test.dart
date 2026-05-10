import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
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
