import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/core/data/models/question_model.dart';
import 'package:studyking/core/data/enums.dart';
import '../models/markscheme_model.dart';

/// Generic Result class for safe error propagation
sealed class Result<T> {
  final T? data;
  final String? error;

  const Result({this.data, this.error});

  factory Result.success(T data) = SuccessResult<T>;
  factory Result.failure(String error) = FailureResult<T>;

  bool get isSuccess => error == null && data != null;
  bool get isFailure => error != null;
}

class SuccessResult<T> extends Result<T> {
  SuccessResult(T data) : super(data: data);
}

class FailureResult<T> extends Result<T> {
  FailureResult(String error) : super(error: error);
}

class QuestionRepository {
  late Box<Question> _box;

  Future<Result<void>> init() async {
    try {
      _box = await Hive.openBox<Question>('questions');
      return Result.success(null);
    } catch (e) {
      debugPrint('Error initializing question repository: $e');
      return Result.failure('Failed to initialize question repository: ${e.toString()}');
    }
  }

  Future<Result<void>> create(Question question) async {
    try {
      await _box.put(question.id, question);
      return Result.success(null);
    } catch (e) {
      debugPrint('Error creating question: $e');
      return Result.failure('Failed to create question: ${e.toString()}');
    }
  }

  Future<Result<Question?>> get(String id) async {
    try {
      final question = _box.get(id);
      return Result.success(question);
    } catch (e) {
      debugPrint('Error getting question: $e');
      return Result.failure('Failed to get question: ${e.toString()}');
    }
  }

  Future<Result<List<Question>>> getAll() async {
    try {
      if (!_box.isOpen) {
        return Result.failure('Question box is not open');
      }
      return Result.success(_box.values.toList());
    } catch (e) {
      debugPrint('Error getting all questions: $e');
      return Result.failure('Failed to get all questions: ${e.toString()}');
    }
  }

  Future<Result<List<Question>>> getByTopic(String topicId) async {
    try {
      if (!_box.isOpen) {
        return Result.failure('Question box is not open');
      }
      final all = _box.values.toList();
      return SuccessResult<List<Question>>(all.where((q) => q.topicId == topicId).toList());
    } catch (e) {
      debugPrint('Error getting questions by topic: $e');
      return Result.failure('Failed to get questions by topic: ${e.toString()}');
    }
  }

  Future<Result<List<Question>>> getBySubject(String subjectId) async {
    try {
      if (!_box.isOpen) {
        return Result.failure('Question bank is not open');
      }
      final all = _box.values.toList();
      return SuccessResult<List<Question>>(all.where((q) => q.subjectId == subjectId).toList());
    } catch (e) {
      debugPrint('Error getting questions by subject: $e');
      return Result.failure('Failed to get questions by subject: ${e.toString()}');
    }
  }

  Future<Result<List<Question>>> getBySubjectAndTopic(
    String subjectId,
    String topicId,
  ) async {
    try {
      if (!_box.isOpen) {
        return Result.failure('Question bank is not open');
      }
      final all = _box.values.toList();
      return SuccessResult<List<Question>>(all.where((q) => 
        q.subjectId == subjectId && q.topicId == topicId
      ).toList());
    } catch (e) {
      debugPrint('Error getting questions by subject and topic: $e');
      return Result.failure('Failed to get questions: ${e.toString()}');
    }
  }

  Future<Result<List<Question>>> getByType(QuestionType type) async {
    try {
      if (!_box.isOpen) {
        return Result.failure('Question bank is not open');
      }
      final all = _box.values.toList();
      return SuccessResult<List<Question>>(all.where((q) => q.type == type).toList());
    } catch (e) {
      debugPrint('Error getting questions by type: $e');
      return Result.failure('Failed to get questions by type: ${e.toString()}');
    }
  }

  Future<Result<List<Question>>> getBySubjectAndType(
    String subjectId,
    QuestionType type,
  ) async {
    try {
      if (!_box.isOpen) {
        return Result.failure('Question bank is not open');
      }
      final all = _box.values.toList();
      return SuccessResult<List<Question>>(all.where((q) => 
        q.subjectId == subjectId && q.type == type
      ).toList());
    } catch (e) {
      debugPrint('Error getting questions by subject and type: $e');
      return Result.failure('Failed to get questions: ${e.toString()}');
    }
  }

  /// Get questions with markscheme for a subject
  Future<Result<List<QuestionWithMarkscheme>>> getQuestionsWithMarkschemes(String subjectId) async {
    try {
      if (!_box.isOpen) {
        return Result.failure('Question bank is not open');
      }
      final questions = _box.values.toList();
      final filtered = questions.where((q) => q.markscheme != null).toList();
      
      if (filtered.isEmpty) {
        return Result.failure('No questions with markscheme found for subject: $subjectId');
      }
      
      return SuccessResult<List<QuestionWithMarkscheme>>(
        filtered.map((q) => QuestionWithMarkscheme(
          question: q, 
          markscheme: q.markscheme!,
        )).toList()
      );
    } catch (e) {
      debugPrint('Error getting questions with markscheme: $e');
      return Result.failure('Failed to get questions with markscheme: ${e.toString()}');
    }
  }

  Future<Result<void>> updateMarkscheme(String questionId, Markscheme markscheme) async {
    try {
      final question = _box.get(questionId);
      if (question == null) {
        return Result.failure('Question not found: $questionId');
      }
      final updated = question.copyWith(markscheme: markscheme);
      await _box.put(questionId, updated);
      return Result.success(null);
    } catch (e) {
      debugPrint('Error updating markscheme: $e');
      return Result.failure('Failed to update markscheme: ${e.toString()}');
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await _box.delete(id);
      return Result.success(null);
    } catch (e) {
      debugPrint('Error deleting question: $e');
      return Result.failure('Failed to delete question: ${e.toString()}');
    }
  }
}

class QuestionWithMarkscheme {
  final Question question;
  final Markscheme markscheme;

  QuestionWithMarkscheme({required this.question, required this.markscheme});
}
