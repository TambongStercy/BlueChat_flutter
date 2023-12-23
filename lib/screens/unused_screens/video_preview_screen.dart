// import 'dart:io';
// import 'package:blue_chat_v1/constants.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter/material.dart';
// import 'package:blue_chat_v1/classes/message.dart';
// import 'package:video_player/video_player.dart';
// import 'package:blue_chat_v1/screens/chat_screen.dart';

// class VideoPreviewScreen extends StatefulWidget {
//   final String videoPath;

//   VideoPreviewScreen({required this.videoPath});

//   @override
//   State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
// }

// class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
//   VideoPlayerController? _videoPlayerController;
//   // bool _isPlaying = false;

//   @override
//   void dispose() {
//     _videoPlayerController!.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {

//     _videoPlayerController = VideoPlayerController.file(File(widget.videoPath))
//       ..initialize().then((_) {
//         // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
//         setState(() {});
//       }).catchError((e){
//         print(e);
//       });

//     super.initState();
//   }

//   // Future _initVideoPlayer() async {
//     // print('1');
//   //   _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
//   //   // _videoPlayerController = VideoPlayerController.asset('video/dark.mp3');
//   //   // final videoUrl = 'video/dark.mp3';
//   //   // final videoFile = await rootBundle.load(videoUrl);
//   //   // _videoPlayerController = VideoPlayerController.networkUrl(videoFile);
//   //   print('2');
//   //   await _videoPlayerController!.initialize().then((val) {
//   //     print('successfull initialization fo video controller');
//   //   }).catchError((e) => print(e));
//   //   print('3');
//   //   // await _videoPlayerController!.setLooping(true);
//   //   print('4');
//   //   await _videoPlayerController!.play();
//   //   print('5');
//   // }

//   // void _toggleVideoPlayback() {
//   //   setState(() {
//   //     if (_videoPlayerController!.value.isPlaying) {
//   //       _videoPlayerController!.pause();
//   //       _isPlaying = false;
//   //     } else {
//   //       _videoPlayerController!.play();
//   //       _isPlaying = true;
//   //     }
//   //   });
//   // }

//   final id = 'video_preview_screen';

//   String caption = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: Text('To Nezuko'),
//         elevation: 0,
//         actions: [
//           IconButton(
//             onPressed: () {
//               print('go to crop screen');
//             },
//             icon: Icon(
//               Icons.crop,
//               color: Colors.white,
//             ),
//           )
//         ],
//       ),
//       extendBodyBehindAppBar: true,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Container(
//               width: MediaQuery.of(context).size.width,
//               height: MediaQuery.of(context).size.height - 150,
//               child: _videoPlayerController!.value.isInitialized
//                   ? AspectRatio(
//                       aspectRatio: _videoPlayerController!.value.aspectRatio,
//                       child: VideoPlayer(_videoPlayerController!),
//                     )
//                   : Container(),
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
//                     prefixIcon: const Icon(
//                       Icons.add_photo_alternate,
//                       color: Colors.white,
//                       size: 27,
//                     ),
//                     hintStyle: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 17,
//                     ),
//                     suffixIcon: CircleAvatar(
//                       radius: 27,
//                       backgroundColor: Colors.tealAccent[700],
//                       child: IconButton(
//                         onPressed: (){
//                           final file = AccFiles(
//                             path: widget.videoPath,
//                             caption: caption,
//                             type: MessageType.video
//                           );
//                           int count = 0;

//                           Provider.of<FilesToSend>(context,listen: false).addFiles([file]);
                          
//                           Navigator.popUntil(
//                             context,
//                             (route) {
//                               return count++ == 2;
//                             }
//                           );
//                         },
//                         icon: Icon(
//                           Icons.check,
//                           color: Colors.white,
//                           size: 27,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             Align(
//               alignment: Alignment.center,
//               child: InkWell(
//                 onTap: () {
//                   setState(() {
//                     _videoPlayerController!.value.isPlaying
//                         ? _videoPlayerController!.pause()
//                         : _videoPlayerController!.play();
//                   });
//                 },
//                 child: CircleAvatar(
//                   radius: 33,
//                   backgroundColor: Colors.black38,
//                   child: Icon(
//                     _videoPlayerController!.value.isPlaying
//                         ? Icons.pause
//                         : Icons.play_arrow,
//                     color: Colors.white,
//                     size: 50,
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
