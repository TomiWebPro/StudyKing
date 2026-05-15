import 'package:studyking/core/data/hive_box_names.dart';
import 'package:studyking/core/data/repository.dart';
import 'package:studyking/core/data/models/student_availability_model.dart';

class StudentAvailabilityRepository extends Repository<StudentAvailabilityModel> {
  Future<void> init() async {
    await openBox(HiveBoxNames.studentAvailability);
  }

  Future<void> saveAvailability(StudentAvailabilityModel model) async {
    await super.save(model.studentId, model);
  }

  Future<StudentAvailabilityModel?> getByStudent(String studentId) async {
    return super.get(studentId);
  }
}
