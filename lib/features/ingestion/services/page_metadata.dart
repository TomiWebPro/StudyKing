import 'package:hive/hive.dart';
import 'package:studyking/core/utils/logger.dart';

/// Metadata extracted from a fetched web page.
class PageMetadata {
  final String? title;
  final String? description;
  final String? author;
  final String? publicationDate;
  final String? siteName;
  final String? canonicalUrl;

  const PageMetadata({
    this.title,
    this.description,
    this.author,
    this.publicationDate,
    this.siteName,
    this.canonicalUrl,
  });

  factory PageMetadata.fromMap(Map<String, dynamic> map) {
    String? str(String key) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return null;
    }

    return PageMetadata(
      title: str('title'),
      description: str('description'),
      author: str('author'),
      publicationDate: str('publicationDate'),
      siteName: str('siteName'),
      canonicalUrl: str('canonicalUrl'),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'author': author,
        'publicationDate': publicationDate,
        'siteName': siteName,
        'canonicalUrl': canonicalUrl,
      };

  PageMetadata copyWith({
    String? title,
    String? description,
    String? author,
    String? publicationDate,
    String? siteName,
    String? canonicalUrl,
  }) {
    return PageMetadata(
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      publicationDate: publicationDate ?? this.publicationDate,
      siteName: siteName ?? this.siteName,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
    );
  }

  bool get isEmpty =>
      title == null &&
      description == null &&
      author == null &&
      publicationDate == null &&
      siteName == null &&
      canonicalUrl == null;
}

/// The result of scraping a web page: cleaned main content plus metadata.
class ScrapedPage {
  final String content;
  final PageMetadata metadata;
  final bool fromCache;

  const ScrapedPage({
    required this.content,
    required this.metadata,
    this.fromCache = false,
  });

  ScrapedPage copyWith({
    String? content,
    PageMetadata? metadata,
    bool? fromCache,
  }) {
    return ScrapedPage(
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

/// Abstraction over a cache for scraped pages so the scraper can be tested
/// without Hive and without performing real network calls.
abstract class ScrapeCache {
  Future<ScrapedPage?> get(String url);
  Future<void> put(String url, ScrapedPage page);
  Future<void> clear();
}

/// In-memory cache used for offline/deterministic tests and as a fallback
/// when a persistent cache is unavailable.
class InMemoryScrapeCache implements ScrapeCache {
  final Duration ttl;
  final Map<String, _CacheEntry> _entries = {};

  InMemoryScrapeCache({this.ttl = const Duration(hours: 24)});

  @override
  Future<ScrapedPage?> get(String url) async {
    final entry = _entries[url];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(url);
      return null;
    }
    return entry.page;
  }

  @override
  Future<void> put(String url, ScrapedPage page) async {
    _entries[url] = _CacheEntry(
      page: page,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  @override
  Future<void> clear() async => _entries.clear();
}

class _CacheEntry {
  final ScrapedPage page;
  final DateTime expiresAt;
  _CacheEntry({required this.page, required this.expiresAt});
}

/// Hive-backed persistent cache with a time-to-live. Any failure (e.g. Hive
/// not initialised in the current environment) is logged and the cache is
/// transparently disabled so scraping still works.
class HiveScrapeCache implements ScrapeCache {
  static final Logger _logger = const Logger('HiveScrapeCache');

  final String boxName;
  final Duration ttl;

  Box? _box;
  bool _unavailable = false;

  HiveScrapeCache({
    this.boxName = 'web_scraper_cache',
    this.ttl = const Duration(hours: 24),
  });

  Future<Box> _ensureBox() async {
    if (_unavailable) throw StateError('cache unavailable');
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(boxName);
    return _box!;
  }

  @override
  Future<ScrapedPage?> get(String url) async {
    try {
      final box = await _ensureBox();
      final raw = box.get(url);
      if (raw is! Map) return null;
      final expiresAt = raw['expiresAt'] as int?;
      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await box.delete(url);
        return null;
      }
      final metaRaw = raw['metadata'];
      final meta = metaRaw is Map
          ? PageMetadata.fromMap(Map<String, dynamic>.from(metaRaw))
          : const PageMetadata();
      return ScrapedPage(
        content: (raw['content'] as String?) ?? '',
        metadata: meta,
        fromCache: true,
      );
    } catch (e) {
      _unavailable = true;
      _logger.w('Scrape cache read failed; disabling cache', e);
      return null;
    }
  }

  @override
  Future<void> put(String url, ScrapedPage page) async {
    try {
      final box = await _ensureBox();
      await box.put(url, {
        'content': page.content,
        'metadata': page.metadata.toMap(),
        'expiresAt': DateTime.now().add(ttl).millisecondsSinceEpoch,
      });
    } catch (e) {
      _unavailable = true;
      _logger.w('Scrape cache write failed; disabling cache', e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      final box = await _ensureBox();
      await box.clear();
    } catch (e) {
      _logger.w('Scrape cache clear failed', e);
    }
  }

  Future<void> dispose() async {
    try {
      await _box?.close();
    } catch (e) {
      _logger.w('Scrape cache close failed', e);
    }
  }
}
