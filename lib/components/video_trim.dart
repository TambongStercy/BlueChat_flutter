import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/screens/chat_screen.dart';
import 'package:blue_chat_v1/screens/chats.dart';
import 'package:blue_chat_v1/screens/unused_screens/image_crop_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:io';
import 'dart:typed_data';

class TrimmerView extends StatefulWidget {
  final File file;
  final GlobalKey<_TrimmerViewState> key;

  TrimmerView(this.file, this.key) : super(key: key);

  @override
  _TrimmerViewState createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView>
    with AutomaticKeepAliveClientMixin<TrimmerView> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  String? _value;
  final bool exist = true;

  Future<String?> saveVideo(Function val) async {
    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      videoFolderName: 'tempTrim',
      onSave: (value) {
        val(value);
      },
    );

    return _value;
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.file);
  }

  void stopPlaying() async {
    if (_isPlaying) {
      bool playbackState = await _trimmer.videoPlaybackControl(
        startValue: _startValue,
        endValue: _endValue,
      );
      if (mounted) {
        setState(() {
          _isPlaying = playbackState;
        });
      }
    }
  }

  @override
  void initState() {
    _loadVideo();
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      child: Builder(
        builder: (context) => Center(
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () async {
                    bool playbackState = await _trimmer.videoPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    if (mounted) {
                      setState(() {
                        _isPlaying = playbackState;
                      });
                    }
                  },
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 30.0),
                          child: VideoViewer(trimmer: _trimmer),
                        ),
                        (!_isPlaying)
                            ? Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: Colors.black54,
                                  ),
                                  padding: const EdgeInsets.all(9.0),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    size: 50.0,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : SizedBox(),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Center(
                      child: TrimViewer(
                        trimmer: _trimmer,
                        viewerHeight: 50.0,
                        viewerWidth: MediaQuery.of(context).size.width * 0.97,
                        onChangeStart: (value) => _startValue = value,
                        onChangeEnd: (value) => _endValue = value,
                        onChangePlaybackState: (value) {
                          if (mounted) setState(() => _isPlaying = value);
                        },
                        editorProperties: const TrimEditorProperties(
                          borderWidth: 2.5,
                          circleSize: 6.0,
                          circleSizeOnDrag: 9.0,
                          circlePaintColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImageView extends StatelessWidget {
  final File file;

  ImageView(this.file);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: PhotoView(
          imageProvider: FileImage(file),
        ),
      ),
    );
  }
}

class TrimmerPageView extends StatefulWidget {
  final List<File> mediaFiles;

  TrimmerPageView({required this.mediaFiles});

  @override
  _TrimmerPageViewState createState() => _TrimmerPageViewState();
}

class _TrimmerPageViewState extends State<TrimmerPageView> {
  PageController _pageController = PageController();
  List<GlobalKey<_TrimmerViewState>> _trimmerKeys = [];
  int _currentPage = 0;
  List<Uint8List?> _thumbnails = [];
  List<String> _captions = [];
  bool _showEmojiPicker = false;
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Widget> _pages = [];
  final List<File> _finalFiles = [];

  @override
  void initState() {
    super.initState();
    _trimmerKeys = List.generate(
        widget.mediaFiles.length, (index) => GlobalKey<_TrimmerViewState>());
    _captions = List.generate(widget.mediaFiles.length, (index) => "");

    for (final file in widget.mediaFiles) {
      _finalFiles.add(file);
    }

    _pages = widget.mediaFiles.map((file) {
      int index = widget.mediaFiles.indexOf(file);
      if (_isVideoFile(file)) {
        return TrimmerView(file, _trimmerKeys[index]);
      } else {
        return ImageView(file);
      }
    }).toList();

    _generateThumbnails();

    _captionController.addListener(() {
      _captions[_currentPage] = _captionController.text;
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    });
  }

  Future<void> _generateThumbnails() async {
    List<Uint8List?> thumbnails = [];
    for (var file in widget.mediaFiles) {
      if (_isVideoFile(file)) {
        final thumbnail = await VideoThumbnail.thumbnailData(
          video: file.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth:
              128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
          quality: 25,
        );
        thumbnails.add(thumbnail);
      } else {
        thumbnails.add(await file.readAsBytes());
      }
    }
    if (mounted) {
      setState(() {
        _thumbnails = thumbnails;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _captionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isVideoFile(File file) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.wmv', '.flv', '.mkv'];
    final fileExtension = file.path.split('.').last;
    return videoExtensions.contains('.$fileExtension'.toLowerCase());
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      FocusScope.of(context).requestFocus(_focusNode);
    } else {
      FocusScope.of(context).unfocus();
    }
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _onBackspacePressed() {
    _captionController
      ..text = _captionController.text.characters.toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _captionController.text.length));
  }

  void _deleteCurrentMedia() {
    setState(() {
      widget.mediaFiles.removeAt(_currentPage);
      _trimmerKeys.removeAt(_currentPage);
      _captions.removeAt(_currentPage);
      _thumbnails.removeAt(_currentPage);
      _finalFiles.removeAt(_currentPage);
      if (_currentPage > 0) {
        _currentPage--;
      }
      if (widget.mediaFiles.isEmpty) {
        Navigator.of(context).pop();
      } else {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  Future<void> _saveAllMedia(context) async {
    final String appTempDir = kTempDirectory.path;
    for (int i = 0; i < widget.mediaFiles.length; i++) {
      final file = widget.mediaFiles[i];
      if (_isVideoFile(file)) {
        // Save trimmed video
        final key = _trimmerKeys[i];
        if (key.currentState != null) {
          await key.currentState?.saveVideo((value) async {
            final outputPath = value;

            if (outputPath != null) {
              final File savedFile = File(outputPath);
              final String newFilePath =
                  '$appTempDir/${savedFile.uri.pathSegments.last}';

              await savedFile.copy(newFilePath);
              _finalFiles[i] = File(newFilePath);

              savedFile.deleteSync();
            }

            if (i == widget.mediaFiles.length - 1) {
              //Send message
              _sendMessages(context);
            }
          });
        } else {
          if (i == widget.mediaFiles.length - 1) {
            //Send message
            _sendMessages(context);
          }
          print('Is not trimmed so remains the same');
        }
      } else {
        if (i == widget.mediaFiles.length - 1) {
          //Send message
          _sendMessages(context);
        }
        print('Is an Image so, is already saved');
      }
    }
  }

  Future<void> _sendMessages(context) async {
    final chat = Provider.of<CurrentChat>(
      context,
      listen: false,
    ).openedChat!;

    for (int i = 0; i < _finalFiles.length; i++) {
      final file = _finalFiles[i];
      final mediaPath = file.path;

      String caption = _captions[i];

      final type = _isVideoFile(file) ? MessageType.video : MessageType.image;

      await chat.sendYourMessage(
        context: context,
        msg: caption,
        type: type,
        path: mediaPath,
      );
    }

    Navigator.popUntil(context, (route) {
      
      print('============////////////////================');
      print('////////////===============/////////////////');
      print('============////////////////================');
      print('////////////===============/////////////////');
      print('============////////////////================');
      print('////////////===============/////////////////');
      print('============////////////////================');
      print('////////////===============/////////////////');
      print('============////////////////================');
      print('////////////===============/////////////////');
      print('============////////////////================');
      print('////////////===============/////////////////');
      print('============////////////////================');
      print('////////////===============/////////////////');
      print('============////////////////================');
      print('////////////===============/////////////////');
      print('============////////////////================');
      print('////////////===============/////////////////');
      print(route.settings.name);
      return (route.settings.name == ChatScreen.id||route.settings.name == ChatsScreen.id);
    });
    // Navigator.popUntil(context, ModalRoute.withName(ChatScreen.id));
  }

  Future<void> _cropImage() async {
    File? croppedFile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyCropper(image: widget.mediaFiles[_currentPage]),
      ),
    );

    if (croppedFile != null && mounted) {
      print('OUTPUT: ${croppedFile.path}');
      _pages[_currentPage] = ImageView(croppedFile);
      _finalFiles[_currentPage] = croppedFile;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaFiles = widget.mediaFiles;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 27,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Color.fromARGB(255, 26, 26, 27),
        actions: [
          if (!_isVideoFile(mediaFiles[_currentPage]))
            IconButton(
              icon: const Icon(
                Icons.crop_rotate,
                size: 27,
              ),
              onPressed: _cropImage,
              color: Colors.white,
            ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteCurrentMedia,
            color: Colors.white,
          ),
        ],
      ),
      resizeToAvoidBottomInset:
          false, // Prevents resizing when the keyboard appears
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView(
            controller: _pageController,
            children: _pages.map((page) => page).toList(),
            // children:  List<Widget>.generate(_pages.length, (index) {
            //   return Container(
            //     key: PageStorageKey(index),
            //     child: _pages[index],
            //   );
            // }),
            onPageChanged: (index) {
              setState(() {
                _trimmerKeys[_currentPage].currentState?.stopPlaying();
                _currentPage = index;
                _captionController.text = _captions[_currentPage];
              });
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.mediaFiles.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.jumpToPage(index);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _currentPage == index
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          child: _thumbnails.isNotEmpty
                              ? Image.memory(
                                  width: 50,
                                  height: 50,
                                  _thumbnails[index]!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                    );
                  },
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
                        controller: _captionController,
                        focusNode: _focusNode,
                        onTap: () {
                          if (_showEmojiPicker) {
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
                            onPressed: () {
                              _toggleEmojiPicker();
                            },
                            icon: Icon(
                              !_showEmojiPicker
                                  ? Icons.emoji_emotions_rounded
                                  : Icons.keyboard,
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
                      onPressed: () {
                        _saveAllMedia(context);
                      },
                    ),
                  ),
                ],
              ),
              if (_showEmojiPicker)
                SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      _captionController.text += emoji.emoji;
                    },
                    onBackspacePressed: _onBackspacePressed,
                  ),
                ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
