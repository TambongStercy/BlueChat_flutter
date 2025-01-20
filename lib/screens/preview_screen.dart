// import 'package:blue_chat_v1/classes/chat_hive_box.dart';
// import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/components/my_emoji_picker.dart';
// import 'package:blue_chat_v1/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
// import 'package:photo_view/photo_view.dart';
import 'package:mime/mime.dart';

class PreviewScreen extends StatefulWidget {
  final List<String> mediaPaths;
  final double popsAfter;

  PreviewScreen({required this.mediaPaths, required this.popsAfter});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;
  final List<Widget> _pages = [];
  final List<Widget> _indicators = [];
  final List<VideoPlayerController?> _videoControllers = [];
  final List<String> captions = [''];
  final TextEditingController textController = TextEditingController();

  final FocusNode _focusNode = FocusNode();
  bool _emojiShowing = false;

  bool isImage(String path) {
    final mimeType = lookupMimeType(path);
    return (mimeType!.split('/').first == 'image');
  }

  void _onBackspacePressed() {
    textController
      ..text = textController.text.characters.toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: textController.text.length));
  }

  void _toggleEmojiPicker() {
    if (!_emojiShowing) {
      // Show emoji picker
      setState(() {
        _emojiShowing = true;
        _focusNode.unfocus();
      });
    } else {
      // Hide emoji picker and show keyboard
      setState(() {
        _emojiShowing = false;
        _focusNode.requestFocus();
      });
    }
  }

  void _addEmoji(emoji) {
    setState(() {
      captions[_currentIndex] += emoji;
    });
  }

  void initFiles() {
    for (VideoPlayerController? videoController in _videoControllers) {
      videoController?.dispose();
    }
    _videoControllers.length = 0;
    _pages.length = 0;
    _indicators.length = 0;

    for (var i = 0; i < widget.mediaPaths.length; i++) {
      captions.add('');
      final url = widget.mediaPaths[i];
      if (!isImage(url)) {
        _videoControllers.add(VideoPlayerController.file(File(url)));
        print(_videoControllers.last!.value.aspectRatio);
        _pages.add(
          Container(
            height: 500,
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: _videoControllers.last!.value.aspectRatio,
                    child: VideoPlayer(_videoControllers.last!),
                  ),
                ),
              ],
            ),
          ),
        );
        _indicators.add(
          Container(

            child: Column(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: _videoControllers.last!.value.aspectRatio,
                    child: VideoPlayer(_videoControllers.last!),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        _pages.add(Container(child: Image.file(File(url), fit: BoxFit.fitWidth)));
        print('$i pageURL: $url');
        _indicators.add(Image.file(File(url), fit: BoxFit.cover));
        print('$i indicatorURL: $url');
        _videoControllers.add(null);
      }
    }

    if (_videoControllers.isNotEmpty) {
      _videoControllers[_currentIndex]?.initialize().then((_) {
        setState(() {});
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initFiles();
  }

  @override
  void dispose() {
    for (VideoPlayerController? videoController in _videoControllers) {
      videoController?.dispose();
    }

    super.dispose();
  }

  Future<void> saveCrop(String newPath) async {
    _pages[_currentIndex] = (Image.file(File(newPath), fit: BoxFit.fitWidth));
    _indicators[_currentIndex] = (Image.file(File(newPath), fit: BoxFit.cover));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final paths = widget.mediaPaths;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: isImage(paths[_currentIndex])
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.crop_rotate,
                    size: 27,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    final croppedFile = await ImageCropper().cropImage(
                      sourcePath: paths[_currentIndex],
                      uiSettings: [
                        AndroidUiSettings(
                            toolbarTitle: 'Cropping',
                            toolbarColor: Colors.blueGrey[900],
                            toolbarWidgetColor: Colors.white,
                            initAspectRatio: CropAspectRatioPreset.original,
                            lockAspectRatio: false),
                        IOSUiSettings(
                          title: 'Cropping',
                        ),
                        WebUiSettings(
                          context: context,
                        ),
                      ],
                    );

                    if (croppedFile != null) {
                      final newPath = croppedFile.path;
                      await saveCrop(newPath);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    size: 27,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    Icons.title,
                    size: 27,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 27,
                  ),
                  onPressed: () {},
                ),
              ]
            : [],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                textController.text = captions[_currentIndex];
                if (_videoControllers[index] != null &&
                    _videoControllers[index]!.value.isPlaying) {
                  _videoControllers[index]!.pause();
                }

                _videoControllers[index]?.initialize().then((_) {
                  setState(() {});
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _pages[index];
              },
              // children: _pages,
            ),

            if (_videoControllers[_currentIndex] != null)
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    color: Colors.black26,
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(0),
                    icon: Icon(
                      _videoControllers[_currentIndex]!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 35.0,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_videoControllers[_currentIndex]!.value.isPlaying) {
                          _videoControllers[_currentIndex]!.pause();
                        } else {
                          _videoControllers[_currentIndex]!.play();
                        }
                      });
                    },
                  ),
                ),
              ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 125.0,
                color: Colors.black.withOpacity(0.5),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (var i = 0; i < _pages.length; i++)
                            GestureDetector(
                              onTap: () {
                                _pageController.jumpToPage(
                                  i,
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                  color: i == _currentIndex
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2.0,
                                )),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: _indicators[i],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.blueGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TextFormField(
                              focusNode: _focusNode,
                              controller: textController,
                              onChanged: (newValue) =>
                                  captions[_currentIndex] = newValue,
                              onTap: () {
                                if (_emojiShowing) {
                                  _toggleEmojiPicker();
                                }
                              },
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                              maxLines: 6,
                              minLines: 1,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Add Caption....",
                                prefixIcon: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.add_photo_alternate,
                                    color: Colors.white,
                                    size: 27,
                                  ),
                                ),
                                hintStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
                                // suffixIcon:
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        CircleAvatar(
                          radius: 27,
                          backgroundColor: Colors.tealAccent[700],
                          child: IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 27,
                            ),
                            onPressed: () async {
                              final chat = Provider.of<CurrentChat>(
                                context,
                                listen: false,
                              ).openedChat!;

                              for (int i = 0;
                                  i < widget.mediaPaths.length;
                                  i++) {
                                String mediaPath = widget.mediaPaths[i];
                                String caption = captions[i];

                                final type = isImage(mediaPath)
                                    ? MessageType.image
                                    : MessageType.video;

                                await chat.sendYourMessage(
                                  context: context,
                                  msg: caption,
                                  type: type,
                                  path: mediaPath,
                                );

                                setState(() {});

                                int count = 0;

                                Navigator.popUntil(context, (route) {
                                  return count++ == widget.popsAfter;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    MyEmojiPicker(
                      emojiShowing: _emojiShowing,
                      onBackspacePressed: _onBackspacePressed,
                      textEditingController: textController,
                      draft: captions[_currentIndex],
                      addEmoji: _addEmoji,
                    ),
                  ],
                ),
              ),
            ),

            // Align(
            //   alignment: Alignment.topCenter,
            //   child: ,
            // )
          ],
        ),
      ),
    );
  }
}
