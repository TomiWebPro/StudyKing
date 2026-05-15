import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyking/features/planner/data/models/student_availability_model.dart';
import 'package:studyking/features/planner/data/repositories/student_availability_repository.dart';

class MockStudentAvailabilityBox implements Box<StudentAvailabilityModel> {
  final Map<String, StudentAvailabilityModel> _storage = {};
  bool _isOpen = true;

  @override
  Iterable<StudentAvailabilityModel> get values => _storage.values.toList();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  StudentAvailabilityModel? get(dynamic key, {StudentAvailabilityModel? defaultValue}) {
    return _storage[key as String] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, StudentAvailabilityModel value) async {
    _storage[key as String] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _storage.remove(key as String);
  }

  @override
  bool containsKey(dynamic key) {
    return _storage.containsKey(key as String);
  }

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  bool get isOpen => _isOpen;

  @override
  String get name => 'mock-student-availability';

  @override
  Iterable<String> get keys => _storage.keys;

  void addAvailability(StudentAvailabilityModel model) {
    _storage[model.studentId] = model;
  }

  void clearStorage() {
    _storage.clear();
  }
}

class TestableStudentAvailabilityRepository extends StudentAvailabilityRepository {
  void attachMockBox(Box<StudentAvailabilityModel> box) {
    attachBox(box);
  }
}

StudentAvailabilityModel createAvailability({
  String studentId = 'student-1',
  List<int> preferredStudyDays = const [1, 2, 3, 4, 5],
  int preferredStartHour = 9,
  int preferredEndHour = 17,
  int maxSessionsPerDay = 3,
  int defaultSessionDurationMinutes = 30,
  List<DateTime> blackoutDates = const [],
}) {
  return StudentAvailabilityModel(
    studentId: studentId,
    preferredStudyDays: preferredStudyDays,
    preferredStartHour: preferredStartHour,
    preferredEndHour: preferredEndHour,
    maxSessionsPerDay: maxSessionsPerDay,
    defaultSessionDurationMinutes: defaultSessionDurationMinutes,
    blackoutDates: blackoutDates,
  );
}

void main() {
  group('StudentAvailabilityRepository', () {
    late TestableStudentAvailabilityRepository repository;
    late MockStudentAvailabilityBox mockBox;

    setUp(() {
      mockBox = MockStudentAvailabilityBox();
      repository = TestableStudentAvailabilityRepository();
      repository.attachMockBox(mockBox);
    });

    group('saveAvailability', () {
      test('stores an availability model by studentId', () async {
        final model = createAvailability(studentId: 'student-1');
        await repository.saveAvailability(model);
        final stored = await repository.getByStudent('student-1');
        expect(stored, isNotNull);
        expect(stored!.studentId, 'student-1');
      });

      test('overwrites existing availability for same student', () async {
        final model1 = createAvailability(
          studentId: 'student-1',
          preferredStudyDays: [1, 2, 3],
        );
        final model2 = createAvailability(
          studentId: 'student-1',
          preferredStudyDays: [4, 5, 6],
        );
        await repository.saveAvailability(model1);
        await repository.saveAvailability(model2);
        final stored = await repository.getByStudent('student-1');
        expect(stored!.preferredStudyDays, [4, 5, 6]);
      });
    });

    group('getByStudent', () {
      test('returns null for non-existent student', () async {
        final result = await repository.getByStudent('non-existent');
        expect(result, isNull);
      });

      test('returns stored availability for existing student', () async {
        final model = createAvailability(studentId: 'student-1');
        mockBox.addAvailability(model);
        final stored = await repository.getByStudent('student-1');
        expect(stored, isNotNull);
        expect(stored!.preferredStartHour, 9);
        expect(stored.preferredEndHour, 17);
      });

      test('stores and retrieves all fields', () async {
        final blackout = DateTime(2026, 6, 1);
        final model = createAvailability(
          studentId: 'student-1',
          preferredStudyDays: [1, 3, 5],
          preferredStartHour: 8,
          preferredEndHour: 22,
          maxSessionsPerDay: 2,
          defaultSessionDurationMinutes: 45,
          blackoutDates: [blackout],
        );
        await repository.saveAvailability(model);
        final stored = await repository.getByStudent('student-1');
        expect(stored!.preferredStudyDays, [1, 3, 5]);
        expect(stored.preferredStartHour, 8);
        expect(stored.preferredEndHour, 22);
        expect(stored.maxSessionsPerDay, 2);
        expect(stored.defaultSessionDurationMinutes, 45);
        expect(stored.blackoutDates, [blackout]);
      });
    });

    group('edge cases', () {
      test('returns null after delete', () async {
        final model = createAvailability(studentId: 'student-1');
        await repository.saveAvailability(model);
        mockBox.clearStorage();
        final stored = await repository.getByStudent('student-1');
        expect(stored, isNull);
      });

      test('handles multiple students independently', () async {
        await repository.saveAvailability(createAvailability(studentId: 's1', preferredStartHour: 8));
        await repository.saveAvailability(createAvailability(studentId: 's2', preferredStartHour: 10));
        final s1 = await repository.getByStudent('s1');
        final s2 = await repository.getByStudent('s2');
        expect(s1!.preferredStartHour, 8);
        expect(s2!.preferredStartHour, 10);
      });
    });
  });
}
