import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/features/ingestion/services/web_scraper.dart';

class _MockClient extends http.BaseClient {
  final _ResponseSpec Function(http.BaseRequest) _handler;

  _MockClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final spec = _handler(request);
    return http.StreamedResponse(
      Stream.value(spec.bodyBytes),
      spec.statusCode,
    );
  }
}

class _ResponseSpec {
  final int statusCode;
  final List<int> bodyBytes;
  _ResponseSpec(this.statusCode, this.bodyBytes);

  factory _ResponseSpec.ok(String body) =>
      _ResponseSpec(200, body.codeUnits);

  factory _ResponseSpec.status(int code) =>
      _ResponseSpec(code, ''.codeUnits);
}

class _ThrowingClient extends http.BaseClient {
  final Exception exception;
  _ThrowingClient(this.exception);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw exception;
  }
}

void main() {
  group('WebScraper', () {
    group('fetchPageContent', () {
      test('returns failure for URL without scheme', () async {
        final scraper = WebScraper(httpClient: _MockClient((_) => _ResponseSpec.ok('')));
        final result = await scraper.fetchPageContent('example.com');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('no scheme'));
      });

      test('returns failure for bad URL', () async {
        final scraper = WebScraper(httpClient: _MockClient((_) => _ResponseSpec.ok('')));
        final result = await scraper.fetchPageContent('');
        expect(result.isFailure, isTrue);
      });

      test('returns content on HTTP 200', () async {
        final scraper = WebScraper(httpClient: _MockClient((_) => _ResponseSpec.ok('Hello World content here with enough chars')));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Hello World'));
      });

      test('returns failure on HTTP 404', () async {
        final scraper = WebScraper(httpClient: _MockClient((_) => _ResponseSpec.status(404)));
        final result = await scraper.fetchPageContent('https://example.com/404');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('404'));
      });

      test('returns failure on HTTP 500', () async {
        final scraper = WebScraper(httpClient: _MockClient((_) => _ResponseSpec.status(500)));
        final result = await scraper.fetchPageContent('https://example.com/500');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('500'));
      });

      test('returns failure on HTTP 403', () async {
        final scraper = WebScraper(httpClient: _MockClient((_) => _ResponseSpec.status(403)));
        final result = await scraper.fetchPageContent('https://example.com/403');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('403'));
      });

      test('returns failure for empty body', () async {
        final scraper = WebScraper(httpClient: _MockClient((_) => _ResponseSpec.ok('')));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('No readable content'));
      });

      test('strips script and style tags', () async {
        final html = '<html><head><script>alert("x")</script><style>.cls{}</style></head><body><p>Visible content paragraph text here for testing purposes</p></body></html>';
        final scraper = WebScraper(httpClient: _MockClient((_) => _ResponseSpec.ok(html)));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isSuccess, isTrue);
        expect(result.data, contains('Visible content'));
        expect(result.data, isNot(contains('alert')));
        expect(result.data, isNot(contains('.cls')));
      });

      test('handles unclosed script tag returns no readable content', () async {
        final html = '<html><script>unclosed<body><p>Content line that is long enough for filtering</p></body>';
        final scraper = WebScraper(httpClient: _MockClient((_) => _ResponseSpec.ok(html)));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('No readable content'));
      });

      test('filters lines shorter than 20 characters', () async {
        final html = '<p>Short</p><p>\n</p><p>This is a long enough content line for the test</p>';
        final scraper = WebScraper(httpClient: _MockClient((_) => _ResponseSpec.ok(html)));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNot(contains('Short')));
        expect(result.data, contains('long enough content'));
      });

      test('returns failure when fetch throws exception', () async {
        final scraper = WebScraper(httpClient: _ThrowingClient(Exception('Network error')));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Network error'));
      });
    });

    group('dispose', () {
      test('dispose closes the HTTP client', () {
        final client = _MockClient((_) => _ResponseSpec.ok('test'));
        final scraper = WebScraper(httpClient: client);
        scraper.dispose();
      });
    });
  });
}
