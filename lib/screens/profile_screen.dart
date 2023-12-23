import 'dart:io';

import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/screens/profile_picture.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  static const String id = 'profile_screen';

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userBox = Provider.of<UserHiveBox>(context, listen: false);

    final avatarUrl = userBox.avatar;

    final ppFile = File(avatarUrl);

    final image = (ppFile.existsSync()
            ? FileImage(ppFile)
            : const AssetImage('assets/images/user1.png'))
        as ImageProvider<Object>?;

    final ppWidget = CircleAvatar(
      backgroundImage: image,
      radius: 100.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer<UserHiveBox>(
        builder: (context, user, child) {
          String name = user.name;
          // String email = user.email;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        FadePageRoute(
                          builder: (context) => ProfilePicture(
                            path: avatarUrl,
                            chatName: '',
                            tag: 'pp',
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'user_profile',
                          child: ppWidget,
                        ),
                        Hero(
                          tag: 'pp',
                          child: CircleAvatar(
                            radius: 100,
                            backgroundImage: image,
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.lightBlueAccent,
                                child: Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    onPressed: () async {
                                      final result =
                                          await FilePicker.platform.pickFiles(
                                        allowMultiple: true,
                                        type: FileType.image,
                                      );
                                      if (result == null) {
                                        return;
                                      } else {
                                        print(result.files.last.path);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 35.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ListTile(
                onTap: () {
                  showModalBottomSheet(
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (BuildContext context) {
                      return ChangeName();
                    },
                  );
                },
                leading: const Icon(
                  Icons.account_circle,
                  size: 35.0,
                ),
                title: Text(name),
                subtitle: const Text('Name'),
                trailing: const Icon(
                  Icons.edit,
                  color: Colors.lightBlue,
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class ChangeName extends StatefulWidget {
  const ChangeName({
    super.key,
  });

  @override
  State<ChangeName> createState() => _ChangeNameState();
}

class _ChangeNameState extends State<ChangeName> {
  /// Define the focus node. To manage the life cycle, create the FocusNode in the initState method, and clean it up in the dispose method.
  late FocusNode _focusNode;

  /// An object that is used to control the Text Form Field.
  final TextEditingController _editingController = TextEditingController();

  int _textLength = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.lightBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter your new name',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Color(0xFFFFFF).withOpacity(0.54),
                    size: 24,
                  ),
                  onPressed: () {
                    _editingController.clear();
                    Navigator.pop(context);
                  },
                ),
              ),
              Flexible(
                child: TextFormField(
                  cursorColor: Colors.white10,
                  style: TextStyle(
                      color: Color(0xf2f2f2).withOpacity(0.87), fontSize: 16),
                  enableInteractiveSelection: false,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  controller: _editingController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Find...',
                    hintStyle: TextStyle(
                      color: Color(0xFFFFFF).withOpacity(0.34),
                    ),
                  ),
                  onChanged: (text) {
                    if (_textLength < _editingController.value.text.length) {
                      _textLength = _editingController.value.text.length;
                    }
                    setState(() {});
                  },
                ),
              ),
              Visibility(
                visible: _editingController.text.isNotEmpty,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Color.fromRGBO(255, 255, 255, 0.884),
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _editingController.clear();
                        _focusNode.requestFocus();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
            ),
            onPressed: () {
              // Perform any necessary actions with the text input
              Navigator.pop(context);
            },
            child: Text(
              'Submit',
              style: TextStyle(
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
