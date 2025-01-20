import 'dart:io';

import 'package:hive/hive.dart';

part 'upload_item.g.dart'; // Hive Type Adapter Generator

@HiveType(typeId: 1)
class UploadItem extends HiveObject {
  @HiveField(0)
  String? selectedFilePath;

  @HiveField(1)
  double uploadProgress;

  @HiveField(2)
  String uploadStatus;

  @HiveField(3)
  bool uploadPaused;

  @HiveField(4)
  int initOffset;

  @HiveField(5)
  String fileId;

  @HiveField(6)
  late String name;

  @HiveField(7)
  late File file;

  UploadItem({required this.selectedFilePath})
      : uploadProgress = 0.0,
        uploadStatus = '',
        uploadPaused = false,
        initOffset = 0,
        fileId = '' {
    file = File(selectedFilePath!);
    name = file.path.split('/').last;
  }
}
