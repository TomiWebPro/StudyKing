import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/features/planner/data/models/student_availability_model.dart';

class StudentAvailabilityRepository extends Repository<StudentAvailabilityModel> {
  StudentAvailabilityRepository() : super(boxName: HiveBoxNames.studentAvailability);

  Future<Result<void>> init() async {
    return Result.capture(
      () async => openBox(HiveBoxNames.studentAvailability),
      context: 'StudentAvailabilityRepository.init',
    );
  }

  Future<Result<void>> saveAvailability(StudentAvailabilityModel model) async {
    return super.save(model.studentId, model);
  }

  Future<Result<StudentAvailabilityModel?>> getByStudent(String studentId) async {
    return super.get(studentId);
  }
}
