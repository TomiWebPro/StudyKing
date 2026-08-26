import 'package:studyking/core/utils/string_extensions.dart';

/// Result of attempting to parse a syllabus-switch intent from a user message.
class SyllabusSwitchResult {
  final bool matched;
  /// The requested syllabus title, or `null` when the student asked to view
  /// all syllabi (e.g. `/syllabus all`).
  final String? syllabusTitle;

  const SyllabusSwitchResult({required this.matched, this.syllabusTitle});
}

/// Parses tutor messages for an explicit intent to switch the active syllabus.
///
/// Supports two forms:
///  * A command: `/syllabus <title>`, `/switchsyllabus <title>`,
///    `/syllabus all` (or empty) to clear the selection.
///  * Natural language: "switch to Math syllabus", "change syllabus to
///    Algebra", "use Science syllabus", etc.
class SyllabusSwitchParser {
  static const List<String> _switchKeywords = [
    'switch',
    'change',
    'use',
    'select',
    'open',
    'go to',
  ];

  SyllabusSwitchParser._();

  static SyllabusSwitchResult parse(
    String message, {
    required List<String> availableTitles,
  }) {
    final normalized = message.normalized.trim();

    final commandResult = _parseCommand(normalized, availableTitles);
    if (commandResult.matched) return commandResult;

    return _parseNaturalLanguage(normalized, availableTitles);
  }

  static SyllabusSwitchResult _parseCommand(
    String normalized,
    List<String> availableTitles,
  ) {
    String rest = normalized;
    if (rest.startsWith('/switchsyllabus')) {
      rest = rest.substring('/switchsyllabus'.length);
    } else if (rest.startsWith('/syllabus')) {
      rest = rest.substring('/syllabus'.length);
    } else {
      return const SyllabusSwitchResult(matched: false);
    }

    rest = rest.replaceFirst(RegExp(r'^[\s:]+'), '');
    if (rest.isEmpty ||
        rest == 'all' ||
        rest == 'all syllabi' ||
        rest == '*') {
      return const SyllabusSwitchResult(matched: true, syllabusTitle: null);
    }

    final matchedTitle = _matchTitle(rest, availableTitles);
    if (matchedTitle != null) {
      return SyllabusSwitchResult(matched: true, syllabusTitle: matchedTitle);
    }
    // Command form but the title was not recognized.
    return const SyllabusSwitchResult(matched: false);
  }

  static SyllabusSwitchResult _parseNaturalLanguage(
    String normalized,
    List<String> availableTitles,
  ) {
    final mentionsSyllabus = normalized.contains('syllabus');
    final hasSwitchKeyword =
        _switchKeywords.any((k) => normalized.contains(k));
    if (!mentionsSyllabus || !hasSwitchKeyword) {
      return const SyllabusSwitchResult(matched: false);
    }

    final matchedTitle = _matchTitle(normalized, availableTitles);
    if (matchedTitle != null) {
      return SyllabusSwitchResult(matched: true, syllabusTitle: matchedTitle);
    }
    return const SyllabusSwitchResult(matched: false);
  }

  static String? _matchTitle(String text, List<String> availableTitles) {
    for (final title in availableTitles) {
      final normalizedTitle = title.normalized;
      if (normalizedTitle.isNotEmpty && text.contains(normalizedTitle)) {
        return title;
      }
    }
    return null;
  }
}
