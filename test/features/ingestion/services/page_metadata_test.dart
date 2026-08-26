import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/features/ingestion/services/page_metadata.dart';

void main() {
  group('PageMetadata', () {
    test('fromMap ignores blank strings', () {
      final m = PageMetadata.fromMap({
        'title': 'T',
        'description': '   ',
        'author': 'A',
      });
      expect(m.title, 'T');
      expect(m.description, isNull);
      expect(m.author, 'A');
    });

    test('toMap round-trips populated values', () {
      final m = PageMetadata(
        title: 'T',
        author: 'A',
        canonicalUrl: 'https://x.com',
      );
      final map = m.toMap();
      expect(map['title'], 'T');
      expect(map['author'], 'A');
      expect(map['canonicalUrl'], 'https://x.com');
      expect(PageMetadata.fromMap(map).title, 'T');
    });

    test('isEmpty is true when nothing is set', () {
      expect(const PageMetadata().isEmpty, isTrue);
      expect(const PageMetadata(title: 'x').isEmpty, isFalse);
    });

    test('copyWith overrides only provided fields', () {
      final m = const PageMetadata(title: 'T').copyWith(description: 'D');
      expect(m.title, 'T');
      expect(m.description, 'D');
    });
  });

  group('InMemoryScrapeCache', () {
    test('stores, retrieves and clears pages', () async {
      final cache = InMemoryScrapeCache();
      final page = ScrapedPage(
        content: 'c',
        metadata: const PageMetadata(title: 'T'),
      );
      await cache.put('u', page);

      final got = await cache.get('u');
      expect(got, isNotNull);
      expect(got!.content, 'c');
      expect(got.metadata.title, 'T');

      await cache.clear();
      expect(await cache.get('u'), isNull);
    });

    test('expires entries after the ttl', () async {
      final cache = InMemoryScrapeCache(ttl: Duration.zero);
      await cache.put('u', ScrapedPage(
        content: 'c',
        metadata: const PageMetadata(),
      ));
      // With a zero ttl the entry is immediately expired.
      expect(await cache.get('u'), isNull);
    });
  });

}
