// import 'package:blue_chat_v1/classes/message.dart';
// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'package:blue_chat_v1/constants.dart';
// import 'package:provider/provider.dart';
// // import 'package:blue_chat_v1/screens/chat_screen.dart';

// class ImagePreviewScreen extends StatelessWidget {
//   final id = 'image_preview_screen';

//   final String imagePath;

//   ImagePreviewScreen({required this.imagePath});

//   String caption = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         actions: [
//           IconButton(
//             icon: Icon(
//               Icons.crop_rotate,
//               size: 27,
//             ),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: Icon(
//               Icons.emoji_emotions_outlined,
//               size: 27,
//             ),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: Icon(
//               Icons.title,
//               size: 27,
//             ),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: Icon(
//               Icons.edit,
//               size: 27,
//             ),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Container(
//         width: MediaQuery.of(context).size.width,
//         height: MediaQuery.of(context).size.height,
//         child: Stack(
//           children: [
//             Container(
//               width: MediaQuery.of(context).size.width,
//               height: MediaQuery.of(context).size.height - 150,
//               child: Image.file(
//                 File(imagePath),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             Positioned(
//               bottom: 0,
//               child: Container(
//                 color: Colors.black38,
//                 width: MediaQuery.of(context).size.width,
//                 padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
//                 child: TextFormField(
//                   onChanged: (newValue)=> caption = newValue,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 17,
//                   ),
//                   maxLines: 6,
//                   minLines: 1,
//                   decoration: InputDecoration(
//                     border: InputBorder.none,
//                     hintText: "Add Caption....",
//                     prefixIcon: Icon(
//                       Icons.add_photo_alternate,
//                       color: Colors.white,
//                       size: 27,
//                     ),
//                     hintStyle: TextStyle(
//                       color: Colors.white,
//                       fontSize: 17,
//                     ),
//                     suffixIcon: CircleAvatar(
//                       radius: 27,
//                       backgroundColor: Colors.tealAccent[700],
//                       child: IconButton(
//                         icon: Icon(
//                           Icons.check,
//                           color: Colors.white,
//                           size: 27,
//                         ),
//                         onPressed: () async {
//                           final file = AccFiles(
//                             path: imagePath,
//                             caption: caption,
//                             type: MessageType.image
//                           );
//                           int count = 0;

//                           Provider.of<FilesToSend>(context,listen: false).addFiles([file]);
                          
//                           Navigator.popUntil(
//                             context,
//                             (route) {
//                               return count++ == 2;
//                             }
//                           );
//                           // Navigator.push(
//                           //   context,
//                           //   MaterialPageRoute(
//                           //     builder: (
//                           //       (context) => ChatScreen(files: [file],)
//                           //     )
//                           //   )
//                           // );
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
