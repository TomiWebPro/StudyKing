import 'package:hive_flutter/hive_flutter.dart';
import '../models/plan_adherence_model.dart';

class PlanAdherenceRepository {
  Box<PlanAdherenceModel>? _box;

  Future<void> init() async {
    if (_box != null) return;
    try {
      _box = await Hive.openBox<PlanAdherenceModel>('plan_adherence');
    } catch (_) {
      _box = null;
    }
  }

  bool get _isReady => _box != null;

  Future<void> save(PlanAdherenceModel model) async {
    await _box?.put(model.id, model);
  }

  Future<PlanAdherenceModel?> get(String id) async {
    return _box?.get(id);
  }

  Future<List<PlanAdherenceModel>> getByStudent(String studentId) async {
    if (!_isReady) return [];
    final results = _box!.values
        .where((m) => m.studentId == studentId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  Future<List<PlanAdherenceModel>> getByDateRange(
      String studentId, DateTime start, DateTime end) async {
    if (!_isReady) return [];
    return _box!.values
        .where((m) =>
            m.studentId == studentId &&
            m.date.isAfter(start) &&
            m.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<List<PlanAdherenceModel>> getWeekly(String studentId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
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
    if (!_isReady) return null;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final todayMetrics = _box!.values.where((m) =>
        m.studentId == studentId &&
        m.date.isAfter(startOfDay) &&
        m.date.isBefore(endOfDay));
    return todayMetrics.isNotEmpty ? todayMetrics.first : null;
  }

  Future<void> delete(String id) async {
    await _box?.delete(id);
  }

  Future<void> deleteByStudent(String studentId) async {
    if (!_isReady) return;
    final metrics = _box!.values
        .where((m) => m.studentId == studentId)
        .toList();
    for (final m in metrics) {
      await _box!.delete(m.id);
    }
  }
}
