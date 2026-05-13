library;

const int _typeIdTopicModel = 0;
const int _typeIdTopicProgressModel = 1;
const int _typeIdQuestionModel = 2;
const int _typeIdAnswerModel = 3;
const int _typeIdSettingsBox = 4;
const int _typeIdSourceModel = 26;
const int _typeIdLessonBlockModel = 6;
const int _typeIdLessonModel = 7;
const int _typeIdStudySessionModel = 8;
const int _typeIdTaskModel = 9;
const int _typeIdUserProfileModel = 10;
const int _typeIdSubjectModel = 11;
const int _typeIdMarkschemeQuestions = 12;
const int _typeIdMarkSchemeStep = 13;
const int _typeIdQuestionEvaluation = 14;
const int _typeIdEvaluationStep = 15;
const int _typeIdMasteryStateModel = 16;
const int _typeIdTopicDependencyModel = 17;
const int _typeIdQuestionMasteryStateModel = 18;
const int _typeIdPersonalLearningPlan = 19;
const int _typeIdDailyPlan = 20;
const int _typeIdPlannedTopic = 21;
const int _typeIdPlanSummary = 22;
const int _typeIdPlanRecommendation = 23;
const int _typeIdStudentAttempt = 24;
const int _typeIdMarkschemeLegacy = 25;
const int _typeIdConversationMessage = 27;
const int _typeIdTutorSession = 28;
const int _typeIdPlanAdherenceMetric = 30;
const int _typeIdMasteryImprovementMetric = 31;

const List<int> _allTypeIds = [
  _typeIdTopicModel,
  _typeIdTopicProgressModel,
  _typeIdQuestionModel,
  _typeIdAnswerModel,
  _typeIdSettingsBox,
  _typeIdSourceModel,
  _typeIdLessonBlockModel,
  _typeIdLessonModel,
  _typeIdStudySessionModel,
  _typeIdTaskModel,
  _typeIdUserProfileModel,
  _typeIdSubjectModel,
  _typeIdMarkschemeQuestions,
  _typeIdMarkSchemeStep,
  _typeIdQuestionEvaluation,
  _typeIdEvaluationStep,
  _typeIdMasteryStateModel,
  _typeIdTopicDependencyModel,
  _typeIdQuestionMasteryStateModel,
  _typeIdPersonalLearningPlan,
  _typeIdDailyPlan,
  _typeIdPlannedTopic,
  _typeIdPlanSummary,
  _typeIdPlanRecommendation,
  _typeIdStudentAttempt,
  _typeIdMarkschemeLegacy,
  _typeIdConversationMessage,
  _typeIdTutorSession,
  _typeIdPlanAdherenceMetric,
  _typeIdMasteryImprovementMetric,
];

bool _checkUniqueIds() {
  final uniqueIds = _allTypeIds.toSet();
  if (uniqueIds.length != _allTypeIds.length) {
    final duplicates = <int>{};
    for (final id in _allTypeIds) {
      if (_allTypeIds.where((e) => e == id).length > 1) {
        duplicates.add(id);
      }
    }
    throw StateError('Duplicate Hive typeIds detected: $duplicates');
  }
  return true;
}

final bool _typeIdsValid = _checkUniqueIds();

void validateHiveTypeIds() {
  assert(_typeIdsValid, 'Duplicate Hive typeIds detected');
}