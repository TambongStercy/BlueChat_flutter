// import 'dart:io';

// import 'package:hive/hive.dart';

// part 'upload_item.g.dart';

// @HiveType(typeId: 0)
// class UploadItem extends HiveObject {
//   @HiveField(0)
//   String? selectedFilePath;

//   @HiveField(1)
//   double uploadProgress = 0.0;

//   @HiveField(2)
//   String uploadStatus = '';

//   @HiveField(3)
//   bool uploadPaused = false;

//   @HiveField(4)
//   int initOffset = 0;

//   @HiveField(5)
//   String fileId = '';

//   @HiveField(6)
//   late String name;

  
//   late File file;

//   // You don't need to store the 'file' property in Hive, as it's not serializable.
//   // You can recreate it when needed using 'selectedFilePath'.

//   UploadItem({required this.selectedFilePath}) {
//     file = File(selectedFilePath!);
//     name = selectedFilePath!.split('/').last;
//   }
// }
