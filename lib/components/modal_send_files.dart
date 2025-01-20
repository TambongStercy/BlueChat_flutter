import 'dart:io';

import 'package:blue_chat_v1/components/video_trim.dart';
import 'package:flutter/material.dart';
import 'package:blue_chat_v1/components/circular_icon_avatar.dart';
import 'package:blue_chat_v1/screens/camera_screen.dart';
import 'package:provider/provider.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:file_picker/file_picker.dart';

import '../classes/message.dart';

class ModalContainerSendFiles extends StatelessWidget {
  const ModalContainerSendFiles({
    super.key,
    required this.updatePage,
  });

  final Function updatePage;

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<CurrentChat>(
      context,
      listen: false,
    ).openedChat!;
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15.0)),
        color: Colors.white,
      ),
      margin: const EdgeInsets.all(18.0),
      height: 200,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleIconAvatar(
              title: 'Camera',
              backgroungColor: Colors.pinkAccent,
              icon: Icons.camera_alt_rounded,
              onPress: () {
                Navigator.popAndPushNamed(context, CameraScreen.id)
                    .then((value) {
                  updatePage();
                });
              },
            ),
            const SizedBox(
              width: 20.0,
            ),
            CircleIconAvatar(
              title: 'Document',
              backgroungColor: Colors.purpleAccent,
              icon: Icons.insert_drive_file,
              onPress: () async {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                );

                if (result == null) return;

                for (PlatformFile file in result.files) {
                  final path = file.path!;

                  const type = MessageType.files;

                  // ignore: use_build_context_synchronously
                  chat.sendYourMessage(
                    context: context,
                    msg: '',
                    type: type,
                    path: path,
                  );
                }

                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
            ),
            const SizedBox(
              width: 20.0,
            ),
            CircleIconAvatar(
              title: 'Audio',
              backgroungColor: Colors.orangeAccent,
              icon: Icons.headset,
              onPress: () async {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.audio,
                );

                if (result == null) return;

                for (PlatformFile file in result.files) {
                  final path = file.path!;

                  const type = MessageType.audio;

                  // ignore: use_build_context_synchronously
                  chat.sendYourMessage(
                    context: context,
                    msg: '',
                    type: type,
                    path: path,
                  );
                }

                Navigator.pop(context);
              },
            ),
            const SizedBox(
              width: 20.0,
            ),
            CircleIconAvatar(
              title: 'Gallery',
              backgroungColor: Colors.greenAccent,
              icon: Icons.filter,
              onPress: () async {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.media,
                );
                if (result == null) return;

                final List<String> paths = [];
                final List<File> files = [];

                for (PlatformFile file in result.files) {
                  paths.add(file.path!);
                  files.add(File(file.path!));
                }

                // ignore: use_build_context_synchronously
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrimmerPageView(
                      mediaFiles: files,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
