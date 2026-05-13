import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/services/pdf_upload_coordinator.dart';

void main() {
  group('HeadersAPI', () {
    test('has default timeout constant', () {
      expect(HeadersAPI.defaultTimeout, equals(30000));
    });

    test('call accepts required parameters', () async {
      final headersApi = HeadersAPI();
      final result = await headersApi.call<String>(
        endpoint: '/test',
        headerName: 'Authorization',
        headerToken: 'Bearer token',
      );
      expect(result, isNull);
    });

    test('call with default data returns default on error', () async {
      final headersApi = HeadersAPI();
      final result = await headersApi.call<String>(
        endpoint: '/test',
        headerName: 'X-Test',
        headerToken: 'token',
        defaultData: 'default',
      );
      expect(result, equals('default'));
    });

    test('callRaw accepts url and optional parameters', () async {
      final headersApi = HeadersAPI();
      expect(() => headersApi.callRaw(url: 'http://test.com'), returnsNormally);
    });

    test('callRaw accepts headers parameter', () async {
      final headersApi = HeadersAPI();
      expect(() => headersApi.callRaw(
        url: 'http://test.com',
        headers: {'Content-Type': 'application/json'},
      ), returnsNormally);
    });

    test('callRaw accepts body parameter', () async {
      final headersApi = HeadersAPI();
      expect(() => headersApi.callRaw(
        url: 'http://test.com',
        body: '{"test": true}',
      ), returnsNormally);
    });
  });
}
