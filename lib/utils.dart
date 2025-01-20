import 'package:flutter/material.dart';

void popUntilAndPush(BuildContext context, String pageId) {
  Navigator.of(context).pushNamedAndRemoveUntil(
    pageId,
    (Route<dynamic> route) => false,
  );

  // Navigator.popUntil(context, (route) => route.isFirst);

  // print('pushing from pop');
  // // Now, push the new page as the first page
  // Navigator.pushReplacement(
  //   context,
  //   MaterialPageRoute(builder: (context) => page),
  // );
}

final darkBG = Color.fromARGB(255, 6, 6, 6);

