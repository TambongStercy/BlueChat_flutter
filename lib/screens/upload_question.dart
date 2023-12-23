import 'package:blue_chat_v1/api_call.dart';
import 'package:blue_chat_v1/classes/level_hive_box.dart';
import 'package:blue_chat_v1/classes/levels.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UploadQuestion extends StatefulWidget {
  const UploadQuestion({super.key});

  @override
  State<UploadQuestion> createState() => _UploadQuestionState();
}

class _UploadQuestionState extends State<UploadQuestion> {
  List<String> levels = ['200', '300', '400', '500'];
  String? level = '200';

  List<String> semesters = ['first', 'second'];
  String? semester = 'first';

  Course? course;

  final List<String> years = List.generate(
      DateTime.now().year - 1999,
      (index) => (2000 + index)
          .toString()); // Generate years from 2000 to current year

  String? selectedYear =
      DateTime.now().year.toString(); // Default selected year

  String name = '';

  List<String> types = ['CA', 'EXAM', 'TUTO'];
  String? type = 'CA';

  PlatformFile? file;

  String? title;

  bool init = true;

  @override
  Widget build(BuildContext context) {
    final levelBox = Provider.of<LevelHiveBox>(context, listen: false);

    final realCourses = semester == 'first'
        ? levelBox.firstSemester(level!)
        : levelBox.secondSemester(level!);

    if (realCourses!.isNotEmpty && !realCourses.contains(course)) {
      course = realCourses.first;
    } else if (realCourses.isEmpty) {
      course = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Question'),
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //Levels and semesters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                //Levels
                Row(
                  children: [
                    const Text(
                      'Level: ',
                      style: TextStyle(fontSize: 17.0),
                    ),
                    DropdownButton<String>(
                      items: levels.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (item) => setState(() => level = item),
                      value: level,
                    ),
                  ],
                ),
                //Semesters
                Row(
                  children: [
                    const Text(
                      'Semester: ',
                      style: TextStyle(fontSize: 17.0),
                    ),
                    DropdownButton<String>(
                      items: semesters.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item == 'first' ? '1st' : '2nd',
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (item) => setState(() => semester = item),
                      value: semester,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),

            ///Years
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Year: ',
                  style: TextStyle(fontSize: 17.0),
                ),
                DropdownButton<String>(
                  items: years.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (item) => setState(() => selectedYear = item),
                  value: selectedYear,
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            ///Courses and Question type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ///Courses
                Row(
                  children: [
                    const Text(
                      'Courses: ',
                      style: TextStyle(fontSize: 17.0),
                    ),
                    DropdownButton<Course>(
                      items: realCourses.map((item) {
                        return DropdownMenuItem<Course>(
                          value: item,
                          child: Text(
                            item.courseCode,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (item) {
                        setState(() {
                          course = item;
                          // title = realCourses.firstWhere((course) => course.courseCode == code).title;
                        });
                      },
                      value: course,
                    ),
                  ],
                ),

                ///TYPES
                Row(
                  children: [
                    const Text(
                      'Question Type: ',
                      style: TextStyle(fontSize: 17.0),
                    ),
                    DropdownButton<String>(
                      items: types.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (item) => setState(() => type = item),
                      value: type,
                    ),
                  ],
                ),
              ],
            ),

            if (course != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: Column(
                  children: [
                    const Text(
                      'Course Name:',
                      style: TextStyle(fontSize: 17.0),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      course!.title,
                      style: TextStyle(fontSize: 15.0),
                    ),
                  ],
                ),
              ),

            const SizedBox(
              height: 10,
            ),

            ///Question title
            TextField(
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.blueAccent,
                hintText: 'Question Title',
                border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(50)),
              ),
              onChanged: (newValue) {
                setState(() => name = newValue);
              },
            ),
            const SizedBox(
              height: 10,
            ),

            ///PDF selection
            ElevatedButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  setState(() => file = result.files.single);
                }
              },
              child: const Text('Select File'),
            ),

            const SizedBox(
              height: 10,
            ),

            if (file != null)
              ElevatedButton(
                onPressed: () async {
                  if (level == null ||
                      semester == null ||
                      course == null ||
                      selectedYear == null ||
                      name == '' ||
                      type == null ||
                      file == null) {
                    print('something is empty');
                    return;
                  }

                  final question = Question(
                    name: name,
                    path: file!.path!,
                    year: selectedYear!,
                    type: type!,
                  );

                  await uploadQuestion(
                    context: context,
                    level: level!,
                    semester: semester!,
                    question: question,
                    course: course!,
                  );
                },
                child: Text('Upload Question'),
              ),
          ],
        ),
      ),
    );
  }
}
