import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/ingestion/services/page_metadata.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' show MockClient;

void main() {
  const htmlBody = '<html><head><title>Page</title></head>'
      '<body><p>Readable web page content used by scraper tests.</p></body></html>';

  http.Response okResponse() => http.Response(
        htmlBody,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );

  group('web scraper fetch', () {
    test('extracts content and metadata from html', () async {
      final client = MockClient((request) async {
        final body = '<html><head><title>My Page</title>'
            '<meta name="description" content="desc"></head>'
            '<body><p>This is some readable web page content that should be '
            'extracted properly by the scraper implementation in tests.</p>'
            '</body></html>';
        return http.Response(
          body,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final scraper = WebScraper(httpClient: client);

      final result = await scraper.fetchPageContent('https://example.com');

      expect(result.isSuccess, isTrue);
      expect(result.data!.content, contains('readable web page content'));
      expect(result.data!.metadata.title, 'My Page');
      expect(result.data!.metadata.description, 'desc');
      scraper.dispose();
    });

    test('returns failure for an invalid url', () async {
      final client = MockClient((_) async => http.Response('x', 200));
      final scraper = WebScraper(httpClient: client);

      final result = await scraper.fetchPageContent('not-a-url');

      expect(result.isFailure, isTrue);
      scraper.dispose();
    });

    test('returns failure for a non-200 response', () async {
      final client = MockClient((_) async => http.Response('err', 404));
      final scraper = WebScraper(httpClient: client);

      final result = await scraper.fetchPageContent('https://example.com');

      expect(result.isFailure, isTrue);
      scraper.dispose();
    });

    test('returns failure when no readable content is found', () async {
      final client = MockClient((_) async => http.Response(
        '<html><body></body></html>',
        200,
        headers: {'content-type': 'text/html'},
      ));
      final scraper = WebScraper(httpClient: client);

      final result = await scraper.fetchPageContent('https://example.com');

      expect(result.isFailure, isTrue);
      scraper.dispose();
    });
  });

  group('web scraper cache', () {
    test('serves repeat fetches from cache without a second HTTP call',
        () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return okResponse();
      });
      final scraper = WebScraper(
        httpClient: client,
        cache: InMemoryScrapeCache(),
      );

      final first = await scraper.fetchPageContent('https://example.com');
      final second = await scraper.fetchPageContent('https://example.com');

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(second.data!.fromCache, isTrue);
      expect(second.data!.content, equals(first.data!.content));
      expect(requestCount, equals(1));
      scraper.dispose();
    });

    test('refetches after the cache entry expires', () async {
      var requestCount = 0;
      final client = MockClient((_) async {
        requestCount++;
        return okResponse();
      });
      final scraper = WebScraper(
        httpClient: client,
        cache: InMemoryScrapeCache(ttl: const Duration(milliseconds: 100)),
      );

      final first = await scraper.fetchPageContent('https://example.com');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final second = await scraper.fetchPageContent('https://example.com');

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(second.data!.fromCache, isFalse);
      expect(requestCount, equals(2));
      scraper.dispose();
    });
  });

  group('web scraper politeness', () {
    test('enforces the politeness delay between successive fetches',
        () async {
      final requestTimes = <DateTime>[];
      final client = MockClient((_) async {
        requestTimes.add(DateTime.now());
        return okResponse();
      });
      final scraper = WebScraper(
        httpClient: client,
        politenessDelay: const Duration(milliseconds: 400),
      );

      await scraper.fetchPageContent('https://example.com/first');
      await scraper.fetchPageContent('https://example.com/second');

      expect(requestTimes, hasLength(2));
      final gap = requestTimes[1].difference(requestTimes[0]);
      expect(gap, greaterThanOrEqualTo(const Duration(milliseconds: 350)));
      scraper.dispose();
    });

    test('does not delay the first fetch', () async {
      final stopwatch = Stopwatch()..start();
      final client = MockClient((_) async => okResponse());
      final scraper = WebScraper(
        httpClient: client,
        politenessDelay: const Duration(seconds: 5),
      );

      final result = await scraper.fetchPageContent('https://example.com');

      expect(result.isSuccess, isTrue);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
      scraper.dispose();
    });
  });
}
