// ignore_for_file: sort_child_properties_last

import 'dart:io';

import 'package:blue_chat_v1/api_call.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/screens/chats.dart';
import 'package:file_picker/file_picker.dart  ';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PpUpload extends StatefulWidget {
  const PpUpload({super.key});

  static const String id = 'upload_profile_picture';

  @override
  State<PpUpload> createState() => _PpUploadState();
}

class _PpUploadState extends State<PpUpload> {
  bool waiting = false;

  String userProfilePicturePath = '';

  bool init = true;

  @override
  Widget build(BuildContext context) {
    if (init) {
      init = false;
      userProfilePicturePath =
          Provider.of<UserHiveBox>(context, listen: false).avatar;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload profile picture'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 15.0,
                ),
                const Text(
                  'Please provide a picture for your profile',
                  style: TextStyle(fontSize: 15.0),
                ),
                const SizedBox(
                  height: 100.0,
                  width: double.infinity,
                ),
                SizedBox(
                  child: InkWell(
                    onTap: () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );

                        if (result == null) return;

                        setState(() {
                          waiting = true;
                        });

                        final filePath = result.files.first.path!;

                        print('filePath : $filePath');

                        final mobilePath = await avatarPath(filePath);

                        print('mobilePath : $mobilePath');

                        // ignore: use_build_context_synchronously
                        await uploadPP(context: context, path: mobilePath);

                        userProfilePicturePath = mobilePath;

                      } on Exception catch (e) {
                        print(e);
                        setState(() {
                          waiting = false;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 100.0,
                      child: !ppExist(userProfilePicturePath)
                          ? const Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.grey,
                              size: 120.0,
                            )
                          : null,
                      backgroundImage: _profileImage(),
                      backgroundColor: Colors.blueGrey[100],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(fontSize: 17.0),
                  ),
                ),
                onPressed: () async {
                  Navigator.pushNamed(
                    context,
                    ChatsScreen.id,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider<Object>? _profileImage() {
    if (ppExist(userProfilePicturePath)) {
      // Check if the user's profile picture path is not empty and the file exists.
      return FileImage(File(userProfilePicturePath));
    }
    // Return the default profile picture from the asset folder.
    return null;
  }

  bool ppExist(path) {
    return path.isNotEmpty && File(path).existsSync();
  }
}
