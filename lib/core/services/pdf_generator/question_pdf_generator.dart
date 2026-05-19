
import 'package:flutter/material.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';

/// PDF Question Generator Service
/// 
/// Generates PDF files with:
/// - Question bank for students (no answers)
/// - Markscheme with solutions (for teachers)
/// - Mixed format with customizable options
class QuestionPDFGenerator {
  final List<dynamic> _questions = [];
  Map<String, dynamic>? _metadata;
  String _localeName = 'en';

  /// Add a question to the PDF
  void addQuestion(
    String id,
    String text,
    String? markscheme,
    bool showAnswers,
  ) {
    _questions.add({
      'id': id,
      'text': text,
      'markscheme': showAnswers ? markscheme : null,
    });
  }

  /// Set the locale for localized output
  void setLocaleName(String localeName) {
    _localeName = localeName;
  }

  /// Set metadata for the PDF
  void setMetadata({
    String? title,
    String? author,
    String? subject,
    List<String>? keywords,
  }) {
    _metadata = {
      'title': title,
      'author': author,
      'subject': subject,
      'keywords': keywords,
    };
  }

  /// Generate PDF
  /// Note: PDF generation requires dart_pdf package.
  /// Returns a text representation as fallback.
  Future<String> generate() async {
    return _generatePlaceholderPDF();
  }

  /// Export questions to JSON
  Future<Map<String, dynamic>> exportToJSON({
    bool includeAnswers = true,
    String? subjectId,
  }) async {
    final filteredQuestions = subjectId != null
        ? _questions.where((q) => q['subjectId'] == subjectId).toList()
        : _questions;

    return {
      'metadata': _metadata ?? {},
      'generatedAt': DateTime.now().toIso8601String(),
      'totalQuestions': filteredQuestions.length,
      'includeAnswers': includeAnswers,
      'questions': filteredQuestions,
    };
  }

  /// Export to CSV for spreadsheet analysis
  Future<String> exportToCSV() async {
    // Format CSV data
    return _generateCSV();
  }

  String _generatePlaceholderPDF() {
    // Placeholder - returns a simple text representation
    // In production, this would generate actual PDF bytes
    final l10n = lookupAppLocalizations(Locale(_localeName));
    final totalLabel = l10n.totalQuestions;
    StringBuffer sb = StringBuffer();
    sb.writeln('PDF QUESTION GENERATOR');
    sb.writeln('======================');
    sb.writeln('$totalLabel: ${_questions.length}');
    sb.writeln('Metadata: ${_metadata ?? "None"}');
    sb.writeln('');
    
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      sb.writeln('Question ${i + 1}: ${q['text']}');
      if (q['markscheme'] != null) {
        sb.writeln('Answer: ${q['markscheme']}');
      }
      sb.writeln('');
    }
    
    return sb.toString();
  }

  String _generateCSV() {
    StringBuffer sb = StringBuffer();
    sb.writeln('ID,Question,Answer,Markscheme');
    
    for (final q in _questions) {
      final id = q['id'];
      final text = '${q['text']}'.replaceAll(',', ';');
      final answer = q['markscheme'] ?? 'N/A';
      sb.writeln('$id,"$text",$answer');
    }
    
    return sb.toString();
  }

  /// Generate practice PDF (questions only, no answers)
  Future<String> generatePracticePDF({
    required String subjectName,
    required String title,
  }) async {
    return await generateWithAnswers(false);
  }

  /// Generate answer key PDF (answers only)
  Future<String> generateAnswerKeyPDF({
    required String subjectName,
    required String title,
  }) async {
    return await generateWithAnswers(true);
  }

  Future<String> generateWithAnswers(bool showAnswers) async {
    // Filter questions based on showAnswers flag
    final finalQuestions = _questions.map((q) {
      if (!showAnswers) {
        return {
          ...q,
          'markscheme': null,
        };
      }
      return q;
    }).toList();

    _questions.clear();
    _questions.addAll(finalQuestions);
    
    return await generate();
  }

  void clear() {
    _questions.clear();
    _metadata = null;
  }
}
