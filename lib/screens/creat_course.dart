import 'package:blue_chat_v1/api_call.dart';
import 'package:flutter/material.dart';

class CreateCourse extends StatefulWidget {
  const CreateCourse({super.key});

  @override
  State<CreateCourse> createState() => _CreateCourseState();
}

class _CreateCourseState extends State<CreateCourse> {
  List<String> levels = ['200', '300', '400', '500'];
  String? level = '200';

  List<String> semesters = ['first', 'second'];
  String? semester = 'first';

  Map<String, bool> allDepartments = {
    'CE': false,
    'EE': false,
    'CV': false,
    'ME': false,
  };

  late String courseCode;
  late String courseTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Creation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              //Level and semester
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
                                fontSize: 15.0,
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
        
             
              /// Department Checkboxes
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: allDepartments.keys.map((deptmnt) {
                  return CheckboxListTile(
                    title: Text(deptmnt),
                    value: allDepartments[deptmnt],
                    onChanged: (bool? newValue) {
                      setState(() {
                        allDepartments[deptmnt] = newValue!;
                      });
                    },
                  );
                }).toList(),
              ),
        
              /// Course Title TextField
              TextField(
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.blueAccent,
                  hintText: 'Course Title',
                  border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(50)),
                ),
                onChanged: (newValue) {
                  setState(() => courseTitle = newValue);
                },
              ),
              const SizedBox(height: 20.0),
        
              /// Course Code TextField
              TextField(
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.blueAccent,
                  hintText: 'CourseCode',
                  border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(50)),
                ),
                onChanged: (newValue) {
                  setState(() => courseCode = newValue);
                },
              ),
              const SizedBox(height: 20.0),
        
              /// Create Course Button
              ElevatedButton(
                onPressed: () async {
                  List<String> selectedDepartments = allDepartments.keys
                      .where((key) => allDepartments[key] == true)
                      .toList();
                  if (level == null ||
                      semester == null ||
                      selectedDepartments.isEmpty ||
                      courseCode.isEmpty ||
                      courseTitle.isEmpty) {
                    print('Something is empty');
                    return;
                  }
        
                  await createCourse(
                    context: context,
                    level: level!,
                    semester: semester!,
                    code: courseCode,
                    title: courseTitle,
                    departments: selectedDepartments,
                  );
        
                  print('course was created');
                  // You can use courseCode, courseTitle, level, semester, and selectedDepartments to create the course.
                  print('Course was created');
                },
                child: const Text('Create a new Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
