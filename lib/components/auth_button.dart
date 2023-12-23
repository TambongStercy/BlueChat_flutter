import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {

  final String title;
  final void Function() onPress;

  AuthButton({
    required this.title,
    required this.onPress
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Material(
          elevation: 5.0,
          borderRadius: BorderRadius.circular(15.0),
          color: Colors.blue[400],
          child: MaterialButton(
            onPressed: onPress,
            child: Padding(
              padding: 
              const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
                ),
            ),
          ),
        ),  
      ),
    );
  }
}