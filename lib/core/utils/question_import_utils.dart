import 'dart:convert';
import 'dart:io';

import '../data/enums.dart';
import '../data/models/markscheme_model.dart';
import '../data/models/question_model.dart';
import '../../core/errors/result.dart';
import 'id_generator.dart';
import 'logger.dart';

enum ConflictStrategy { skipExisting, overwrite }

class QuestionImportUtils {
  static final Logger _logger = const Logger('QuestionImportUtils');

  static Future<Result<List<Question>>> importFromJson(
    String filePath, {
    Set<String> existingIds = const {},
    ConflictStrategy strategy = ConflictStrategy.skipExisting,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Result.failure('File_not_found: $filePath');
      }
      final jsonStr = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;
      final questions = <Question>[];
      var skipped = 0;
      for (final json in jsonList) {
        final q = Question.fromJson(json as Map<String, dynamic>);
        if (existingIds.contains(q.id)) {
          if (strategy == ConflictStrategy.skipExisting) {
            skipped++;
            continue;
          }
        }
        questions.add(q);
      }
      _logger.i('Imported ${questions.length} questions from JSON ($skipped skipped)');
      return Result.success(questions);
    } catch (e) {
      _logger.w('Failed to import JSON', e);
      return Result.failure(e.toString());
    }
  }

  static Future<Result<List<Question>>> importFromCsv(
    String filePath, {
    Set<String> existingIds = const {},
    ConflictStrategy strategy = ConflictStrategy.skipExisting,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Result.failure('File_not_found: $filePath');
      }
      final lines = await file.readAsLines();
      if (lines.length < 2) {
        return Result.success([]);
      }
      final questions = <Question>[];
      var skipped = 0;
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final q = _parseCsvRow(line);
        if (q == null) continue;
        if (existingIds.contains(q.id)) {
          if (strategy == ConflictStrategy.skipExisting) {
            skipped++;
            continue;
          }
        }
        questions.add(q);
      }
      _logger.i('Imported ${questions.length} questions from CSV ($skipped skipped)');
      return Result.success(questions);
    } catch (e) {
      _logger.w('Failed to import CSV', e);
      return Result.failure(e.toString());
    }
  }

  static Question? _parseCsvRow(String line) {
    try {
      final values = _parseCsvLine(line);
      final colCount = values.length;

      if (colCount >= 18) {
        return _parseCsvRowV18(values);
      }
      if (colCount >= 13) {
        return _parseCsvRowV13(values);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Question _parseCsvRowV18(List<String> values) {
    final options = values[8].split('|').where((s) => s.isNotEmpty).toList();
    final correctAnswer = values[10].trim();
    final markscheme = correctAnswer.isNotEmpty
        ? Markscheme(correctAnswer: correctAnswer)
        : null;

    final type = _parseType(values[2]);

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(values[16]);
    } catch (_) {
      createdAt = DateTime.now();
    }
    DateTime updatedAt;
    try {
      updatedAt = DateTime.parse(values[17]);
    } catch (_) {
      updatedAt = DateTime.now();
    }

    DateTime? nextReview;
    if (values[15].isNotEmpty) {
      try {
        nextReview = DateTime.parse(values[15]);
      } catch (_) {}
    }

    return Question(
      id: values[0].isNotEmpty ? values[0] : IdGenerator.generate('question'),
      text: values[1],
      type: type,
      difficulty: int.tryParse(values[3]) ?? 1,
      subjectId: values[4],
      topicId: values[5],
      variantIds: values[6].split('|').where((s) => s.isNotEmpty).toList(),
      sourceIds: values[7].split('|').where((s) => s.isNotEmpty).toList(),
      options: options,
      allowedAnswerTypes: values[9],
      markscheme: markscheme,
      explanation: values[11].isNotEmpty ? values[11] : null,
      tags: values[12].split(';').where((s) => s.isNotEmpty).toList(),
      model: values[13].isNotEmpty ? values[13] : null,
      difficultyText: values[14].isNotEmpty ? values[14] : null,
      nextReview: nextReview,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Question _parseCsvRowV13(List<String> values) {
    final options = values[7].split('|').where((s) => s.isNotEmpty).toList();
    final correctAnswer = values[8].trim();
    final markscheme = correctAnswer.isNotEmpty
        ? Markscheme(correctAnswer: correctAnswer)
        : null;

    final type = _parseType(values[2]);

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(values[11]);
    } catch (_) {
      createdAt = DateTime.now();
    }
    DateTime updatedAt;
    try {
      updatedAt = DateTime.parse(values[12]);
    } catch (_) {
      updatedAt = DateTime.now();
    }

    return Question(
      id: values[0].isNotEmpty ? values[0] : IdGenerator.generate('question'),
      text: values[1],
      type: type,
      difficulty: int.tryParse(values[3]) ?? 1,
      subjectId: values[4],
      topicId: values[5],
      sourceIds: values[6].split('|').where((s) => s.isNotEmpty).toList(),
      options: options,
      markscheme: markscheme,
      explanation: values[9].isNotEmpty ? values[9] : null,
      model: values[10].isNotEmpty ? values[10] : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static QuestionType _parseType(String typeValue) {
    final typeIdx = int.tryParse(typeValue);
    if (typeIdx != null && typeIdx >= 0 && typeIdx < QuestionType.values.length) {
      return QuestionType.values[typeIdx];
    }
    return QuestionType.singleChoice;
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          current.write(c);
        }
      } else {
        if (c == '"') {
          inQuotes = true;
        } else if (c == ',') {
          result.add(current.toString());
          current = StringBuffer();
        } else {
          current.write(c);
        }
      }
    }
    result.add(current.toString());
    return result;
  }

  static Future<Result<List<Question>>> importFromText(
    String text, {
    Set<String> existingIds = const {},
  }) async {
    try {
      final lines = text.trim().split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isEmpty) return Result.success([]);
      final questions = <Question>[];
      for (final line in lines) {
        final q = _parseTextLine(line);
        if (q == null) {
          final fallback = Question(
            id: IdGenerator.generate('question'),
            text: line,
            type: QuestionType.typedAnswer,
            subjectId: '',
            topicId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          questions.add(fallback);
        } else {
          questions.add(q);
        }
      }
      return Result.success(questions);
    } catch (e) {
      _logger.w('Failed to import from text', e);
      return Result.failure(e.toString());
    }
  }

  static Question? _parseTextLine(String line) {
    final parts = line.split('||');
    if (parts.length < 2) return null;

    final text = parts[0].trim();
    if (text.isEmpty) return null;

    final answer = parts.length > 1 ? parts[1].trim() : '';
    final typeStr = parts.length > 2 ? parts[2].trim().toLowerCase() : '';
    final subjectId = parts.length > 3 ? parts[3].trim() : '';
    final topicId = parts.length > 4 ? parts[4].trim() : '';

    QuestionType type;
    switch (typeStr) {
      case 'singlechoice':
      case 'single_choice':
      case 'sc':
        type = QuestionType.singleChoice;
        break;
      case 'multichoice':
      case 'multi_choice':
      case 'mc':
        type = QuestionType.multiChoice;
        break;
      case 'typed':
      case 'typedanswer':
      case 'typed_answer':
      case 'ta':
        type = QuestionType.typedAnswer;
        break;
      default:
        type = answer.isNotEmpty ? QuestionType.typedAnswer : QuestionType.typedAnswer;
    }

    Markscheme? markscheme;
    if (answer.isNotEmpty) {
      markscheme = Markscheme(correctAnswer: answer);
    }

    return Question(
      id: IdGenerator.generate('question'),
      text: text,
      type: type,
      subjectId: subjectId,
      topicId: topicId,
      markscheme: markscheme,
      explanation: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Future<Result<List<Question>>> importFromJsonString(
    String jsonStr, {
    Set<String> existingIds = const {},
    ConflictStrategy strategy = ConflictStrategy.skipExisting,
  }) async {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;
      final questions = <Question>[];
      var skipped = 0;
      for (final json in jsonList) {
        final q = Question.fromJson(json as Map<String, dynamic>);
        if (existingIds.contains(q.id)) {
          if (strategy == ConflictStrategy.skipExisting) {
            skipped++;
            continue;
          }
        }
        questions.add(q);
      }
      _logger.i('Imported ${questions.length} questions from JSON string ($skipped skipped)');
      return Result.success(questions);
    } catch (e) {
      _logger.w('Failed to import from JSON string', e);
      return Result.failure(e.toString());
    }
  }
}
