import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/ingestion/services/web_scraper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' show MockClient;

void main() {
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
}
