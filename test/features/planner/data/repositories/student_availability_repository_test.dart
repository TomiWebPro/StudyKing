import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyking/features/planner/data/models/student_availability_model.dart';
import 'package:studyking/features/planner/data/repositories/student_availability_repository.dart';

class FakeStudentAvailabilityBox implements Box<StudentAvailabilityModel> {
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
    late FakeStudentAvailabilityBox mockBox;

    setUp(() {
      mockBox = FakeStudentAvailabilityBox();
      repository = TestableStudentAvailabilityRepository();
      repository.attachMockBox(mockBox);
    });

    group('saveAvailability', () {
      test('stores an availability model by studentId', () async {
        final model = createAvailability(studentId: 'student-1');
        await repository.saveAvailability(model);
        final result = await repository.getByStudent('student-1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.studentId, 'student-1');
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
        final result = await repository.getByStudent('student-1');
        expect(result.data!.preferredStudyDays, [4, 5, 6]);
      });
    });

    group('getByStudent', () {
      test('returns null data for non-existent student', () async {
        final result = await repository.getByStudent('non-existent');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('returns stored availability for existing student', () async {
        final model = createAvailability(studentId: 'student-1');
        mockBox.addAvailability(model);
        final result = await repository.getByStudent('student-1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.preferredStartHour, 9);
        expect(result.data!.preferredEndHour, 17);
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
        final result = await repository.getByStudent('student-1');
        expect(result.data!.preferredStudyDays, [1, 3, 5]);
        expect(result.data!.preferredStartHour, 8);
        expect(result.data!.preferredEndHour, 22);
        expect(result.data!.maxSessionsPerDay, 2);
        expect(result.data!.defaultSessionDurationMinutes, 45);
        expect(result.data!.blackoutDates, [blackout]);
      });
    });

    group('edge cases', () {
      test('returns null data after delete', () async {
        final model = createAvailability(studentId: 'student-1');
        await repository.saveAvailability(model);
        mockBox.clearStorage();
        final result = await repository.getByStudent('student-1');
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('handles multiple students independently', () async {
        await repository.saveAvailability(createAvailability(studentId: 's1', preferredStartHour: 8));
        await repository.saveAvailability(createAvailability(studentId: 's2', preferredStartHour: 10));
        final s1 = await repository.getByStudent('s1');
        final s2 = await repository.getByStudent('s2');
        expect(s1.data!.preferredStartHour, 8);
        expect(s2.data!.preferredStartHour, 10);
      });
    });
  });

  group('error handling', () {
    test('saveAvailability returns failure when box throws', () async {
      final repo = StudentAvailabilityRepository();
      repo.attachBox(_ThrowingAvailabilityBox());
      final model = createAvailability();
      final result = await repo.saveAvailability(model);
      expect(result.isFailure, isTrue);
    });

    test('getByStudent returns failure when box throws', () async {
      final repo = StudentAvailabilityRepository();
      repo.attachBox(_ThrowingAvailabilityBox());
      final result = await repo.getByStudent('test');
      expect(result.isFailure, isTrue);
    });
  });

  group('StudentAvailabilityRepository (init with real Hive)', () {
    late StudentAvailabilityRepository repository;
    late String hivePath;

    setUpAll(() {
      Hive.registerAdapter(_TestStudentAvailabilityAdapter());
    });

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('sa_repo_test_');
      hivePath = dir.path;
      Hive.init(hivePath);
      repository = StudentAvailabilityRepository();
      await repository.init();
    });

    tearDown(() async {
      await repository.box.close();
      await Hive.deleteBoxFromDisk('student_availability');
    });

    test('init opens box and supports CRUD', () async {
      final model = createAvailability(studentId: 'hive-1');
      await repository.saveAvailability(model);
      final result = await repository.getByStudent('hive-1');
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.studentId, 'hive-1');
      expect(result.data!.preferredStartHour, 9);
    });

    test('overwrites existing availability', () async {
      await repository.saveAvailability(createAvailability(studentId: 's1', preferredStartHour: 8));
      await repository.saveAvailability(createAvailability(studentId: 's1', preferredStartHour: 10));
      final result = await repository.getByStudent('s1');
      expect(result.data!.preferredStartHour, 10);
    });
  });
}

class _ThrowingAvailabilityBox implements Box<StudentAvailabilityModel> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw Exception('Simulated Hive error');
  }
}

class _TestStudentAvailabilityAdapter extends TypeAdapter<StudentAvailabilityModel> {
  @override
  final int typeId = 35;

  @override
  StudentAvailabilityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentAvailabilityModel(
      studentId: fields[0] as String,
      preferredStudyDays: (fields[1] as List?)?.cast<int>() ?? [1, 2, 3, 4, 5, 6, 7],
      preferredStartHour: fields[2] as int? ?? 9,
      preferredEndHour: fields[3] as int? ?? 21,
      maxSessionsPerDay: fields[4] as int? ?? 3,
      defaultSessionDurationMinutes: fields[5] as int? ?? 30,
      blackoutDates: (fields[6] as List?)?.cast<DateTime>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, StudentAvailabilityModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.studentId)
      ..writeByte(1)
      ..write(obj.preferredStudyDays)
      ..writeByte(2)
      ..write(obj.preferredStartHour)
      ..writeByte(3)
      ..write(obj.preferredEndHour)
      ..writeByte(4)
      ..write(obj.maxSessionsPerDay)
      ..writeByte(5)
      ..write(obj.defaultSessionDurationMinutes)
      ..writeByte(6)
      ..write(obj.blackoutDates);
  }
}
