import 'package:blue_chat_v1/constants.dart';
import 'package:hive/hive.dart';
part 'levels.g.dart';

@HiveType(typeId: 4)
class Level extends HiveObject {
  @HiveField(0)
  String value;

  @HiveField(1)
  List<Course> semester1;

  @HiveField(2)
  List<Course> semester2;

  Level({
    required this.value,
    required this.semester1,
    required this.semester2,
  });

  List<Course> getCourses(semester) {
    return semester == 'first' ? semester1 : semester2;
  }

  bool hasThisCourse(Course course, String semesterValue) {
    final courses = getCourses(semesterValue);
    return courses
            .indexWhere((sCourse) => sCourse.courseCode == course.courseCode) >
        -1;
  }

  Future<void> updateCourse(Course course, String semesterValue) async {
    try {
      final courses = getCourses(semesterValue);

      for (int i = 0; i < courses.length; i++) {
        var sCourse = courses[i];
        if (sCourse.courseCode == course.courseCode) {
          courses[i] = course;
          await save();
          break;
        }
      }
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<void> addCourse(Course course, String semesterValue) async {
    try {
      final courses = getCourses(semesterValue);

      courses.add(course);

      await save();
    } on Exception catch (e) {
      print(e);
    }
  }
}

@HiveType(typeId: 5)
class Course extends HiveObject {
  @HiveField(0)
  List<String> departments;

  @HiveField(1)
  String title;

  @HiveField(2)
  String courseCode;

  @HiveField(3)
  List<Question> questions;

  Course({
    required this.departments,
    required this.title,
    required this.courseCode,
    required this.questions,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      departments: (json['departments'] as List).cast<String>(),
      title: json['title'],
      courseCode: json['courseCode'],
      questions: (json['questions'] as List)
          .map((questionJson) => Question.fromJson(questionJson))
          .toList(),
    );
  }
}

@HiveType(typeId: 6)
class Question extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String path;

  @HiveField(2)
  String year;

  @HiveField(3)
  String type;

  Question({
    required this.name,
    required this.path,
    required this.year,
    required this.type,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      name: json['name'],
      path: getMobilePath(json['path']),
      year: json['year'],
      type: json['type'],
    );
  }
}
