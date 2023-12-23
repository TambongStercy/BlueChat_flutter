import 'package:flutter/material.dart';
// import 'dart:io';
// import 'dart:async';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'dart:typed_data';
// import 'package:permission_handler/permission_handler.dart';


class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});
  static const id = 'gallery_page';
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

// class GalleryPage extends StatefulWidget {
//   const GalleryPage({super.key});
//   static final id = 'gallery_page';
//   @override
//   State<GalleryPage> createState() => _GalleryPageState();
// }

// class _GalleryPageState extends State<GalleryPage> {
  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //   getFiles();
  // }

  // List<String> firstPath = [];
  // var dirtory = null;
  // var permission;
  // final imagesAndVideos = [];

  // Future<Uint8List> _getVideoThumbnail(String videoPath) async {
  //   final uint8list = await VideoThumbnail.thumbnailData(
  //     video: videoPath,
  //     imageFormat: ImageFormat.JPEG,
  //     maxWidth: 100,
  //     quality: 25,
  //   );
  //   return uint8list!;
  // }

  // Widget _buildImageOrVideo(File file) {
  //   if (file.path.endsWith('.mp4')) {
  //     return FutureBuilder<Uint8List>(
  //       future: _getVideoThumbnail(file.path),
  //       builder: (context, snapshot) {
  //         if (snapshot.hasData) {
  //           return Image.memory(snapshot.data!);
  //         } else {
  //           return Container();
  //         }
  //       },
  //     );
  //   } else {
  //     return Image.file(file);
  //   }
  // }
  // void getFiles() async {
  //   PermissionStatus status = await Permission.storage.status;
  //   if (status.isGranted) {
  //     print('permisson granted');
  //   } else {
  //     // Permission is not granted, request it
  //     PermissionStatus requestStatus = await Permission.storage.request();
  //     print(requestStatus);
  //     if (requestStatus.isGranted) {
  //       print('permisson granted');
  //     } else {
  //       print('permisson refused');
  //     }
  //   }
  //   permission = status.isGranted;

  //   final photoDir = Directory('/storage/emulated/0');

  //   Stream<FileSystemEntity> files = photoDir.list(recursive: true);

  //   files = files.where((file) => !file.path.startsWith('Android'));


  //   dirtory = files;

  //   files.listen((file) async {
  //     if (file.path.endsWith('.jpg') ||  file.path.endsWith('.png') ||  file.path.endsWith('.mp4')) {
        
  //       print('A media: ${file.path}');
  //       firstPath.add(file.path);

  //       imagesAndVideos.add(file);

  //     } else {
  //       print('Not a media: ${file.path}');
  //     }
  //     setState(() {});
  //   });

  //   //This is the error here 💔
  //   // Erro Flutter - @pragma("vm:external-name", "Error_throwWithStackTrace") external static Never _throw(Object error, StackTrace stackTrace);

  // }

  // // Column showFiles() {
  // //   List<Widget> texts = [];
  // //   List<Widget> grid = [];
  // //   for (String path in firstPath) {
  // //     texts.add(Text(path));
  // //   }
  // //   return Column( children: texts);
  // // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('Gallery section'),
  //     ),
  //     body: SafeArea(
  //       child: Center(
  //         child: GridView.count(
  //           padding: const EdgeInsets.all(0),
  //           crossAxisCount: 3,
  //           physics: const BouncingScrollPhysics(),
  //           children: imagesAndVideos.map((file) =>_buildImageOrVideo(file)).toList(),
  //         )
  //         // ListView(
  //         //   children: [
  //         //     firstPath.length > 0
  //         //         ? Text('${firstPath[0]}: First')
  //         //         : const CircularProgressIndicator(),
  //         //     Text('$permission: Permission'),
  //         //     showFiles(),
  //         //     // Expanded(child: Text('A')),
  //         //     // Expanded(child: Text('B')),
  //         //     // Expanded(child: Text('C')),
  //         //   ],
  //         // ),
  //       ),
  //     ),
  //   );
  // }
// }
