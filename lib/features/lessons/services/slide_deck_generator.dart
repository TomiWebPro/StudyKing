import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:studyking/core/data/enums.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/utils/logger.dart';
import 'package:studyking/features/lessons/data/models/lesson_block_model.dart';
import 'package:studyking/features/lessons/data/models/lesson_model.dart';
import 'package:studyking/features/lessons/data/repositories/lesson_repository.dart';

enum SlideDeckStyle {
  detailed,
  concise,
  examFocused,
}

class SlideDeckGenerator {
  static final Logger _logger = const Logger('SlideDeckGenerator');

  final LlmService _llmService;
  final String _modelId;
  final LessonRepository _lessonRepository;

  SlideDeckGenerator({
    required LlmService llmService,
    required String modelId,
    required LessonRepository lessonRepository,
  })  : _llmService = llmService,
        _modelId = modelId,
        _lessonRepository = lessonRepository;

  /// Generates a progressive slide deck from source content.
  ///
  /// Returns a [Result] containing a list of [Lesson] objects, one per chapter,
  /// each containing structured slide blocks with chapter/section metadata.
  Future<Result<List<Lesson>>> generateSlideDeck({
    required String subjectId,
    required String topicId,
    required String topicTitle,
    required String sourceContent,
    required String localeName,
    SlideDeckStyle style = SlideDeckStyle.detailed,
  }) async {
    try {
      final structure = await _analyzeStructure(
        sourceContent: sourceContent,
        topicTitle: topicTitle,
        localeName: localeName,
      );

      if (structure.isEmpty) {
        _logger.w('Could not analyze document structure, generating single chapter');
        final singleChapter = _ChapterInfo(
          title: topicTitle,
          sections: [],
          startIndex: 0,
          endIndex: sourceContent.length,
        );
        final singleLessons = await _generateChapters(
          chapters: [singleChapter],
          sourceContent: sourceContent,
          subjectId: subjectId,
          topicId: topicId,
          topicTitle: topicTitle,
          localeName: localeName,
          style: style,
        );
        if (singleLessons.isEmpty) {
          _logger.w('Chapter generation failed for single chapter fallback');
          return Result.failure('SlideDeckGenerator.generateSlideDeck: chapter generation failed');
        }
        final tocLesson = _buildTableOfContents(
          chapters: singleLessons,
          subjectId: subjectId,
          topicId: topicId,
          topicTitle: topicTitle,
        );
        for (final chapter in singleLessons) {
          final createResult = await _lessonRepository.create(chapter);
          if (createResult.isFailure) {
            _logger.w('Failed to save chapter lesson: ${createResult.error}');
          }
        }
        final tocResult = await _lessonRepository.create(tocLesson);
        if (tocResult.isFailure) {
          _logger.w('Failed to save table of contents: ${tocResult.error}');
        }
        return Result.success([tocLesson, ...singleLessons]);
      }

      final chapters = await _generateChapters(
        chapters: structure,
        sourceContent: sourceContent,
        subjectId: subjectId,
        topicId: topicId,
        topicTitle: topicTitle,
        localeName: localeName,
        style: style,
      );

      if (chapters.isEmpty) {
        _logger.w('Chapter generation failed');
        return Result.failure('SlideDeckGenerator.generateSlideDeck: chapter generation failed');
      }

      final tocLesson = _buildTableOfContents(
        chapters: chapters,
        subjectId: subjectId,
        topicId: topicId,
        topicTitle: topicTitle,
      );

      for (final chapter in chapters) {
        final createResult = await _lessonRepository.create(chapter);
        if (createResult.isFailure) {
          _logger.w('Failed to save chapter lesson: ${createResult.error}');
        }
      }

      final tocResult = await _lessonRepository.create(tocLesson);
      if (tocResult.isFailure) {
        _logger.w('Failed to save table of contents: ${tocResult.error}');
      }

      return Result.success([tocLesson, ...chapters]);
    } catch (e) {
      _logger.w('Slide deck generation failed', e);
      return Result.failure('SlideDeckGenerator.generateSlideDeck: $e');
    }
  }

  /// Analyzes the source content to identify chapter/section boundaries.
  Future<List<_ChapterInfo>> _analyzeStructure({
    required String sourceContent,
    required String topicTitle,
    required String localeName,
  }) async {
    final prompt = _buildStructureAnalysisPrompt(sourceContent, topicTitle);

    final result = await _llmService.chat(
      message: prompt,
      modelId: _modelId,
      systemPrompt: _structureAnalysisSystemPrompt(),
      feature: 'slide_deck_structure',
    );

    if (result.isFailure || result.data == null) {
      _logger.w('Structure analysis LLM call failed: ${result.error}');
      return [];
    }

    return _parseStructureResponse(result.data!);
  }

  /// Generates slides for each chapter and returns lesson objects.
  Future<List<Lesson>> _generateChapters({
    required List<_ChapterInfo> chapters,
    required String sourceContent,
    required String subjectId,
    required String topicId,
    required String topicTitle,
    required String localeName,
    required SlideDeckStyle style,
  }) async {
    final lessons = <Lesson>[];

    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final chapterContent = sourceContent.substring(
        chapter.startIndex.clamp(0, sourceContent.length),
        chapter.endIndex.clamp(0, sourceContent.length),
      );

      final blocks = await _generateChapterSlides(
        chapterIndex: i,
        chapter: chapter,
        chapterContent: chapterContent,
        topicTitle: topicTitle,
        localeName: localeName,
        style: style,
      );

      if (blocks.isEmpty) {
        _logger.w('No slides generated for chapter: ${chapter.title}');
        continue;
      }

      final lesson = Lesson(
        id: const Uuid().v4(),
        subjectId: subjectId,
        title: chapter.title,
        topicId: topicId,
        blocks: blocks,
        difficulty: 3,
        generatedBy: GeneratedBy.ai,
        createdAt: DateTime.now(),
      );

      lessons.add(lesson);
    }

    return lessons;
  }

  /// Generates slide blocks for a single chapter.
  Future<List<LessonBlock>> _generateChapterSlides({
    required int chapterIndex,
    required _ChapterInfo chapter,
    required String chapterContent,
    required String topicTitle,
    required String localeName,
    required SlideDeckStyle style,
  }) async {
    final styleLabel = switch (style) {
      SlideDeckStyle.detailed => 'detailed',
      SlideDeckStyle.concise => 'concise',
      SlideDeckStyle.examFocused => 'exam-focused',
    };

    final prompt = _buildChapterSlidePrompt(
      chapterTitle: chapter.title,
      chapterContent: chapterContent,
      sectionTitles: chapter.sections,
      style: styleLabel,
      topicTitle: topicTitle,
    );

    final result = await _llmService.chat(
      message: prompt,
      modelId: _modelId,
      systemPrompt: _chapterSlideSystemPrompt(localeName),
      feature: 'slide_deck_chapter',
    );

    if (result.isFailure || result.data == null) {
      _logger.w('LLM slide generation failed for chapter ${chapter.title}: ${result.error}');
      return _fallbackSlides(chapterIndex, chapter, topicTitle);
    }

    final slides = _parseSlideResponse(
      result.data!,
      chapterIndex: chapterIndex,
      chapterTitle: chapter.title,
    );

    if (slides.isEmpty) {
      return _fallbackSlides(chapterIndex, chapter, topicTitle);
    }

    return slides;
  }

  List<LessonBlock> _parseSlideResponse(
    String llmResponse, {
    required int chapterIndex,
    required String chapterTitle,
  }) {
    try {
      final cleaned = llmResponse
          .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();
      final data = jsonDecode(cleaned);

      List<dynamic> slidesList;
      if (data is List) {
        slidesList = data;
      } else if (data is Map && data.containsKey('slides')) {
        slidesList = data['slides'] as List;
      } else {
        return [];
      }

      final blocks = <LessonBlock>[];
      var order = 0;

      for (final item in slidesList) {
        try {
          final map = item as Map<String, dynamic>;
          final typeStr = map['slideType'] as String? ?? 'concept';
          final slideType = SlideType.values.firstWhere(
            (s) => s.name == typeStr,
            orElse: () => SlideType.concept,
          );

          final blockType = switch (slideType) {
            SlideType.quiz => LessonBlockType.quiz,
            SlideType.summary => LessonBlockType.summary,
            _ => LessonBlockType.slide,
          };

          final block = LessonBlock(
            id: const Uuid().v4(),
            subjectId: '',
            lessonId: '',
            type: blockType,
            content: map['content'] as String? ?? '',
            order: order++,
            answerKey: map['answerKey'] as String? ?? '',
            chapterTitle: chapterTitle,
            sectionTitle: map['sectionTitle'] as String?,
            chapterOrder: chapterIndex,
            sectionOrder: map['sectionOrder'] as int?,
            slideType: slideType,
          );
          blocks.add(block);
        } catch (e) {
          _logger.w('Skipping malformed slide item: $item', e);
        }
      }

      return blocks;
    } catch (e) {
      _logger.w('Failed to parse slide deck response', e);
      return _parseSlidesFromText(llmResponse, chapterIndex, chapterTitle);
    }
  }

  List<LessonBlock> _parseSlidesFromText(
    String text,
    int chapterIndex,
    String chapterTitle,
  ) {
    final blocks = <LessonBlock>[];
    final lines = text.split('\n');
    var order = 0;
    final buffer = StringBuffer();

    String currentSection = '';

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ') || trimmed.startsWith('## ')) {
        if (buffer.isNotEmpty) {
          blocks.add(_createBlock(
            content: buffer.toString().trim(),
            order: order++,
            chapterIndex: chapterIndex,
            chapterTitle: chapterTitle,
            sectionTitle: currentSection,
            slideType: SlideType.concept,
          ));
          buffer.clear();
        }
        currentSection = trimmed.replaceFirst(RegExp(r'^#{1,2}\s*'), '');
        buffer.writeln(line);
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        buffer.writeln(line);
      } else if (trimmed.isNotEmpty) {
        buffer.writeln(line);
      }
    }

    if (buffer.isNotEmpty) {
      blocks.add(_createBlock(
        content: buffer.toString().trim(),
        order: order,
        chapterIndex: chapterIndex,
        chapterTitle: chapterTitle,
        sectionTitle: currentSection,
        slideType: SlideType.concept,
      ));
    }

    return blocks;
  }

  LessonBlock _createBlock({
    required String content,
    required int order,
    required int chapterIndex,
    required String chapterTitle,
    required String sectionTitle,
    required SlideType slideType,
    String answerKey = '',
  }) {
    final blockType = switch (slideType) {
      SlideType.quiz => LessonBlockType.quiz,
      SlideType.summary => LessonBlockType.summary,
      _ => LessonBlockType.slide,
    };

    return LessonBlock(
      id: const Uuid().v4(),
      subjectId: '',
      lessonId: '',
      type: blockType,
      content: content,
      order: order,
      answerKey: answerKey,
      chapterTitle: chapterTitle,
      sectionTitle: sectionTitle,
      chapterOrder: chapterIndex,
      sectionOrder: null,
      slideType: slideType,
    );
  }

  List<LessonBlock> _fallbackSlides(
    int chapterIndex,
    _ChapterInfo chapter,
    String topicTitle,
  ) {
    return [
      _createBlock(
        content: chapter.title,
        order: 0,
        chapterIndex: chapterIndex,
        chapterTitle: chapter.title,
        sectionTitle: '',
        slideType: SlideType.title,
      ),
      _createBlock(
        content: 'Content for ${chapter.title} in $topicTitle',
        order: 1,
        chapterIndex: chapterIndex,
        chapterTitle: chapter.title,
        sectionTitle: '',
        slideType: SlideType.concept,
      ),
    ];
  }

  Lesson _buildTableOfContents({
    required List<Lesson> chapters,
    required String subjectId,
    required String topicId,
    required String topicTitle,
  }) {
    final tocContent = StringBuffer();
    tocContent.writeln('Table of Contents: $topicTitle\n');

    for (var i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      tocContent.writeln('Chapter ${i + 1}: ${chapter.title}');
      for (final block in chapter.blocks) {
        if (block.slideType == SlideType.title ||
            block.slideType == SlideType.concept ||
            block.slideType == SlideType.definition) {
          final sectionLabel = block.sectionTitle ?? '';
          if (sectionLabel.isNotEmpty) {
            tocContent.writeln('  - $sectionLabel');
          }
        }
      }
      tocContent.writeln();
    }

    final tocBlock = LessonBlock(
      id: const Uuid().v4(),
      subjectId: subjectId,
      lessonId: topicId,
      type: LessonBlockType.slide,
      content: tocContent.toString(),
      order: 0,
      chapterTitle: 'Table of Contents',
      chapterOrder: -1,
      slideType: SlideType.tableOfContents,
    );

    return Lesson(
      id: const Uuid().v4(),
      subjectId: subjectId,
      title: 'Table of Contents: $topicTitle',
      topicId: topicId,
      blocks: [tocBlock],
      difficulty: 1,
      generatedBy: GeneratedBy.ai,
      createdAt: DateTime.now(),
    );
  }

  List<_ChapterInfo> _parseStructureResponse(String response) {
    try {
      final cleaned = response
          .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();
      final data = jsonDecode(cleaned);

      if (data is Map && data.containsKey('chapters')) {
        final chaptersList = data['chapters'] as List;
        return chaptersList.map((item) {
          final map = item as Map<String, dynamic>;
          return _ChapterInfo(
            title: map['title'] as String? ?? 'Untitled Chapter',
            sections: (map['sections'] as List?)
                    ?.whereType<String>()
                    .toList() ??
                [],
            startIndex: (map['startIndex'] as num?)?.toInt() ?? 0,
            endIndex: (map['endIndex'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }

      if (data is List) {
        return data.map((item) {
          final map = item as Map<String, dynamic>;
          return _ChapterInfo(
            title: map['title'] as String? ?? 'Untitled Chapter',
            sections: (map['sections'] as List?)
                    ?.whereType<String>()
                    .toList() ??
                [],
            startIndex: (map['startIndex'] as num?)?.toInt() ?? 0,
            endIndex: (map['endIndex'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      }
    } catch (e) {
      _logger.w('Failed to parse structure response', e);
    }
    return [];
  }

  String _buildStructureAnalysisPrompt(String sourceContent, String topicTitle) {
    return 'Analyze the following source material and identify its chapter/section structure.\n\n'
        'Topic: $topicTitle\n\n'
        'Source content (may be truncated):\n${_truncate(sourceContent, 8000)}\n\n'
        'Return a JSON object with a "chapters" array. Each chapter should have:\n'
        '- "title": the chapter/section title\n'
        '- "sections": an array of subsection titles within the chapter\n'
        '- "startIndex": approximate character offset where this chapter starts in the source\n'
        '- "endIndex": approximate character offset where this chapter ends\n\n'
        'If the document has no clear chapter structure, create logical sections based on '
        'topic shifts, headings, or content blocks. Aim for 3-10 chapters.\n\n'
        'Return ONLY the JSON, no explanation.';
  }

  String _structureAnalysisSystemPrompt() {
    return 'You are a document structure analyzer. Identify chapter and section boundaries '
        'in educational content. Return valid JSON only.';
  }

  String _buildChapterSlidePrompt({
    required String chapterTitle,
    required String chapterContent,
    required List<String> sectionTitles,
    required String style,
    required String topicTitle,
  }) {
    final sectionInfo = sectionTitles.isNotEmpty
        ? '\nSections in this chapter: ${sectionTitles.join(', ')}'
        : '';

    return 'Generate a progressive slide deck for this chapter of a textbook.\n\n'
        'Topic: $topicTitle\n'
        'Chapter: $chapterTitle$sectionInfo\n'
        'Style: $style\n\n'
        'Chapter content:\n${_truncate(chapterContent, 6000)}\n\n'
        'Create slides that progressively build understanding:\n'
        '1. Start with a title slide for the chapter\n'
        '2. Concept slides explaining key ideas\n'
        '3. Definition slides for important terms\n'
        '4. Formula slides for equations/formulas (if applicable)\n'
        '5. Example slides with worked problems\n'
        '6. A summary slide reviewing key points\n'
        '7. Quiz slides with 1-2 review questions\n\n'
        'Return a JSON array of slides, each with:\n'
        '- "slideType": one of [title, concept, definition, formula, example, summary, quiz, reference]\n'
        '- "content": the slide content (markdown-style text)\n'
        '- "sectionTitle": which section this slide belongs to (from the section list)\n'
        '- "sectionOrder": numeric order within the chapter\n'
        '- "answerKey": (for quiz slides only) the correct answer\n\n'
        'Return ONLY the JSON array, no explanation.';
  }

  String _chapterSlideSystemPrompt(String localeName) {
    return 'You are an educational content designer. Generate structured slide decks '
        'for textbook chapters in $localeName. Return valid JSON only.';
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}\n...[truncated]';
  }
}

class _ChapterInfo {
  final String title;
  final List<String> sections;
  final int startIndex;
  final int endIndex;

  _ChapterInfo({
    required this.title,
    required this.sections,
    required this.startIndex,
    required this.endIndex,
  });
}
