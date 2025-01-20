import 'dart:io';

import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/providers/socket_io.dart';
import 'package:blue_chat_v1/screens/chat_settings.dart';
import 'package:blue_chat_v1/screens/profile_picture.dart';
import 'package:flutter/material.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/screens/chat_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ChatBox extends StatefulWidget {
  // final Function<void> onPress
  final String id;
  bool isSelected;
  final bool selectionMode;
  final List<String> selectedItems;
  final String avatarURL;
  final String name;
  final int unreadNumber;
  final String lastMessage;
  final bool isMe;
  final MessageStatus? lastMessageStatus;
  final String lastMessageDate;
  final Function incrementSelectedChats;
  final MessageType? lastMessageType;
  final Function updatePage;

  ChatBox({
    required this.id,
    required this.avatarURL,
    required this.name,
    required this.unreadNumber,
    required this.lastMessage,
    required this.lastMessageDate,
    required this.selectionMode,
    required this.selectedItems,
    required this.incrementSelectedChats,
    required this.updatePage,
    required this.lastMessageStatus,
    required this.isMe,
    this.lastMessageType,
    required this.isSelected,
  });

  @override
  State<ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<ChatBox>
    with AutomaticKeepAliveClientMixin<ChatBox> {
  @override
  bool get wantKeepAlive => true;

  Color? bgColor = Colors.white;

  @override
  void initState() {
    super.initState();
  }

  void _toggleSelectState() {
    bool selected = widget.isSelected;

    setState(() {
      selected = !selected;
      if (selected) {
        bgColor = Colors.blue[50];
      } else {
        bgColor = Colors.white;
      }
      widget.isSelected = selected;
      // print('selected: $_selected');
      widget.incrementSelectedChats(selected, widget.id);
    });
  }

  bool _isModalVisible = false;

  String get chatID => widget.id;

  void _toggleModal() {
    setState(() {
      _isModalVisible = !_isModalVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.isSelected) {
      bgColor = Colors.blue[50];
    } else {
      bgColor = Colors.white;
    }

    if (!widget.selectionMode) {
      bgColor = Colors.white;
      widget.isSelected = false;
    }

    int number = widget.unreadNumber >= 999 ? 999 : widget.unreadNumber;

    String msg = widget.lastMessage.replaceAll('\n', '').trimLeft();

    if (msg.length > 23) {
      msg = '${msg.substring(0, 23)}...';
    }

    final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

    final chat = chatBox.getChat(chatID)!;

    final isTyping = chat.isTyping ?? false;
    msg = isTyping ? 'Typing...' : msg;

    final avatarUrl = chat.avatar;

    final ppFile = File(avatarUrl);

    final CircleAvatar ppWidget;
    if (ppFile.existsSync()) {
      ppWidget = CircleAvatar(
        backgroundImage: FileImage(ppFile),
        radius: 23.0,
      );
    } else {
      ppWidget = !chat.isGroup
          ? const CircleAvatar(
              backgroundImage: AssetImage('assets/images/user.png'),
              radius: 23.0,
            )
          : CircleAvatar(
              radius: 23,
              backgroundColor: Colors.blueGrey[200],
              child: SvgPicture.asset(
                "assets/svg/groups.svg",
                color: Colors.white,
                height: 30,
                width: 30,
              ),
            );
    }

    final Widget unreadCircle = widget.unreadNumber != 0
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: const Color.fromRGBO(18, 255, 176, 1),
            ),
            margin: const EdgeInsets.only(top: 5.0),
            padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 5.0),
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 13.0, color: Colors.white),
            ),
          )
        : const SizedBox(
            height: 25.0,
          );

    final IconData? icon;
    final IconData? icon2;

    switch (widget.lastMessageType) {
      case MessageType.image:
        icon = Icons.image;
        break;
      case MessageType.video:
        icon = Icons.videocam;
        break;
      case MessageType.audio:
        icon = Icons.headphones_rounded;
        break;
      case MessageType.voice:
        icon = Icons.headphones_rounded;
        break;
      case MessageType.files:
        icon = Icons.file_present_rounded;
        break;
      default:
        icon = null;
        break;
    }

    switch (widget.lastMessageStatus) {
      // switch (MessageStatus.seen) {
      case MessageStatus.sending:
        icon2 = Icons.access_time_outlined;
        break;
      case MessageStatus.sent:
        icon2 = Icons.check;
        break;
      case MessageStatus.received:
        icon2 = Icons.done_all_rounded;
        break;
      case MessageStatus.seen:
        icon2 = Icons.done_all_rounded;
        break;
      default:
        icon2 = null;
        break;
    }

    final tag = 'box ${widget.id}';

    return MaterialButton(
      onPressed: () async {
        if (!widget.selectionMode) {
          Provider.of<SocketIo>(context, listen: false)
              .requestChatStatus(chat.id);

          Provider.of<CurrentChat>(context, listen: false).addChat(chat);
          Navigator.push(
            context,
            SlideRightToLeftPageRoute(
              builder: (context) => ChatScreen(
                chat: chat,
              ),
              routeSettings: RouteSettings(
                name: ChatScreen.id,
              ),
            ),
          ).then((data) {
            widget.updatePage();
          });
        } else {
          _toggleSelectState();
        }
      },
      onLongPress: () {
        if (!widget.selectionMode) {
          HapticFeedback.vibrate();
          _toggleSelectState();
        } else {
          _toggleSelectState();
        }
      },
      elevation: 0,
      color: bgColor,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (!widget.selectionMode) {
                      Chat chat =
                          Provider.of<ChatHiveBox>(context, listen: false)
                              .getChat(widget.id)!;

                      Navigator.push(
                        context,
                        HeroDialogRoute(
                          builder: (BuildContext context) => ShowProfile(
                            tag: tag,
                            chat: chat,
                            updatePage: widget.updatePage,
                          ),
                        ),
                      );
                    } else {
                      _toggleSelectState();
                    }
                  },
                  child: Stack(
                    children: [
                      ppWidget,
                      Hero(
                        tag: tag,
                        child: ppWidget,
                      ),
                      if (widget.isSelected)
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.teal,
                            radius: 11,
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10.0,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          // color: Colors.black54,
                        ),
                      ),
                      const SizedBox(
                        height: 4.0,
                      ),
                      Row(
                        children: [
                          icon2 != null && widget.isMe
                              ? Icon(
                                  icon2,
                                  color: widget.lastMessageStatus ==
                                          MessageStatus.seen
                                      ? Colors.blue
                                      : Colors.grey,
                                  size: 20.0,
                                )
                              : const SizedBox(),
                          const SizedBox(
                            width: 3,
                          ),
                          icon != null
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Icon(icon,
                                      color: Colors.black54, size: 20.0),
                                )
                              : const SizedBox(),
                          Text(
                            msg,
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    unreadCircle,
                    const SizedBox(
                      height: 15.0,
                    ),
                    Text(
                      widget.lastMessageDate,
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(
            thickness: 1,
            height: 1,
          ),
        ],
      ),
    );
  }
}

class ShowProfile extends StatefulWidget {
  final String tag;
  final Chat chat;
  final Function updatePage;

  const ShowProfile({
    super.key,
    required this.tag,
    required this.chat,
    required this.updatePage,
  });

  @override
  State<ShowProfile> createState() => _ShowProfileState();
}

class _ShowProfileState extends State<ShowProfile> {
  Chat get chat => widget.chat;

  @override
  Widget build(BuildContext context) {
    final String name = chat.name;
    final bool isGroup = chat.isGroup;
    final avatarUrl = chat.avatar;

    final ppFile = File(avatarUrl);

    final Widget ppWidget;
    if (ppFile.existsSync()) {
      ppWidget = Image.file(
        ppFile,
        fit: BoxFit.contain,
      );
    } else {
      ppWidget = !isGroup
          ? Image.asset(
              'assets/images/user1.png',
              fit: BoxFit.contain,
            )
          : CircleAvatar(
              radius: 150,
              backgroundColor: Colors.blueGrey[200],
              child: SvgPicture.asset(
                "assets/svg/groups.svg",
                color: Colors.white,
                height: 150,
                width: 150,
              ),
            );
    }

    return Align(
      alignment: Alignment.center,
      child: Stack(
        children: [
          Hero(
            tag: widget.tag,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 300.0,
                height: 360.0,
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            FadePageRoute(
                              builder: (context) => ProfilePicture(
                                path: avatarUrl,
                                chatName: name,
                                tag: widget.tag,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          color: Colors.black,
                          width: 300.0,
                          height: 300.0,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                FadePageRoute(
                                  builder: (context) => ProfilePicture(
                                    path: avatarUrl,
                                    chatName: name,
                                    tag: widget.tag,
                                  ),
                                ),
                              );
                            },
                            child: ppWidget,
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Colors.blue.shade50,
                    ),
                    Expanded(
                      child: SizedBox(
                        width: 300.0,
                        child: Container(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 5,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: IconButton(
                                    onPressed: () {
                                      Chat chat = Provider.of<ChatHiveBox>(
                                        context,
                                        listen: false,
                                      ).getChat(widget.chat.id)!;

                                      Navigator.push(
                                        context,
                                        SlideRightToLeftPageRoute(
                                          builder: (context) => ChatScreen(
                                            chat: chat,
                                          ),
                                          routeSettings: RouteSettings(
                                            name: ChatScreen.id,
                                          ),
                                        ),
                                      ).then((data) {
                                        print('back to chats');
                                        widget.updatePage();
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.message,
                                      color: Colors.lightBlueAccent,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.lightBlueAccent,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.videocam_rounded,
                                      color: Colors.lightBlueAccent,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: IconButton(
                                    onPressed: () {
                                      Chat chat = Provider.of<ChatHiveBox>(
                                        context,
                                        listen: false,
                                      ).getChat(widget.chat.id)!;

                                      print('Chat\'s Settings');

                                      Provider.of<CurrentChat>(context,
                                              listen: false)
                                          .addChat(chat);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatSetting(
                                            chat: chat,
                                          ),
                                        ),
                                      ).then((data) {
                                        print('back to chats');
                                        widget.updatePage();
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.info_outline,
                                      color: Colors.lightBlueAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeroDialogRoute<T> extends PageRoute<T> {
  HeroDialogRoute({required this.builder}) : super();

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  bool get maintainState => true;

  @override
  Color get barrierColor => Colors.black54;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return new FadeTransition(
        opacity: new CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child);
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  String? get barrierLabel => null;
}
