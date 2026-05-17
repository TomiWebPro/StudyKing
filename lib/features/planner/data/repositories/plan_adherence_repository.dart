import 'package:studyking/core/constants/app_constants.dart';
import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/utils/time_utils.dart';
import 'package:studyking/features/planner/data/models/plan_adherence_model.dart';

class PlanAdherenceRepository extends Repository<PlanAdherenceModel> {
  Future<void> init() async {
    await openBox(HiveBoxNames.planAdherence);
  }

  Future<void> create(PlanAdherenceModel model) async {
    await super.save(model.id, model);
  }

  Future<List<PlanAdherenceModel>> getByStudent(String studentId) async {
    final results = filterBy((m) => m.studentId, studentId)
      ..sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  Future<List<PlanAdherenceModel>> getByDateRange(
      String studentId, DateTime start, DateTime end) async {
    final byStudent = filterBy((m) => m.studentId, studentId);
    return byStudent
        .where((m) => m.date.isAfter(start) && m.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<List<PlanAdherenceModel>> getWeekly(String studentId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(Timeouts.week);
    return getByDateRange(studentId, weekAgo, now);
  }

  Future<double> getAverageAdherence(String studentId) async {
    final metrics = await getByStudent(studentId);
    if (metrics.isEmpty) return 0.0;
    return metrics.fold<double>(0.0, (sum, m) => sum + m.adherenceScore) /
        metrics.length;
  }

  Future<int> getConsecutiveLowAdherenceDays(String studentId,
      {double threshold = 0.5}) async {
    final metrics = await getByStudent(studentId);
    int consecutive = 0;
    for (final metric in metrics) {
      if (metric.adherenceScore < threshold) {
        consecutive++;
      } else {
        break;
      }
    }
    return consecutive;
  }

  Future<PlanAdherenceModel?> getToday(String studentId) async {
    final today = DateTime.now();
    final startOfDay = today.dateOnly;
    final endOfDay = startOfDay.add(Timeouts.day);
    final todayMetrics = filterBy((m) => m.studentId, studentId)
        .where((m) => m.date.isAfter(startOfDay) && m.date.isBefore(endOfDay));
    return todayMetrics.isNotEmpty ? todayMetrics.first : null;
  }

  Future<void> deleteByStudent(String studentId) async {
    final metrics = filterBy((m) => m.studentId, studentId);
    for (final m in metrics) {
      await super.delete(m.id);
    }
  }
}
