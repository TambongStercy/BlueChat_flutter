// import 'dart:async';
// import 'dart:io';

// import 'package:dio/dio.dart';
// import 'package:hive/hive.dart';

// part 'download_item.g.dart';

// @HiveType(typeId: 1)
// class DownloadItem extends HiveObject {
//   @HiveField(0)
//   String fileName;

//   @HiveField(1)
//   String path;

//   @HiveField(2)
//   int receivedBytes = 0;

//   @HiveField(3)
//   int totalBytes = 0;

//   @HiveField(4)
//   double progress = 0;

//   DownloadStatus status = DownloadStatus.notStarted;

//   CancelToken cancelToken = CancelToken();

//   StreamSubscription<List<int>>? downloadSubscription;

//   File? file;

//   // You don't need to store the 'file' property in Hive, as it's not serializable.
//   // You can recreate it when needed using 'path'.

//   DownloadItem({
//     required this.path,
//   }) {
//     fileName = path.split('/').last;
//     file = File(path);
//   }
// }

// enum DownloadStatus { notStarted, downloading, paused, completed }
