import 'dart:convert';
import 'dart:io';

import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/screens/share_to_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/components/chat_message.dart';
import 'package:blue_chat_v1/components/my_emoji_picker.dart';
import 'package:blue_chat_v1/screens/chat_settings.dart';
import 'package:blue_chat_v1/components/bottom_text_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blue_chat_v1/classes/message.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// ignore: must_be_immutable
class ChatScreen extends StatefulWidget {
  static const id = 'chat_screen';

  Chat chat;
  // final List<AccFiles>? files;

  ChatScreen({
    required this.chat,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isContainerVisible = false;
  int mediaIndex = 0;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  bool _emojiShowing = false;

  final List<ChatMessage> _message = [];

  String draft = '';

  final List<MessageModel> medias = [];

  @override
  void initState() {
    getFiles();
    initMessages();
    super.initState();
  }

  void updatePage() {
    if (mounted) {
      print('updating chatScreen');
      initMessages();
      setState(() {});
    }
  }

  void initMessages() {
    _message.length = 0;
    final chat = widget.chat;
    final messages = chat.messages;
    final mediaMsgs = chat.getMediaMessages();
    for (MessageModel message in messages) {
      int index = mediaMsgs.indexWhere((msg) => msg.id == message.id);

      _message.add(
        ChatMessage(
          id: message.id,
          dateTime: message.date,
          chatID: widget.chat.id,
          sender: message.sender,
          message: message.message,
          time: message.time,
          size: message.size,
          isMe: message.isMe,
          type: message.type,
          status: message.status,
          filePath: message.filePath,
          decibels: message.decibels,
          scrollTo: _scrollToIndex,
          index: index,
          repliedToId: message.repliedToId,
        ),
      );
    }
  }

  void getFiles() async {
    PermissionStatus status = await Permission.storage.status;
    if (status.isGranted) {
      print('permisson granted');
    } else {
      // Permission is not granted, request it
      PermissionStatus requestStatus = await Permission.storage.request();
      print(requestStatus);
      if (requestStatus.isGranted) {
        print('permisson granted');
        ;
      } else {
        print('permisson refused');
      }
    }
  }

  void _scrollToIndex(int id) {
    final messages = _message.reversed.toList();

    int index = messages.indexWhere((element) => element.id == id);

    if (index > 0) {
      _itemScrollController.jumpTo(
        index: index,
      );
    } else {
      print('element not there');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
  }

  void _onBackspacePressed() {
    _textEditingController
      ..text = _textEditingController.text.characters.toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _textEditingController.text.length));
  }

  void _changeDraft(newValue) {
    setState(() {
      draft = newValue;
    });
  }

  void _addEmoji(emoji) {
    setState(() {
      draft += emoji;
    });
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

  void addMsgToUI(MessageModel message) {
    // _focusNode.unfocus();
    _emojiShowing = false;
    _message.add(
      ChatMessage(
        id: message.id,
        sender: message.sender,
        chatID: message.chatID,
        message: message.message,
        dateTime: message.date,
        time: message.time,
        isMe: message.isMe,
        status: message.status,
        type: message.type,
        size: message.size,
        filePath: message.filePath,
        decibels: message.decibels,
        scrollTo: _scrollToIndex,
        repliedToId: message.repliedToId,
      ),
    );
    Provider.of<RepliedMessage>(context, listen: false).clear();
    _textEditingController.clear();
    _changeDraft('');
  }

  void _addMessage() async {
    final chat = widget.chat;

    final String msg = draft.trimLeft().replaceFirst(RegExp('^\\n+'), '');

    if (msg != '') {
      final message = await chat.sendYourMessage(
        context: context,
        msg: draft,
        type: MessageType.text,
      );
      print('went well');
      setState(() {
        addMsgToUI(message);
      });
    }
  }

  void _addFileMessage(
    MessageType type,
    String path,
    List<double> decibels,
  ) async {
    final chat = widget.chat;

    final message = await chat.sendYourMessage(
      context: context,
      msg: draft,
      type: type,
      path: path,
      decibels: decibels,
    );

    setState(() {
      addMsgToUI(message);
    });
  }

  int getMediaIndex() {
    int count = 0;
    for (ChatMessage msg in _message) {
      if (msg.type == MessageType.image || msg.type == MessageType.video) {
        count++;
      }
    }

    return count;
  }

  Future<bool> checkPathExists(String path) async {
    if (path.startsWith('assets')) {
      return checkAssetExists(path);
    } else {
      return checkFilePathExists(path);
    }
  }

  Future<bool> checkAssetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true; // Asset exists
    } catch (e) {
      return false; // Asset does not exist
    }
  }

  Future<bool> checkFilePathExists(String filePath) async {
    File file = File(filePath);
    return await file.exists();
  }

  Future<bool> onBackNavigation(selection) async {
    if (_emojiShowing) {
      print('Pressing back with emoji keyboard ON');
      //unfocus textField and hide emoji
      setState(() {
        _focusNode.unfocus();
        _emojiShowing = true;
      });
      return false;
    } else if (selection.selectionMode) {
      selection.quitSelectionMode();
      return false;
    } else {
      Provider.of<CurrentChat>(context, listen: false).empty();
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //place chat to current chat
      Provider.of<CurrentChat>(context, listen: false).empty();
      Provider.of<CurrentChat>(context, listen: false).addChat(widget.chat);
    });

    final userID = Provider.of<UserHiveBox>(context, listen: false).id;

    final width = MediaQuery.of(context).size.width;

    final chat = widget.chat;

    final String chatName = chat.name;
    final String lastSeen = chat.isGroup
        ? chat.getParticipantsNames(context)
        : chat.formatedLastSeen();

    final bool isGroup = chat.isGroup;
    final bool isMember = chat.isMember(userID);
    final bool isGroupAdmin = chat.isGroupAdmin(userID);
    final bool isOnlyAdmin = chat.onlyAdmins ?? false;

    
    final avatarUrl = chat.avatar;

    final hasPP = avatarUrl != 'default.png';

    MemoryImage? decodedImage;

    if (chat.avatarBuffer == null) {
      print('avatarBuffer: null');
    }

    if (chat.avatarBuffer != null && hasPP) {
      final Uint8List decodedImageBytes = base64Decode(chat.avatarBuffer!);
      decodedImage = MemoryImage(decodedImageBytes);
    }

    final CircleAvatar ppWidget;
    if (hasPP) {      
      ppWidget = CircleAvatar(
        backgroundImage: decodedImage,
        radius: 25.0,
      );
    } else {
      ppWidget = !chat.isGroup
          ? const CircleAvatar(
              backgroundImage: AssetImage('assets/images/user.png'),
              radius: 25.0,
            )
          : CircleAvatar(
              radius: 25.0,
              backgroundColor: Colors.blueGrey[200],
              child: SvgPicture.asset(
                "assets/svg/groups.svg",
                color: Colors.white,
                height: 30,
                width: 30,
              ),
            );
    }


    final String? wallPaper =
        Provider.of<ConstantAppData>(context, listen: false).wallPaper;

    Provider.of<Updater>(context, listen: false)
        .addUpdater(ChatScreen.id, updatePage);
    Provider.of<SocketIo>(context, listen: false).context = (context);

    print('refreshing chat screen');

    return Stack(
      children: [
        wallPaper == null
            ? Image.asset(
                'assets/images/BG1.jpg',
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              )
            : Image.file(
                File(wallPaper),
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.cover,
              ),
        Consumer<Selection>(
          builder: (context, selection, child) => WillPopScope(
            onWillPop: () {
              return onBackNavigation(selection);
            },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: (selection.selectionMode)
                  ? AppBar(
                      title: Text('${selection.selectedItems}'),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            // final List<MessageModel> messages =
                            //     selection.selected;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShareToPage(
                                  chat: widget.chat,
                                ),
                              ),
                            ).then(
                              (value) => setState(() {
                                selection.quitSelectionMode();
                              }),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            bool isPlural = selection.selectedItems > 1;
                            // Selection
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  !isPlural
                                      ? 'Delete this message?'
                                      : 'Delete these messages?',
                                ),
                                content: Text(
                                  !isPlural
                                      ? 'This message once deleted won\'t be ever retrived agian.'
                                      : 'These messages once deleted won\'t be ever retrived agian by you alone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      for (MessageModel cMsg
                                          in selection.selected) {
                                        widget.chat.removeMessage(cMsg);
                                        await widget.chat.save();
                                      }
                                      setState(() {
                                        selection.quitSelectionMode();
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Delete anyway'),
                                  )
                                ],
                              ),
                            ).then((data) {
                              updatePage();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            setState(() {
                              String copiedText = '';
                              for (MessageModel cMsg in selection.selected) {
                                copiedText += '\n ${cMsg.message}';
                              }
                              final data = ClipboardData(text: copiedText);
                              Clipboard.setData(data);
                              selection.quitSelectionMode();
                            });
                          },
                        ),
                      ],
                    )
                  : AppBar(
                      leadingWidth: 40,
                      titleSpacing: 0,
                      leading: IconButton(
                        onPressed: () {
                          Provider.of<CurrentChat>(context, listen: false)
                              .empty();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),
                      title: MaterialButton(
                        padding: const EdgeInsets.all(0.0),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatSetting(
                                chat: widget.chat,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Hero(
                              tag: 'cpp',
                              child: ppWidget,
                            ),
                            const SizedBox(
                              width: 10.0,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chatName,
                                  style: const TextStyle(
                                    fontSize: 20.0,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  lastSeen,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.call),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.videocam),
                          onPressed: () {},
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'View contact',
                              child: Text('View contact'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Wallpaper',
                              child: Text('Wallpaper'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'Block',
                              child: Text('Block'),
                            ),
                          ],
                          onSelected: (String value) {
                            // Handle the selected item here
                            print('Selected item: $value');
                          },
                          child: const Icon(Icons.more_vert),
                        ),
                      ],
                    ),
              body: SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Consumer<CurrentChat>(
                            builder: (context, currentChats, child) {
                              final chat = currentChats.openedChat;

                              widget.chat = chat ?? widget.chat;

                              initMessages();

                              return Positioned.fill(
                                child: ScrollablePositionedList.builder(
                                  itemScrollController: _itemScrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  reverse: true,
                                  padding: const EdgeInsets.only(
                                    bottom: 10,
                                  ),
                                  itemCount: _message.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final List<ChatMessage> messages =
                                        _message.reversed.toList();

                                    final ChatMessage currentMessage =
                                        messages[index];

                                    if (!currentMessage.isMe &&
                                        currentMessage.status !=
                                            MessageStatus.seen) {
                                      print('not yet seen');
                                      widget.chat.makeChatMessageSeen(
                                          currentMessage.id, context);
                                    }

                                    final DateTime currentDateTime =
                                        currentMessage.dateTime;

                                    if (currentMessage == messages.last) {
                                      return Column(
                                        children: [
                                          ShowDay(
                                            value: getTimeOrDate(
                                                currentDateTime, false),
                                          ),
                                          currentMessage,
                                        ],
                                      );
                                    } else if (index >= 0) {
                                      final prevDateTime =
                                          messages[index + 1].dateTime;

                                      if (!isSameDay(
                                        currentDateTime,
                                        prevDateTime,
                                      )) {
                                        return Column(
                                          children: [
                                            ShowDay(
                                              value: getTimeOrDate(
                                                currentDateTime,
                                                false,
                                              ),
                                            ),
                                            currentMessage,
                                          ],
                                        );
                                      } else {
                                        return currentMessage;
                                      }
                                    } else {
                                      return currentMessage;
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    isGroup && !isMember
                        ? Material(
                            elevation: 10,
                            color: Colors.white,
                            child: Container(
                              padding: EdgeInsets.all(20.0),
                              width: width,
                              child: const Text(
                                'Only memebers can communicate in this group',
                                style: TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          )
                        : isGroup && !isGroupAdmin && isOnlyAdmin
                            ? Material(
                                elevation: 10,
                                color: Colors.white,
                                child: Container(
                                  padding: EdgeInsets.all(20.0),
                                  width: width,
                                  child: const Text(
                                    'Only admin can send messages in this group',
                                    style: TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // TextButton(
                                  //   onPressed: () {
                                  //     _scrollToIndex(0);
                                  //   },
                                  //   child: Text('Scroll'),
                                  // ),
                                  BottomTextField(
                                    draft: draft,
                                    emojiShowing: _emojiShowing,
                                    textEditingController:
                                        _textEditingController,
                                    focusNode: _focusNode,
                                    changeDraft: _changeDraft,
                                    addMessage: _addMessage,
                                    toggleEmojiPicker: _toggleEmojiPicker,
                                    addFileMessage: _addFileMessage,
                                    updatePage: updatePage,
                                  ),
                                  MyEmojiPicker(
                                    emojiShowing: _emojiShowing,
                                    onBackspacePressed: _onBackspacePressed,
                                    textEditingController:
                                        _textEditingController,
                                    draft: draft,
                                    addEmoji: _addEmoji,
                                  ),
                                ],
                              ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ShowDay extends StatelessWidget {
  final String value;
  const ShowDay({required this.value});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.blueGrey[100],
          ),
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '$value',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
