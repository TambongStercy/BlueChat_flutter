import 'package:blue_chat_v1/classes/levels.dart';
import 'package:blue_chat_v1/components/course_tile.dart';
import 'package:blue_chat_v1/screens/course_questions.dart';
import 'package:flutter/material.dart';

class CourseSelectionScreen extends StatelessWidget {
  const CourseSelectionScreen({
    super.key,
    required this.courses,
    required this.level,
    required this.semester,
  });

  final List<Course> courses;
  final String level;
  final String semester;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Level $level Courses'),
      ),
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    topRight: Radius.circular(15.0),
                  ),
                ),
                margin: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 30.0,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: courses.map((course) {
                    return CourseTile(
                      onTap: () {
                        print(course.questions.length);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseQuestions(
                              questions: course.questions,
                              course: course,
                              level: level,
                              semester: semester,
                            ),
                          ),
                        );
                      },
                      isQuestion: false,
                      title: course.title,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
