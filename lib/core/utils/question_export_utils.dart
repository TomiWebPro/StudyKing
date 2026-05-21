import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/question_model.dart';
import '../../core/errors/result.dart';
import 'logger.dart';

class QuestionExportUtils {
  static final Logger _logger = const Logger('QuestionExportUtils');

  static String _csvHeader() {
    return 'id,text,type,difficulty,subjectId,topicId,variantIds,sourceIds,options,allowedAnswerTypes,correctAnswer,explanation,tags,model,difficultyText,nextReview,createdAt,updatedAt';
  }

  static String _csvRow(Question q) {
    final correct = q.markscheme?.correctAnswer ?? '';
    final optionsStr = q.options.map((o) => o.replaceAll(',', ';')).join('|');
    final sourceIdsStr = q.sourceIds.join('|');
    final variantIdsStr = q.variantIds.join('|');
    final tagsStr = q.tags.join(';');
    return [
      q.id,
      _csvEscape(q.text),
      q.type.index.toString(),
      q.difficulty.toString(),
      q.subjectId,
      q.topicId,
      variantIdsStr,
      sourceIdsStr,
      optionsStr,
      q.allowedAnswerTypes,
      _csvEscape(correct),
      _csvEscape(q.explanation ?? ''),
      tagsStr,
      q.model ?? '',
      q.difficultyText ?? '',
      q.nextReview?.toIso8601String() ?? '',
      q.createdAt.toIso8601String(),
      q.updatedAt.toIso8601String(),
    ].join(',');
  }

  static String _csvEscape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static Future<Result<String>> exportAsCsv(List<Question> questions, {Directory? directory}) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln(_csvHeader());
      for (final q in questions) {
        buffer.writeln(_csvRow(q));
      }
      final dir = directory ?? await getTemporaryDirectory();
      final file = File('${dir.path}/questions_export.csv');
      await file.writeAsString(buffer.toString());
      _logger.i('Exported ${questions.length} questions to CSV: ${file.path}');
      return Result.success(file.path);
    } catch (e) {
      _logger.w('Failed to export CSV', e);
      return Result.failure(e.toString());
    }
  }

  static Future<Result<String>> exportAsJson(List<Question> questions, {Directory? directory}) async {
    try {
      final jsonList = questions.map((q) => q.toJson()).toList();
      final json = const JsonEncoder.withIndent('  ').convert(jsonList);
      final dir = directory ?? await getTemporaryDirectory();
      final file = File('${dir.path}/questions_export.json');
      await file.writeAsString(json);
      _logger.i('Exported ${questions.length} questions to JSON: ${file.path}');
      return Result.success(file.path);
    } catch (e) {
      _logger.w('Failed to export JSON', e);
      return Result.failure(e.toString());
    }
  }

  static Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }
}
