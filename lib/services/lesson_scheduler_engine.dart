// COMPLETE LESSON SCHEDULING ENGINE
// Lesson connects Subjects & Materials & Pages to Questions
// Supports multiple question types (MCQ, Input, Graph)
// Auto-schedules via LLM engine

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:graphing/graphing.dart';

/// Generate graph path from existing story
String generateGraphPathFromStory({
  required String story,
  required String theme,
  int width = 1600,
  int height = 1200,
}) {
  return Graphing({
    'theme': theme,
    'width': width,
    'height': height,
    'requestTheme_preset': theme,
    'primaryColor': theme,
    'draft': true,
    'target': 'yz',
    'axis_size': 100,
    'axes': true,
    'show_background_grid': true,
    'title': 'Graph from story',
    'credit': true,
    'sectionId': 'story',
    'text': story,
    'title_background_color': theme,
  }, {
    'text_size': 'middle_top',
    'title_align': 'middle',
    'text_align': 'justify',
    'background_color': theme,
    'showLegend': true,
    'show_titles': true,
  }).path;
}

/// Scheduler commands and templates
class LessonSchedulerCommands {
  static const _templates = {
    'mcq_quiz': '''
You are an LLM-powered quiz generator. Create multiple choice questions (mcq_quiz) from this study material:
"$story_content"

Generate 5 questions with these options:
- [A] Correct answer
- [B] Wrong answer
- [C] Wrong answer
- [D] Wrong answer

Return JSON format:
{
  "topic": "topic_name",
  "questions": [
    {"question": "q1", "options": ["a", "b", "c", "d"], "answer": "a"},
    {"question": "q2"...},
    ...
  ]
}
''',
    'input_quiz': '''
You are an LLM-powered quiz generator. Create input-type questions from this study material:
"$story_content"

First question on topic "$topic" followed by few-shot:
1. "What is the meaning of word?"
2. "Identify verb in sentence"

Questions about "$topic" based on context "$story_lesson"</code>
''',
    'graph_quiz': '''
You are graph analysis generator. Create graph-based questions with code for "$topic" ($story_page) using $energy_plot or $flow_plot or $line_plot or $scatter_plot.''';
    'sectionQuiz': '''You are LLM-powered quiz generator
<prompt_lesson="story_lesson" topic="topic_name">
<question source="story_material">mcq_quiz</code>
<prompt_quiz type="quantitative" injection_placement="graph_area">3</prompt_quiz>
</prompt_lesson>'''
  };
  static const _templates = {
    'mcq_quiz': '''
You are an LLM-powered quiz generator. Create multiple choice questions (mcq_quiz) from this study material:
"$story"

Generate 5 mcq questions with these options:
[A] Correct answer
[B] Wrong answer  
[C] Wrong answer
[D] Wrong answer

Return JSON format:
{
  "topic": "topic_name",
  "questions": [
    {"question": "q1", "options": ["a", "b", "c", "d"], "answer": "a"},
    {"question": "q2"...}
  ]
}
''',
    'input_quiz': '''
You are an input-type question generator. Create questions from "$story":
1. "What is the meaning of word?"
2. "Identify verb in sentence"
3. "Generate about $topic"
''',
    'graph_quiz': '''
You are graph analysis generator. Create graph-based questions with code for "$topic" using $graph_type.'''
  };
}

/// Graph rendering service
class GraphRenderingService {
  final Dio _dio = Dio();
  final String Function(
  String method,
  String endpoint,
  String graphType,
  String energyPlot,
  String flowPlot,
  String linePlot,
  String scatterPlot,
  int[,] matrix,
  int width,
  int height,
  String source,
  String title,
  [List<StylingElement>? styling]) _graphFunc;

  Future<GraphPath> generateGraphFromStory({
    required String story,
    required String theme,
    String graphType = 'linePlot',
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/graph/render',
        data: {
          'story': story,
          'theme': theme,
          'graphType': graphType,
          'energyPlot': energyPlot,
          'flowPlot': flowPlot,
          'linePlot': linePlot,
          'scatterPlot': scatterPlot,
          'matrix': matrix,
          'width': width,
          'height': height,
          'source': source,
          'title': title,
        },
      );
      return GraphPath(
        path: response.data['path'],
        rendering: GraphRendering(
          theme: theme,
          bounds: Box(width, height),
        ),
      );
    } catch (e) {
      throw GraphError('Graph generation failed: $e');
    }
  }

  List<GraphData> _getGraphData() {
    return [
      GraphData(
        type: 'linePlot',
        chart: MatrixChart(
          matrix: matrix,
          color: MatrixColor(0xFF0000FF),
          title: 'Line Plot',
        ),
      ),
      GraphData(
        type: 'scatterPlot',
        chart: ScatterChart(
          x: [x, y],
          y: [y, x],
          title: 'Scatter Plot',
        ),
      ),
    ];
  }
}
