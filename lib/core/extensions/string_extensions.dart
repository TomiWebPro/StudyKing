extension StringExtension on String {
  bool get isBlank => trim().isEmpty;

  bool get isNotBlank => trim().isNotEmpty;

  String? get trimmedOrNull {
    final trimmed = trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  String get sentenceCase {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  bool equalsIgnoreCase(String other) =>
      toLowerCase() == other.toLowerCase();

  String? get nullIfEmpty => isEmpty ? null : this;
}
