import 'package:studyking/core/data/models/mastery_state_model.dart';
import 'package:studyking/core/data/repositories/topic_repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/services/llm_agent/agent_tool.dart';
import 'package:studyking/core/services/mastery_graph_service.dart';
import 'package:studyking/core/services/student_id_service.dart';
import 'package:studyking/features/practice/data/repositories/topic_dependency_repository.dart';
import 'package:studyking/features/subjects/data/models/topic_dependency_model.dart';
import 'package:studyking/features/subjects/data/repositories/subject_repository.dart';

class GetSyllabusStructureTool extends AgentTool {
  final SubjectRepository _subjectRepo;
  final TopicRepository _topicRepo;
  final MasteryGraphService _masteryService;
  final TopicDependencyRepository _dependencyRepo;
  final StudentIdService _studentIdService;

  GetSyllabusStructureTool({
    required SubjectRepository subjectRepo,
    required TopicRepository topicRepo,
    required MasteryGraphService masteryService,
    required TopicDependencyRepository dependencyRepo,
    required StudentIdService studentIdService,
  })  : _subjectRepo = subjectRepo,
        _topicRepo = topicRepo,
        _masteryService = masteryService,
        _dependencyRepo = dependencyRepo,
        _studentIdService = studentIdService;

  @override
  String get name => 'get_syllabus_structure';

  @override
  String get description =>
      'Explore subject structure, topic trees, prerequisites, and progress. '
      'List all subjects, view a subject\'s topic hierarchy, or drill into '
      'a specific topic\'s prerequisites and downstream dependencies.';

  @override
  Map<String, dynamic> get parameters => {
        'type': 'object',
        'properties': {
          'subjectId': {
            'type': 'string',
            'description': 'Subject ID to explore. Omit to list all subjects.',
          },
          'topicId': {
            'type': 'string',
            'description':
                'Specific topic ID to get details for. Requires subjectId.',
          },
          'includePrerequisites': {
            'type': 'boolean',
            'default': true,
            'description': 'Whether to include prerequisite and downstream info.',
          },
          'includeProgress': {
            'type': 'boolean',
            'default': true,
            'description': 'Whether to include mastery and progress data.',
          },
        },
        'required': [],
      };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final subjectId = args['subjectId'] as String?;
    final topicId = args['topicId'] as String?;
    final includePrerequisites = args['includePrerequisites'] as bool? ?? true;
    final includeProgress = args['includeProgress'] as bool? ?? true;
    final studentId = _studentIdService.getStudentId();

    if (subjectId == null) {
      return _listAllSubjects(
        studentId: studentId,
        includeProgress: includeProgress,
      );
    }

    if (topicId != null) {
      return _getTopicDetails(
        subjectId: subjectId,
        topicId: topicId,
        studentId: studentId,
        includePrerequisites: includePrerequisites,
        includeProgress: includeProgress,
      );
    }

    return _getSubjectTopicTree(
      subjectId: subjectId,
      studentId: studentId,
      includePrerequisites: includePrerequisites,
      includeProgress: includeProgress,
    );
  }

  Future<Map<String, dynamic>> _listAllSubjects({
    required String studentId,
    required bool includeProgress,
  }) async {
    final subjectsResult = await _subjectRepo.getAll();
    final subjects = subjectsResult.data ?? [];

    final subjectEntries = <Map<String, dynamic>>[];
    for (final subject in subjects) {
      final entry = <String, dynamic>{
        'id': subject.id,
        'name': subject.name,
        'topicCount': subject.topicIds.length,
      };

      if (includeProgress && subject.topicIds.isNotEmpty) {
        final masteryResult =
            await _masteryService.getAllTopicMastery(studentId);
        final allMastery = masteryResult.data ?? [];
        final subjectMastery = allMastery
            .where((m) => subject.topicIds.contains(m.topicId))
            .toList();
        final completedCount =
            subjectMastery.where((m) => m.readinessScore >= 0.8).length;
        entry['completedTopics'] = completedCount;
        entry['overallProgress'] = subject.topicIds.isNotEmpty
            ? completedCount / subject.topicIds.length
            : 0.0;
      }

      subjectEntries.add(entry);
    }

    return {
      'subjectCount': subjectEntries.length,
      'subjects': subjectEntries,
    };
  }

  Future<Map<String, dynamic>> _getSubjectTopicTree({
    required String subjectId,
    required String studentId,
    required bool includePrerequisites,
    required bool includeProgress,
  }) async {
    final subjectResult = await _subjectRepo.get(subjectId);
    final subject = subjectResult.data;
    if (subject == null) {
      return {'error': 'Subject not found: $subjectId'};
    }

    final topicsResult = await _topicRepo.getBySubject(subjectId);
    final topics = topicsResult.data ?? [];

    Result<List<MasteryState>>? masteryResult;
    Map<String, MasteryState> masteryMap = {};
    if (includeProgress) {
      masteryResult = await _masteryService.getAllTopicMastery(studentId);
      final allMastery = masteryResult.data ?? [];
      masteryMap = {
        for (final m in allMastery) m.topicId: m,
      };
    }

    final dependencyMap = <String, TopicDependency>{};
    if (includePrerequisites) {
      final allDepsResult = await _dependencyRepo.getAllDependencies();
      final allDeps = allDepsResult.data ?? [];
      for (final dep in allDeps) {
        if (topics.any((t) => t.id == dep.topicId)) {
          dependencyMap[dep.topicId] = dep;
        }
      }
    }

    final topicEntries = <Map<String, dynamic>>[];
    for (final topic in topics) {
      final entry = _buildTopicEntry(
        topic: topic,
        dependency: dependencyMap[topic.id],
        mastery: masteryMap[topic.id],
        includePrerequisites: includePrerequisites,
        includeProgress: includeProgress,
        completedTopicIds: masteryMap.entries
            .where((e) => e.value.readinessScore >= 0.8)
            .map((e) => e.key)
            .toList(),
      );
      topicEntries.add(entry);
    }

    final completedCount = topicEntries
        .where((t) =>
            (t['mastery'] ?? 'novice') == 'proficient' ||
            (t['mastery'] ?? 'novice') == 'expert')
        .length;

    final suggestedNext = _suggestNextTopic(
      topicEntries: topicEntries,
      dependencyMap: dependencyMap,
      masteryMap: masteryMap,
    );

    return {
      'subjectId': subject.id,
      'subjectName': subject.name,
      'topicCount': topics.length,
      'completedTopics': completedCount,
      'overallProgress':
          topics.isNotEmpty ? completedCount / topics.length : 0.0,
      'topics': topicEntries,
      if (suggestedNext != null) 'suggestedNextTopic': suggestedNext['topicId'],
      if (suggestedNext != null) 'explanation': suggestedNext['explanation'],
    };
  }

  Future<Map<String, dynamic>> _getTopicDetails({
    required String subjectId,
    required String topicId,
    required String studentId,
    required bool includePrerequisites,
    required bool includeProgress,
  }) async {
    final topicsResult = await _topicRepo.getBySubject(subjectId);
    final topics = topicsResult.data ?? [];
    final topic = topics.where((t) => t.id == topicId).firstOrNull;
    if (topic == null) {
      return {'error': 'Topic not found: $topicId in subject $subjectId'};
    }

    Result<MasteryState>? masteryResult;
    if (includeProgress) {
      masteryResult = await _masteryService.getTopicMastery(studentId, topicId);
    }

    TopicDependency? dependency;
    if (includePrerequisites) {
      final depResult =
          await _dependencyRepo.getTopicDependency(topicId);
      dependency = depResult.data;
    }

    final completedTopicIds = <String>[];
    if (includeProgress) {
      final allMasteryResult =
          await _masteryService.getAllTopicMastery(studentId);
      final allMastery = allMasteryResult.data ?? [];
      completedTopicIds.addAll(
        allMastery
            .where((m) => m.readinessScore >= 0.8)
            .map((m) => m.topicId),
      );
    }

    final entry = _buildTopicEntry(
      topic: topic,
      dependency: dependency,
      mastery: masteryResult?.data,
      includePrerequisites: includePrerequisites,
      includeProgress: includeProgress,
      completedTopicIds: completedTopicIds,
    );

    entry['subjectId'] = subjectId;
    return entry;
  }

  Map<String, dynamic> _buildTopicEntry({
    required dynamic topic,
    TopicDependency? dependency,
    MasteryState? mastery,
    required bool includePrerequisites,
    required bool includeProgress,
    required List<String> completedTopicIds,
  }) {
    final entry = <String, dynamic>{
      'id': topic.id,
      'name': topic.title,
      'description': topic.description,
    };

    if (includePrerequisites && dependency != null) {
      entry['prerequisites'] = dependency.prerequisites;
      entry['downstreamTopics'] = dependency.downstreamTopics;
      entry['estimatedMinutes'] = dependency.estimatedMinutes;
      final isReady = dependency.isReady(completedTopicIds, null);
      entry['isReady'] = isReady;
      if (!isReady && dependency.prerequisites.isNotEmpty) {
        entry['blockedBy'] = dependency.prerequisites
            .where((p) => !completedTopicIds.contains(p))
            .toList();
      }
    }

    if (includeProgress && mastery != null) {
      entry['mastery'] = mastery.masteryLevel.name;
      entry['accuracy'] = mastery.accuracy;
      entry['readinessScore'] = mastery.readinessScore;
      entry['totalAttempts'] = mastery.totalAttempts;
    }

    return entry;
  }

  Map<String, String>? _suggestNextTopic({
    required List<Map<String, dynamic>> topicEntries,
    required Map<String, TopicDependency> dependencyMap,
    required Map<String, MasteryState> masteryMap,
  }) {
    final hasAnyPrerequisites =
        dependencyMap.values.any((d) => d.prerequisites.isNotEmpty);

    for (final entry in topicEntries) {
      final topicId = entry['id'] as String;
      final mastery = masteryMap[topicId];
      final isMastered = mastery != null && mastery.readinessScore >= 0.8;

      if (isMastered) {
        continue;
      }

      if (hasAnyPrerequisites) {
        if (entry['isReady'] == true) {
          final explanation =
              'Ready to study — all prerequisites for $topicId are complete.';
          return {'topicId': topicId, 'explanation': explanation};
        }
      } else {
        final explanation = 'Suggested next topic in the syllabus.';
        return {'topicId': topicId, 'explanation': explanation};
      }
    }
    return null;
  }
}
