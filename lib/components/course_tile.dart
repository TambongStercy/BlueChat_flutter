
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CourseTile extends StatelessWidget {
  CourseTile({
    super.key,
    required this.isQuestion,
    required this.title,
    required this.onTap,
  });

  final String title;

  final bool isQuestion;

  final Function() onTap; 

  final Widget pdfSVG = SvgPicture.asset(
    'assets/svg/pdf1.svg',
    width: 28.0,
  );

  final folder = SvgPicture.asset(
    'assets/svg/folder.svg',
    width: 40.0,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isQuestion? Colors.white: Colors.blue[800],
          radius: 16.0,
          child: isQuestion?pdfSVG:folder,
        ),
        style: ListTileStyle.list,
        title: Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        onTap: onTap,
        // () {
        //   // Navigator.push(
        //   //   context,
        //   //   MaterialPageRoute(
        //   //     builder: (context) => CourseSelectionScreen(),
        //   //   ),
        //   // );
        //   print('Navigate to Digital Electronics questions screen.');
        // },
        trailing: const Icon(Icons.arrow_right),
      ),
    );
  }
}
