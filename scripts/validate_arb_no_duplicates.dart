import 'dart:io';

/// Validates that ARB files contain no duplicate keys.
/// Returns exit code 1 if duplicates are found.
void main(List<String> args) {
  final paths = args.isNotEmpty
      ? args
      : [
          'lib/l10n/app_en.arb',
          'lib/l10n/app_es.arb',
        ];

  var hadError = false;

  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('File not found: $path');
      hadError = true;
      continue;
    }

    final content = file.readAsStringSync();
    final keys = <String, int>{};

    // Parse raw text to find all top-level keys (before JSON parsing)
    final keyPattern = RegExp(r'^\s{2}"([^"]+)"\s*:', multiLine: true);
    for (final match in keyPattern.allMatches(content)) {
      final key = match.group(1)!;
      if (key.startsWith('@') || key == '@@locale') continue;
      keys[key] = (keys[key] ?? 0) + 1;
    }

    final duplicates = keys.entries.where((e) => e.value > 1).toList();
    if (duplicates.isNotEmpty) {
      stderr.writeln('ERROR: $path contains ${duplicates.length} duplicate key(s):');
      for (final dup in duplicates) {
        stderr.writeln('  "${dup.key}" appears ${dup.value} times');
      }
      hadError = true;
    } else {
      stdout.writeln('OK: $path has no duplicate keys');
    }
  }

  if (hadError) {
    stderr.writeln('\nDuplicate keys in ARB files cause silent translation '
        'degradation because JSON takes the last value.');
    exitCode = 1;
  }
}
