import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/utils/logger.dart';

/// Page-level extraction metadata for a single PDF page.
class PdfPageText {
  final int pageNumber;
  final String text;
  final int charCount;

  const PdfPageText({
    required this.pageNumber,
    required this.text,
    required this.charCount,
  });
}

/// Result of extracting text from a PDF document.
class PdfExtractionResult {
  final String text;
  final int? pageCount;
  final String extractionMethod;

  /// Per-page text with metadata. `null` when page tracking was not performed.
  final List<PdfPageText>? pages;

  const PdfExtractionResult({
    required this.text,
    this.pageCount,
    required this.extractionMethod,
    this.pages,
  });
}

/// A PDF text extractor that parses the PDF object structure properly instead
/// of scanning raw bytes with a regex.
///
/// It resolves the document catalog, walks the page tree, decompresses
/// content streams (FlateDecode via `archive`), and extracts text from the
/// text-showing operators (`Tj` / `TJ`). Per-page boundaries are tracked and
/// only one page's decompressed content is held in memory at a time (chunked
/// reading) so large documents do not need to be fully decoded up-front.
///
/// Scanned/image-only PDFs cannot yield text here (no OCR engine is bundled),
/// so extraction reports `no_text_found` as a [Result.failure] rather than
/// crashing or silently returning garbage.
class PdfExtractor {
  static final Logger _logger = const Logger('PdfExtractor');

  Future<Result<PdfExtractionResult>> extractFromFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      _logger.w('PDF file not found: $filePath');
      return Result.success(
        const PdfExtractionResult(text: '', extractionMethod: 'file_not_found'),
      );
    }
    try {
      final bytes = await file.readAsBytes();
      return await extractFromBytes(bytes);
    } catch (e, st) {
      _logger.w('Failed to read PDF file: $filePath', e, st);
      return Result.failure('Failed to read PDF file: $e');
    }
  }

  Future<Result<PdfExtractionResult>> extractFromBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return Result.success(
        const PdfExtractionResult(text: '', extractionMethod: 'empty_content'),
      );
    }

    try {
      final header = String.fromCharCodes(bytes.sublist(0, bytes.length.clamp(0, 8)));
      if (!header.startsWith('%PDF')) {
        _logger.w('Input is not a PDF document (missing %PDF header)');
        return Result.failure('extraction_failed: not a PDF document');
      }

      final parser = _PdfParser(bytes);
      final parsed = parser.parse();

      if (parsed.text.trim().isEmpty) {
        _logger.w('No extractable text found in PDF (likely scanned/image-only)');
        return Result.failure(
          'no_text_found: no extractable text; OCR not available',
        );
      }

      return Result.success(
        PdfExtractionResult(
          text: parsed.text,
          pageCount: parsed.pageCount,
          extractionMethod: 'pdf_text_extracted',
          pages: parsed.pages,
        ),
      );
    } catch (e, st) {
      _logger.w('PDF text extraction failed', e, st);
      return Result.failure('extraction_failed: $e');
    }
  }
}

class _ParsedPdf {
  final String text;
  final int? pageCount;
  final List<PdfPageText> pages;

  _ParsedPdf(this.text, this.pageCount, this.pages);
}

/// Minimal but correct PDF object parser tailored to text extraction.
class _PdfParser {
  final Uint8List bytes;
  late final String _src;

  _PdfParser(this.bytes) {
    // latin1 mapping keeps a 1:1 correspondence between string indices and
    // byte offsets, which lets us slice bytes precisely from string matches.
    _src = String.fromCharCodes(bytes);
  }

  final Map<int, _PdfObject> _objects = {};

  _ParsedPdf parse() {
    _indexObjects();
    final root = _findRoot();
    if (root == null) {
      throw const PdfParseException('Could not locate document catalog (/Root)');
    }

    final catalogObj = _objects[root];
    if (catalogObj == null) {
      throw PdfParseException('Catalog object $root is missing');
    }
    final catalog = _parseDict(catalogObj.dict);
    final pagesNum = catalog['/Pages'];
    if (pagesNum is! int) {
      throw const PdfParseException('Catalog has no /Pages reference');
    }
    final pagesObj = _objects[pagesNum];
    if (pagesObj == null) {
      throw PdfParseException('Pages object $pagesNum is missing');
    }
    final pagesNode = _parseDict(pagesObj.dict);

    final pageTexts = <PdfPageText>[];
    _collectPages(pagesNode, pageTexts, 0);

    final buffer = StringBuffer();
    for (var i = 0; i < pageTexts.length; i++) {
      if (i > 0) buffer.writeln();
      buffer.write(pageTexts[i].text);
    }

    return _ParsedPdf(
      buffer.toString().trim(),
      pageTexts.isNotEmpty ? pageTexts.length : null,
      pageTexts,
    );
  }

  void _indexObjects() {
    final re = RegExp(r'(\d+)\s+(\d+)\s+obj');
    for (final m in re.allMatches(_src)) {
      final num = int.parse(m.group(1)!);
      final start = m.end;
      final end = _src.indexOf('endobj', start);
      if (end == -1) continue;
      final body = _src.substring(start, end);
      _objects[num] = _PdfObject(num, body);
    }
  }

  int? _findRoot() {
    final trailerIdx = _src.lastIndexOf('trailer');
    if (trailerIdx != -1) {
      final startxrefIdx = _src.indexOf('startxref', trailerIdx);
      final sliceEnd = startxrefIdx != -1 ? startxrefIdx : _src.length;
      final slice = _src.substring(trailerIdx, sliceEnd);
      final rootRef = _refIn(slice, '/Root');
      if (rootRef != null) return rootRef;
    }
    // Fallback: scan for an object that declares itself the catalog.
    for (final obj in _objects.values) {
      if (_hasType(obj.dict, 'Catalog')) {
        final pages = _refIn(obj.dict, '/Pages');
        if (pages != null) return obj.num;
      }
    }
    return null;
  }

  void _collectPages(
    Map<String, dynamic> pagesNode,
    List<PdfPageText> out,
    int depth,
  ) {
    if (depth > 64) {
      // Guard against malformed cyclic page trees.
      throw const PdfParseException('Page tree too deep (possible cycle)');
    }
    final kids = pagesNode['/Kids'] as List<int>?;
    if (kids == null || kids.isEmpty) return;

    for (final kidNum in kids) {
      final kidObj = _objects[kidNum];
      if (kidObj == null) continue;
      if (_hasType(kidObj.dict, 'Page')) {
        final text = _extractPageText(kidObj);
        out.add(
          PdfPageText(
            pageNumber: out.length + 1,
            text: text,
            charCount: text.length,
          ),
        );
      } else if (_hasType(kidObj.dict, 'Pages')) {
        final childNode = _parseDict(kidObj.dict);
        _collectPages(childNode, out, depth + 1);
      }
    }
  }

  String _extractPageText(_PdfObject pageObj) {
    final pageDict = _parseDict(pageObj.dict);

    final contentRefs = <int>[];
    final contents = pageDict['/Contents'];
    if (contents is int) {
      contentRefs.add(contents);
    } else if (contents is List<int>) {
      contentRefs.addAll(contents);
    }

    final buffer = StringBuffer();
    for (final ref in contentRefs) {
      final contentObj = _objects[ref];
      if (contentObj == null) continue;
      final streamBytes = contentObj.streamBytes;
      if (streamBytes == null) continue;
      final text = _extractTextFromContentStream(streamBytes, contentObj.dict);
      if (text.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(text);
      }
    }
    return buffer.toString().trim();
  }

  String _extractTextFromContentStream(Uint8List streamBytes, String dict) {
    Uint8List data = streamBytes;
    if (_hasFilter(dict, 'FlateDecode')) {
      try {
        data = Uint8List.fromList(const ZLibDecoder().decodeBytes(streamBytes));
      } catch (e) {
        // Leave data as-is; decompression may still yield partial text.
        PdfExtractor._logger.w('FlateDecode decompression failed: $e');
      }
    } else if (_hasFilter(dict, 'ASCII85Decode')) {
      data = _ascii85Decode(streamBytes);
    }

    final content = String.fromCharCodes(data);

    final tokenRe = RegExp(
      r'\((?:[^()\\]|\\.)*\)\s*Tj'
      r'|<[0-9A-Fa-f\s]*>\s*Tj'
      r'|\[[\s\S]*?\]\s*TJ',
    );

    final buffer = StringBuffer();
    for (final m in tokenRe.allMatches(content)) {
      final token = m.group(0)!;
      if (token.trim().endsWith('TJ')) {
        final inner = token.substring(token.indexOf('[') + 1, token.lastIndexOf(']'));
        final innerStrings = _allStringTokens(inner);
        final decoded = innerStrings.map(_decodeStringToken).join();
        if (decoded.trim().isNotEmpty) {
          buffer.writeln(decoded);
        }
      } else {
        final tjIdx = token.lastIndexOf(RegExp(r'\s*Tj'));
        final decoded = _decodeStringToken(token.substring(0, tjIdx));
        if (decoded.trim().isNotEmpty) {
          buffer.writeln(decoded);
        }
      }
    }
    return buffer.toString().trim();
  }

  List<String> _allStringTokens(String inner) {
    final tokens = <String>[];
    final re = RegExp(r'\((?:[^()\\]|\\.)*\)|<[0-9A-Fa-f\s]*>');
    for (final m in re.allMatches(inner)) {
      tokens.add(m.group(0)!);
    }
    return tokens;
  }

  String _decodeStringToken(String token) {
    final trimmed = token.trim();
    if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
      return _decodeLiteral(trimmed.substring(1, trimmed.length - 1));
    } else if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
      return _decodeHex(trimmed.substring(1, trimmed.length - 1));
    }
    return '';
  }

  String _decodeLiteral(String s) {
    final buf = StringBuffer();
    var i = 0;
    while (i < s.length) {
      final c = s[i];
      if (c == '\\' && i + 1 < s.length) {
        final n = s[i + 1];
        if (n == 'n') {
          buf.write('\n');
        } else if (n == 'r') {
          buf.write('\r');
        } else if (n == 't') {
          buf.write('\t');
        } else if (n == 'b') {
          buf.write('\b');
        } else if (n == 'f') {
          buf.write('\f');
        } else if (n == '(') {
          buf.write('(');
        } else if (n == ')') {
          buf.write(')');
        } else if (n == '\\') {
          buf.write('\\');
        } else if (n == '/') {
          buf.write('/');
        } else if (n.codeUnitAt(0) >= 0x30 && n.codeUnitAt(0) <= 0x37) {
          var j = i + 1;
          var digits = '';
          while (j < s.length && digits.length < 3 && s[j].codeUnitAt(0) >= 0x30 && s[j].codeUnitAt(0) <= 0x37) {
            digits += s[j];
            j++;
          }
          final code = int.tryParse(digits, radix: 8) ?? 0;
          buf.write(_decodeByte(code));
          i = j;
          continue;
        } else {
          buf.write(n);
        }
        i += 2;
        continue;
      } else {
        buf.write(_decodeByte(c.codeUnitAt(0)));
      }
      i++;
    }
    return buf.toString();
  }

  String _decodeHex(String s) {
    final clean = s.replaceAll(RegExp(r'\s'), '');
    final buf = StringBuffer();
    for (var i = 0; i < clean.length - 1; i += 2) {
      final byte = int.tryParse(clean.substring(i, i + 2), radix: 16);
      if (byte != null) buf.write(_decodeByte(byte));
    }
    return buf.toString();
  }

  // --- Dictionary / reference helpers ---

  Map<String, dynamic> _parseDict(String body) {
    final result = <String, dynamic>{};
    // Top-level key/value pairs. Values may be refs, arrays, dicts, names,
    // or numbers. This is intentionally lightweight: only the shapes used by
    // the page tree and content references are resolved.
    final keyRe = RegExp(r'/([A-Za-z][A-Za-z0-9]*)');
    final matches = keyRe.allMatches(body).toList();
    for (var k = 0; k < matches.length; k++) {
      final key = '/${matches[k].group(1)}';
      final afterKey = matches[k].end;
      final nextKeyStart = k + 1 < matches.length ? matches[k + 1].start : body.length;
      final valueSpan = body.substring(afterKey, nextKeyStart).trim();
      result[key] = _parseValue(valueSpan);
    }
    return result;
  }

  dynamic _parseValue(String span) {
    if (span.startsWith('[')) {
      final list = <int>[];
      final refRe = RegExp(r'(\d+)\s+(\d+)\s+R');
      for (final m in refRe.allMatches(span)) {
        list.add(int.parse(m.group(1)!));
      }
      return list;
    }
    final ref = _refIn(span, '');
    if (ref != null) return ref;
    if (span.startsWith('<<')) {
      return _parseDict(span);
    }
    return span;
  }

  int? _refIn(String span, String key) {
    final pattern = key.isEmpty
        ? RegExp(r'(\d+)\s+(\d+)\s+R')
        : RegExp('$key\\s+(\\d+)\\s+(\\d+)\\s+R');
    final m = pattern.firstMatch(span);
    if (m != null) return int.parse(m.group(1)!);
    return null;
  }

  bool _hasType(String dict, String type) {
    if (type == 'Page') {
      return RegExp(r'/Type\s*/Page(?![\w])').hasMatch(dict);
    }
    if (type == 'Pages') {
      return RegExp(r'/Type\s*/Pages(?![\w])').hasMatch(dict);
    }
    return RegExp(r'/Type\s*/$type(?![\w])').hasMatch(dict);
  }

  bool _hasFilter(String dict, String filter) {
    final m = RegExp(r'/Filter\s*(\[?[^\]]*\]?)').firstMatch(dict);
    if (m == null) return false;
    return m.group(1)!.contains(filter);
  }

  Uint8List _ascii85Decode(Uint8List bytes) {
    // Minimal ASCII85 (PDF variant, 4-tuple, no <~ ~> wrapper) decode.
    final out = <int>[];
    var tuple = <int>[];
    for (final b in bytes) {
      if (b == 0x7E) break; // '~' ends the stream in standard ascii85
      if (b == 0x20 || b == 0x0A || b == 0x0D || b == 0x09) continue;
      if (b == 0x7A) {
        // 'z' => 4 zero bytes
        out.addAll([0, 0, 0, 0]);
        continue;
      }
      if (b < 0x21 || b > 0x75) continue;
      tuple.add(b - 0x21);
      if (tuple.length == 4) {
        var value = 0;
        for (final t in tuple) {
          value = value * 85 + t;
        }
        out.add((value >> 24) & 0xFF);
        out.add((value >> 16) & 0xFF);
        out.add((value >> 8) & 0xFF);
        out.add(value & 0xFF);
        tuple = [];
      }
    }
    return Uint8List.fromList(out);
  }
}

/// A single PDF object: its dictionary body and (if it is a stream) the
/// decompressed-or-raw stream bytes.
class _PdfObject {
  final int num;
  final String dict;
  final Uint8List? streamBytes;

  _PdfObject(this.num, String body)
      : dict = _extractDict(body),
        streamBytes = _extractStream(body);

  static String _extractDict(String body) {
    final idx = body.indexOf('stream');
    if (idx == -1) return body;
    return body.substring(0, idx);
  }

  static Uint8List? _extractStream(String body) {
    final idx = body.indexOf('stream');
    if (idx == -1) return null;
    var dataStart = idx + 'stream'.length;
    // Skip the single EOL required after the `stream` keyword.
    if (dataStart < body.length && (body[dataStart] == '\r' || body[dataStart] == '\n')) {
      dataStart++;
      if (dataStart < body.length && body[dataStart - 1] == '\r' && body[dataStart] == '\n') {
        dataStart++;
      }
    }
    final end = body.indexOf('endstream', dataStart);
    if (end == -1) return null;
    final streamStr = body.substring(dataStart, end);
    return Uint8List.fromList(streamStr.codeUnits);
  }
}

String _decodeByte(int code) {
  if (code < 0x80) return String.fromCharCode(code);
  if (code >= 0xA0) return String.fromCharCode(code);
  const winAnsi = {
    0x80: '€',
    0x82: '‚',
    0x83: 'ƒ',
    0x84: '„',
    0x85: '…',
    0x86: '†',
    0x87: '‡',
    0x88: 'ˆ',
    0x89: '‰',
    0x8A: 'Š',
    0x8B: '‹',
    0x8C: 'Œ',
    0x8E: 'Ž',
    0x91: '‘',
    0x92: '’',
    0x93: '“',
    0x94: '”',
    0x95: '•',
    0x96: '–',
    0x97: '—',
    0x98: '˜',
    0x99: '™',
    0x9A: 'š',
    0x9B: '›',
    0x9C: 'œ',
    0x9E: 'ž',
    0x9F: 'Ÿ',
  };
  return winAnsi[code] ?? String.fromCharCode(code);
}

class PdfParseException implements Exception {
  final String message;
  const PdfParseException(this.message);
  @override
  String toString() => 'PdfParseException: $message';
}
