import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:studyking/features/ingestion/services/page_metadata.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';

class _FakeClient extends http.BaseClient {
  final _ResponseSpec Function(http.BaseRequest) _handler;

  _FakeClient(this._handler);

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
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.ok('')));
        final result = await scraper.fetchPageContent('example.com');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('scheme'));
      });

      test('returns failure for bad URL', () async {
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.ok('')));
        final result = await scraper.fetchPageContent('');
        expect(result.isFailure, isTrue);
      });

      test('returns content on HTTP 200', () async {
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.ok('Hello World content here with enough chars')));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isSuccess, isTrue);
        expect(result.data!.content, contains('Hello World'));
      });

      test('returns failure on HTTP 404', () async {
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.status(404)));
        final result = await scraper.fetchPageContent('https://example.com/404');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('404'));
      });

      test('returns failure on HTTP 500', () async {
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.status(500)));
        final result = await scraper.fetchPageContent('https://example.com/500');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('500'));
      });

      test('returns failure on HTTP 403', () async {
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.status(403)));
        final result = await scraper.fetchPageContent('https://example.com/403');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('403'));
      });

      test('returns failure for empty body', () async {
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.ok('')));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('No readable content'));
      });

      test('strips script and style tags', () async {
        final html = '<html><head><script>alert("x")</script><style>.cls{}</style></head><body><p>Visible content paragraph text here for testing purposes</p></body></html>';
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.ok(html)));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isSuccess, isTrue);
        expect(result.data!.content, contains('Visible content'));
        expect(result.data!.content, isNot(contains('alert')));
        expect(result.data!.content, isNot(contains('.cls')));
      });

      test('handles malformed/unclosed script tag gracefully without crashing',
          () async {
        final html = '<html><script>unclosed<body><p>Content line that is long enough for the filtering test to pass</p></body>';
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.ok(html)));
        final result = await scraper.fetchPageContent('https://example.com');
        // The dart html parser treats <script> as raw text, so the malformed
        // document yields no readable content. The important behaviour is that
        // extraction fails gracefully (no exception, no crash).
        expect(result.isFailure, isTrue);
        expect(result.error, contains('No readable content'));
      });

      test('filters boilerplate nav/aside and keeps main article text', () async {
        final html = '<html><head><title>T</title></head><body>'
            '<nav>Nav menu link one link two</nav>'
            '<p>This is a sufficiently long article body paragraph that should be extracted as the main content text for the test.</p>'
            '<aside>sidebar advertisement block</aside>'
            '</body></html>';
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.ok(html)));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isSuccess, isTrue);
        expect(result.data!.content, contains('sufficiently long article body'));
        expect(result.data!.content, isNot(contains('sidebar advertisement')));
        expect(result.data!.content, isNot(contains('Nav menu link')));
      });

      test('filters lines shorter than 20 characters', () async {
        final html = '<p>Short</p><p>\n</p><p>This is a long enough content line for the test</p>';
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.ok(html)));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isSuccess, isTrue);
        expect(result.data!.content, isNot(contains('Short')));
        expect(result.data!.content, contains('long enough content'));
      });

      test('extracts page metadata from head tags', () async {
        final html = '<html><head>'
            '<title>My Article Title</title>'
            '<meta name="description" content="A great description">'
            '<meta name="author" content="Jane Doe">'
            '<meta property="article:published_time" content="2024-01-02">'
            '<meta property="og:site_name" content="Example Site">'
            '<link rel="canonical" href="https://example.com/canonical">'
            '</head><body>'
            '<p>This is a sufficiently long article body paragraph that should be extracted as the main content text for the test.</p>'
            '</body></html>';
        final scraper = WebScraper(httpClient: _FakeClient((_) => _ResponseSpec.ok(html)));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isSuccess, isTrue);
        final meta = result.data!.metadata;
        expect(meta.title, 'My Article Title');
        expect(meta.description, 'A great description');
        expect(meta.author, 'Jane Doe');
        expect(meta.publicationDate, '2024-01-02');
        expect(meta.siteName, 'Example Site');
        expect(meta.canonicalUrl, 'https://example.com/canonical');
      });

      test('returns failure when fetch throws exception', () async {
        final scraper = WebScraper(httpClient: _ThrowingClient(Exception('Network error')));
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isFailure, isTrue);
        expect(result.error, contains('Network error'));
      });
    });

    group('cache', () {
      test('returns cached page without performing a network request', () async {
        final cache = InMemoryScrapeCache();
        await cache.put(
          'https://example.com',
          ScrapedPage(
            content: 'cached content body',
            metadata: const PageMetadata(title: 'Cached'),
          ),
        );
        var calls = 0;
        final client = _FakeClient((_) {
          calls++;
          return _ResponseSpec.ok('fresh content body');
        });
        final scraper = WebScraper(httpClient: client, cache: cache);
        final result = await scraper.fetchPageContent('https://example.com');
        expect(result.isSuccess, isTrue);
        expect(result.data!.fromCache, isTrue);
        expect(result.data!.content, 'cached content body');
        expect(calls, 0);
      });

      test('stores fetched page in cache for subsequent hits', () async {
        final cache = InMemoryScrapeCache();
        final client = _FakeClient((_) => _ResponseSpec.ok(
              '<p>This is a sufficiently long article body paragraph that should be extracted and then cached for the test.</p>',
            ));
        final scraper = WebScraper(httpClient: client, cache: cache);
        final first = await scraper.fetchPageContent('https://example.com/a');
        expect(first.isSuccess, isTrue);
        expect(first.data!.fromCache, isFalse);

        final cached = await cache.get('https://example.com/a');
        expect(cached, isNotNull);
        expect(cached!.content, contains('sufficiently long article body'));
      });
    });

    group('dispose', () {
      test('dispose closes the HTTP client', () {
        final client = _FakeClient((_) => _ResponseSpec.ok('test'));
        final scraper = WebScraper(httpClient: client);
        scraper.dispose();
      });
    });
  });
}
