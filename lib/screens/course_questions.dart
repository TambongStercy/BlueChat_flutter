import 'package:blue_chat_v1/classes/levels.dart';
import 'package:blue_chat_v1/components/course_tile.dart';
import 'package:blue_chat_v1/screens/pdf_reader.dart';
import 'package:flutter/material.dart';

class CourseQuestions extends StatelessWidget {
  const CourseQuestions({
    super.key,
    required this.questions,
    required this.course,
    required this.level,
    required this.semester
  });

  final List<Question> questions;
  final Course course;
  final String semester;
  final String level;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
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
                  children: 
                  questions.map((question) {
                    final title = '${question.name} ${question.type} ${question.year}';
                    
                    return CourseTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfReader(
                              level: level,
                              semester: semester,
                              course: course,
                              question: question,
                            ),
                          ),
                        );
                      },
                      isQuestion: true,
                      title: title,
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
