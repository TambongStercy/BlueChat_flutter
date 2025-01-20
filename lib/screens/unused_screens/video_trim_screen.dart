import 'dart:io';

import 'package:blue_chat_v1/components/video_trim.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class VideoSelectionTrim extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Trimmer"),
      ),
      body: Center(
        child: Container(
          child: ElevatedButton(
            child: Text("LOAD VIDEO"),
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.media,
                // allowedExtensions: [
                //   '.png',
                //   '.jpg',
                //   '.mp4',
                // ],
                allowCompression: false,
                allowMultiple: true,
              );
              if (result != null) {
                List<File> files =
                    result.paths.map((path) => File(path!)).toList();

                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return TrimmerPageView(
                      mediaFiles: files,
                    );
                  }),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
