import 'package:flutter/material.dart';


class CircleIconAvatar extends StatelessWidget {
  final Color backgroungColor;
  final IconData icon;
  final Function() onPress;
  final String title;
  CircleIconAvatar({
    required this.backgroungColor,
    required this.icon,
    required this.onPress,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30.0,
          child: IconButton(
            onPressed: onPress,
            icon: Icon(
              icon,
              color: Colors.white,
              size: 35.0,
            ),
          ),
          backgroundColor: backgroungColor,
        ),
        const SizedBox(
          height: 10.0,
        ),
        Text(
          title,
          style: TextStyle(color: Colors.black),
        )
      ],
    );
  }
}