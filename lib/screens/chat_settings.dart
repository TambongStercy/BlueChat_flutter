import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:blue_chat_v1/api_call.dart';
import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/components/contact_card.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/screens/add_to_group.dart';
import 'package:blue_chat_v1/screens/chat_screen.dart';
import 'package:blue_chat_v1/screens/chats.dart';
import 'package:blue_chat_v1/screens/mediafiles_slider_screen.dart';
import 'package:blue_chat_v1/screens/profile_picture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ChatSetting extends StatefulWidget {
  const ChatSetting({super.key, required this.chat});

  final Chat chat;

//Notifier Providers
  // static const id = 'chat_settings';

  @override
  State<ChatSetting> createState() => _ChatSettingState();
}

class _ChatSettingState extends State<ChatSetting>
    with TickerProviderStateMixin {
  TabController? _tabController;

  final GlobalKey _thirdChildKey = GlobalKey();

  bool descExpanded = false;

  @override
  void dispose() {
    setStatusBarTextLight();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setStatusBarTextDark();
  }

  @override
  Widget build(BuildContext context) {
    setStatusBarTextDark();
    final Chat? chat =
        Provider.of<CurrentChat>(context, listen: false).openedChat;
    if (chat != null) {
      final bool isGroup =
          Provider.of<CurrentChat>(context, listen: false).openedChat!.isGroup;
      final String email =
          Provider.of<CurrentChat>(context, listen: false).openedChat!.email;
      final String name =
          Provider.of<CurrentChat>(context, listen: false).openedChat!.name;

      final String lastSeen = chat.isGroup
          ? chat.getParticipantsNames(context)
          : Provider.of<CurrentChat>(context, listen: false).lastSeen;

      final int pages = isGroup ? 4 : 3;

      _tabController =
          TabController(length: pages, vsync: this, initialIndex: 0);

      final userID = Provider.of<UserHiveBox>(context, listen: false).id;

      String description = chat.description ?? '';

      final bool isMember = chat.isMember(userID);
      final bool isGroupAdmin = chat.isGroupAdmin(userID);
      final bool isOnlyAdmin = chat.onlyAdmins ?? false;
      final avatarUrl = chat.avatar;

      final ppFile = File(avatarUrl);

      final CircleAvatar ppWidget;
      if (ppFile.existsSync()) {
        ppWidget = CircleAvatar(
          backgroundImage: FileImage(ppFile),
          radius: 60.0,
        );
      } else {
        ppWidget = !isGroup
            ? const CircleAvatar(
                backgroundImage: AssetImage('assets/images/user1.png'),
                radius: 60.0,
              )
            : CircleAvatar(
                radius: 60.0,
                backgroundColor: Colors.blueGrey[200],
                child: SvgPicture.asset(
                  "assets/svg/groups.svg",
                  color: Colors.white,
                  height: 60.0,
                  width: 60.0,
                ),
              );
      }

      return Consumer<UserHiveBox>(builder: (context, user, child) {
        final bool userIsAdmin = chat.isGroupAdmin(user.id);
        return Scaffold(
          backgroundColor: Colors.grey[200],
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Material(
                    elevation: 1.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 15.0,
                            ),
                            InkWell(
                              onTap: () {
                                setStatusBarTextLight();
                                Navigator.push(
                                  context,
                                  FadePageRoute(
                                    builder: (context) => ProfilePicture(
                                      path: avatarUrl,
                                      chatName: name,
                                      tag: 'pp',
                                    ),
                                  ),
                                ).then((value) {
                                  setState(() {});
                                });
                              },
                              child: Stack(
                                children: [
                                  Hero(
                                    tag: 'cpp',
                                    child: ppWidget,
                                  ),
                                  Hero(
                                    tag: 'pp',
                                    child: ppWidget,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 17.0,
                              ),
                            ),
                            const SizedBox(
                              height: 10.0,
                            ),
                            if (!chat.isGroup)
                              Text(
                                lastSeen,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15.0,
                                ),
                              ),
                            if (!chat.isGroup)
                              const SizedBox(
                                height: 10.0,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          final chat = widget.chat;
                                          setStatusBarTextLight();
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
                                          ).then((value) => setState(() => {}));
                                        },
                                        icon: const Icon(
                                          Icons.message,
                                          color: Colors.lightBlueAccent,
                                        ),
                                      ),
                                      const Text(
                                        'message',
                                        style: TextStyle(
                                          color: Colors.lightBlueAccent,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(width: 20.0),
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.call,
                                          color: Colors.lightBlueAccent,
                                        ),
                                      ),
                                      const Text(
                                        'call',
                                        style: TextStyle(
                                          color: Colors.lightBlueAccent,
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(width: 20.0),
                                  isGroup && userIsAdmin
                                      ? Column(
                                          children: [
                                            IconButton(
                                              iconSize: 30.0,
                                              onPressed: () {
                                                setStatusBarTextLight();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        AddGroupMembers(
                                                      group: chat,
                                                    ),
                                                  ),
                                                ).then((value) {
                                                  setState(() {});
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.add,
                                                size: 25.0,
                                                color: Colors.lightBlueAccent,
                                              ),
                                            ),
                                            const Text(
                                              'add',
                                              style: TextStyle(
                                                color: Colors.lightBlueAccent,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            IconButton(
                                              onPressed: () {},
                                              icon: const Icon(
                                                Icons.videocam_rounded,
                                                color: Colors.lightBlueAccent,
                                              ),
                                            ),
                                            Text(
                                              'video',
                                              style: TextStyle(
                                                color: Colors.lightBlueAccent,
                                              ),
                                            ),
                                          ],
                                        )
                                ],
                              ),
                            )
                          ],
                        ),
                        isGroup && userIsAdmin
                            ? PopupMenuButton<String>(
                                itemBuilder: (BuildContext context) =>
                                    const <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'Add',
                                    child: Text('Add participant'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'Desciption',
                                    child: Text('Change group desciption'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'Name',
                                    child: Text('Change group name'),
                                  ),
                                ],
                                onSelected: (String value) {
                                  if (value == 'Add') {
                                    setStatusBarTextLight();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddGroupMembers(
                                          group: chat,
                                        ),
                                      ),
                                    ).then((value) {
                                      setState(() {});
                                    });
                                  } else if (value == 'Desciption') {
                                    changeDescription(
                                        userIsAdmin, context, user, chat);
                                  } else {}
                                },
                                child: const Padding(
                                  padding:
                                      EdgeInsets.only(top: 15.0, right: 10.0),
                                  child: Icon(Icons.more_vert),
                                ),
                              )
                            : PopupMenuButton<String>(
                                itemBuilder: (BuildContext context) =>
                                    const <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'Block',
                                    child: Text('Block'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'Wallpaper',
                                    child: Text('Wallpaper'),
                                  ),
                                ],
                                onSelected: (String value) {
                                  // Handle the selected item here
                                  print('Selected item: $value');
                                },
                                child: const Padding(
                                  padding:
                                      EdgeInsets.only(top: 15.0, right: 10.0),
                                  child: Icon(Icons.more_vert),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 10.0,
                  ),
                ),
                if (isGroup)
                  SliverToBoxAdapter(
                    child: Material(
                      elevation: 1.0,
                      color: Colors.white,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            descExpanded = !descExpanded;
                          });
                        },
                        trailing: isGroupAdmin
                            ? IconButton(
                                onPressed: () {
                                  changeDescription(
                                      userIsAdmin, context, user, chat);
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.lightBlueAccent,
                                ),
                              )
                            : null,
                        title: Text(
                          description.length < 60 || descExpanded
                              ? description
                              : '${description.substring(0, 60)}...',
                        ),
                        subtitle: const Text('Description'),
                      ),
                    ),
                  ),
                if (isGroup)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 10.0,
                    ),
                  ),
                if (isGroup && isGroupAdmin)
                  SliverToBoxAdapter(
                    child: Material(
                      elevation: 1.0,
                      color: Colors.white,
                      child: ListTile(
                        onTap: () async {
                          await changeGroupOnlyAdmin(
                            context: context,
                            groupId: chat.id,
                            onlyAdmins: !isOnlyAdmin,
                          );
                          if (mounted) setState(() {});
                        },
                        title: const Text('Only admins can send messages'),
                        subtitle: Text(isOnlyAdmin ? 'ON' : 'OFF'),
                      ),
                    ),
                  ),
                if (isGroup && isGroupAdmin)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 10.0,
                    ),
                  ),
                isMember | !isGroup
                    ? SliverAppBar(
                        pinned: true,
                        toolbarHeight: 52.0,
                        backgroundColor: Colors.white,
                        leading: const SizedBox(),
                        flexibleSpace: TabBar(
                          key: _thirdChildKey,
                          labelPadding:
                              const EdgeInsets.only(top: 15.0, bottom: 10.0),
                          indicatorWeight: 5.0,
                          indicatorSize: TabBarIndicatorSize.label,
                          controller: _tabController,
                          tabs: <Widget>[
                            if (isGroup)
                              const Tab(
                                height: 20.0,
                                child: Text(
                                  'Participants',
                                  style: TextStyle(
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            const Tab(
                              height: 20.0,
                              child: Text(
                                'Media',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                            const Tab(
                              height: 20.0,
                              child: Text(
                                'Files',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                            const Tab(
                              height: 20.0,
                              child: Text(
                                'Audio',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SliverToBoxAdapter(
                        child: SizedBox(),
                      ),
                isMember || !isGroup
                    ? SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          child: ChangeNotifierProvider(
                            create: (context) => Selection(),
                            child: Consumer<CurrentChat>(
                                builder: (context, currectChats, child) {
                              final chat = currectChats.openedChat;

                              if (chat == null) {
                                return SizedBox();
                              }

                              final messages = chat.messages.where((msg) {
                                final path = msg.filePath;
                                if (path == null) {
                                  return false;
                                }
                                final file = File(msg.filePath!);
                                if (!file.existsSync()) {
                                  return false;
                                }

                                if (file.lengthSync() < msg.size!) {
                                  return false;
                                }

                                return true;
                              }).toList();
                              // print('chat: $chat');
                              final mediaMsgs = messages.map((msg) {
                                if (msg.type == MessageType.video ||
                                    msg.type == MessageType.image) {
                                  return msg;
                                }
                              }).toList();
                              mediaMsgs.removeWhere((msg) => msg == null);

                              final audioMsgs = messages.map((msg) {
                                if (msg.type == MessageType.audio ||
                                    msg.type == MessageType.voice) {
                                  return msg;
                                }
                              }).toList();
                              audioMsgs.removeWhere((msg) => msg == null);

                              final fileMsgs = messages.map((msg) {
                                if (msg.type == MessageType.files) {
                                  return msg;
                                }
                              }).toList();
                              fileMsgs.removeWhere((msg) => msg == null);

                              final List<String> participants = [];
                              final List<String> admins = [];

                              if (isGroup &&
                                  (chat.participants != null &&
                                      chat.participants != [])) {
                                for (String chatID in chat.participants!) {
                                  if (userID == chatID ||
                                      chat.isGroupAdmin(chatID)) continue;

                                  participants.add(chatID);
                                }
                              }

                              if (isGroup &&
                                  (chat.adminsId != null &&
                                      chat.adminsId != [])) {
                                for (String adminId in chat.adminsId!) {
                                  if (userID == adminId) continue;
                                  admins.add(adminId);
                                }
                              }

                              print(fileMsgs);

                              return TabBarView(
                                controller: _tabController,
                                children: <Widget>[
                                  if (isGroup)
                                    Container(
                                      height: 1500.0,
                                      color: Colors.white54,
                                      child: ListView.builder(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.all(1.0),
                                        itemCount: participants.length +
                                            admins.length +
                                            1,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          final contactIndex =
                                              index > 0 ? index - 1 : 0;

                                          final Chat thisParticipant =
                                              Provider.of<ChatHiveBox>(
                                            context,
                                            listen: false,
                                          ).getChat(
                                            contactIndex < admins.length
                                                ? admins[contactIndex]
                                                : participants[contactIndex -
                                                    admins.length],
                                          )!;

                                          final user = Provider.of<UserHiveBox>(
                                            context,
                                            listen: false,
                                          );

                                          final chatIsAdmin = chat.isGroupAdmin(
                                            index > 0
                                                ? thisParticipant.id
                                                : user.id,
                                          );

                                          return InkWell(
                                            onTap: () {
                                              if (index > 0) {
                                                actionOnMember(
                                                  context,
                                                  thisParticipant,
                                                  chat,
                                                  user,
                                                ).then(
                                                  (value) => setState(() {}),
                                                );
                                              }
                                            },
                                            onLongPress: () {},
                                            child: ContactCard(
                                              chat: index > 0
                                                  ? thisParticipant
                                                  : user,
                                              isAdmin: chatIsAdmin,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  Container(
                                    height: 1500.0,
                                    color: Colors.white54,
                                    child: GridView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.all(1.0),
                                      itemCount: mediaMsgs.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 1.0,
                                        crossAxisSpacing: 1.0,
                                        mainAxisSpacing: 1.0,
                                      ),
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return MediaGrid(
                                          msg: mediaMsgs[index]!,
                                          index: index,
                                          chat: widget.chat,
                                        );
                                      },
                                    ),
                                  ),
                                  Container(
                                    color: Colors.white54,
                                    child: ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: fileMsgs.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return FileDisplay(
                                          filePath: fileMsgs[index]!.filePath!,
                                          dateTime: fileMsgs[index]!.date,
                                        );
                                      },
                                    ),
                                  ),
                                  Container(
                                    color: Colors.white54,
                                    child: ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: audioMsgs.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return Stack(
                                          children: [
                                            InkWell(
                                              onTap: () {},
                                              child: Container(
                                                color: Colors.black12,
                                                height: 100.0,
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                color: Colors.grey[700],
                                              ),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 20.0,
                                                      horizontal: 15.0),
                                              padding:
                                                  const EdgeInsets.all(5.0),
                                              child: SimpleAudioPlayer(
                                                filePath:
                                                    audioMsgs[index]!.filePath!,
                                              ),
                                            ),
                                            Positioned(
                                              right: 20.0,
                                              bottom: 25.0,
                                              child: Text(
                                                getTimeOrDate(
                                                    audioMsgs[index]!.date,
                                                    true),
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      )
                    : const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 400.0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No You are not a member',
                                style: TextStyle(
                                  color: Colors.black38,
                                  fontSize: 20.0,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      });
    } else {
      return const SizedBox();
    }
  }

  Future<dynamic> actionOnMember(
    BuildContext context,
    Chat thisParticipant,
    Chat? chat,
    UserHiveBox user,
  ) {
    final chatIsAdmin = chat!.isGroupAdmin(
      thisParticipant.id,
    );
    final userIsAdmin = chat.isGroupAdmin(user.id);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 0.0,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton(
                child: Row(
                  children: [
                    const SizedBox(width: 15.0),
                    Text(
                      'Message ${thisParticipant.name.split(' ').first}',
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
                onPressed: () {
                  Chat chat = Provider.of<ChatHiveBox>(
                    context,
                    listen: false,
                  ).getChat(thisParticipant.id)!;

                  Navigator.popUntil(context, (route) {
                    if (route.settings.name == ChatsScreen.id) {
                      // navigate to selected chat screen
                      Provider.of<CurrentChat>(
                        context,
                        listen: false,
                      ).addChat(chat);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return ChatScreen(
                              chat: chat,
                            );
                          },
                          settings: const RouteSettings(
                            name: ChatScreen.id,
                          ),
                        ),
                      );

                      return true;
                    }
                    return false;
                  });
                },
              ),
              if (userIsAdmin)
                TextButton(
                  child: Row(
                    children: [
                      const SizedBox(width: 15.0),
                      Text(
                        'Remove ${thisParticipant.name}',
                      ),
                    ],
                  ),
                  onPressed: () async {
                    try {
                      final groupId = chat.id;

                      await removeGroupParticipants(
                        context: context,
                        groupId: groupId,
                        participants: [thisParticipant.id],
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      print(e);
                    }
                  },
                ),
              if (userIsAdmin)
                TextButton(
                  child: Row(
                    children: [
                      const SizedBox(width: 15.0),
                      Text(
                        'Make ${thisParticipant.name} admin',
                      ),
                    ],
                  ),
                  onPressed: () async {
                    try {
                      final groupId = chat.id;

                      await makeParticipantsAdmin(
                        context: context,
                        groupId: groupId,
                        newAdmins: [thisParticipant.id],
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      print(e);
                    }
                  },
                ),
              if (userIsAdmin && chatIsAdmin)
                TextButton(
                  child: const Row(
                    children: [
                      SizedBox(width: 15.0),
                      Text(
                        'Remove from post of admin',
                      ),
                    ],
                  ),
                  onPressed: () async {
                    try {
                      final groupId = chat.id;

                      await removeParticipantsAdmin(
                        context: context,
                        groupId: groupId,
                        admins: [thisParticipant.id],
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      print(e);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void changeDescription(
      bool userIsAdmin, BuildContext context, UserHiveBox user, Chat chat) {
    userIsAdmin
        ? showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            builder: (BuildContext context) {
              return ChangeGroupDescription(
                userID: user.id,
                group: chat,
              );
            },
          ).then((value) => setState(() {}))
        : showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: const Text(
                  'Only admins can update group description',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          ).then((value) => setState(() {}));
  }
}

class ChangeGroupDescription extends StatefulWidget {
  const ChangeGroupDescription({
    super.key,
    required this.group,
    required this.userID,
  });

  final Chat group;
  final String userID;

  @override
  State<ChangeGroupDescription> createState() => _ChangeGroupDescriptionState();
}

class _ChangeGroupDescriptionState extends State<ChangeGroupDescription> {
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
    final group = widget.group;
    final groupId = group.id;
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
          Text(
            'Enter new description for ${widget.group.name}',
            style: const TextStyle(
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
                  maxLines: 5,
                  minLines: 1,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  controller: _editingController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Description...',
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
              final description = _editingController.value.text;

              changeGroupDescription(
                  context: context, groupId: groupId, description: description);

              Navigator.pop(context);
            },
            child: const Text(
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


class MediaGrid extends StatefulWidget {
  MediaGrid({required this.msg, required this.chat, required this.index});

  final MessageModel msg;
  final int index;
  final Chat chat;

  @override
  State<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends State<MediaGrid> {
  String? thumbnailPath;

  @override
  void initState() {
    super.initState();
    if (widget.msg.type == MessageType.video) {
      generateThumbnail();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> generateThumbnail() async {
    final path = widget.msg.filePath ?? '';

    try {
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: kTempDirectory.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 1000, // specify a higher height for better quality
        quality: 100, // set to maximum quality
      );

      setState(() {
        thumbnailPath = thumbPath;
      });
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }


  Widget getContent() {
    if (widget.msg.type == MessageType.image) {
      return Hero(
        tag: 'chatImage ${widget.msg.id}',
        child: Container(
          color: Colors.black,
          child: Image.file(
            File(widget.msg.filePath!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (widget.msg.type == MessageType.video) {
      return Hero(
        tag: 'chatImage ${widget.msg.id}',
        child: Container(
          color: Colors.black,
          child: thumbnailPath != null
              ? Image.file(
                  File(thumbnailPath!),
                  fit: BoxFit.cover,
                )
              : Container(),
        ),
      );
    } else {
      return Container(color: Colors.black);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!Provider.of<Selection>(context, listen: false).selectionMode) {
          setStatusBarTextLight();
          Navigator.push(
            context,
            FadePageRoute(
              builder: (context) => ImageSliderPage(
                initialIndex: widget.index,
                chat: widget.chat,
              ),
            ),
          );
        }
      },
      child: getContent(),
    );
  }
}

class FileDisplay extends StatelessWidget {
  FileDisplay({required this.filePath, required this.dateTime});

  final String filePath;
  final DateTime dateTime;

  void openFile(String path) {
    OpenFile.open(path);
  }

  @override
  Widget build(BuildContext context) {
    final File file = File(filePath);

    final path = file.path;

    final fileName = file.path.split('/').last;

    final name =
        fileName.length <= 45 ? fileName : '${fileName.substring(0, 45)}...';

    final fileExtension = fileName.split('.').last;

    final mimeType = lookupMimeType(file.path);

    String type = mimeType != null ? mimeType.split('/').last : fileExtension;

    type = type.length > 3 ? 'BIN' : type;

    final int fileSize = file.lengthSync();

    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          InkWell(
            onTap: () {},
            child: Container(
              color: Colors.black12,
              height: 100.0,
            ),
          ),
          GestureDetector(
            onTap: () {
              openFile(path);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.grey[700],
              ),
              margin:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
              padding: const EdgeInsets.all(5.0),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.blueGrey[800]),
                    alignment: Alignment.center,
                    height: 45.0,
                    width: 35.0,
                    child: Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 180,
                        child: Text(
                          '${name}',
                          softWrap: true,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Text(
                        formatFileSize(fileSize),
                        style: TextStyle(color: Colors.white38),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Positioned(
            right: 20.0,
            bottom: 25.0,
            child: Text(
              getTimeOrDate(dateTime, true),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleAudioPlayer extends StatefulWidget {
  SimpleAudioPlayer({
    required this.filePath,
    this.decibels,
  });

  final String filePath;
  final List<double>? decibels;

  @override
  State<SimpleAudioPlayer> createState() => _SimpleAudioPlayerState();
}

class _SimpleAudioPlayerState extends State<SimpleAudioPlayer> {
  AudioPlayer audioPlayer = AudioPlayer();

  late StreamSubscription<PlayerState> playerStateSubscription;
  late StreamSubscription<Duration> durationSubscription;
  late StreamSubscription<Duration> positionSubscription;
  late StreamSubscription<void> playerCompleteSubscription;

  bool isPlaying = false;
  Duration audioDuration = Duration.zero;
  Duration audioPosition = Duration.zero;
  int secondsPlayed = 0;

  void initAudioPlayer() async {
    final path = widget.filePath;

    audioPlayer.setReleaseMode(ReleaseMode.stop);
    audioPlayer.setSourceDeviceFile(path);

    playerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    durationSubscription = audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          audioDuration = newDuration;
          secondsPlayed = newDuration.inSeconds;
        });
      }
    });

    positionSubscription = audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          audioPosition = newPosition;
          secondsPlayed = newPosition.inSeconds;
        });
      }
    });

    playerCompleteSubscription = audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          secondsPlayed = audioDuration.inSeconds;
        });
      }
    });
  }

  @override
  void initState() {
    initAudioPlayer();
    super.initState();
  }

  @override
  void dispose() {
    disposeAudioPlayer();
    super.dispose();
  }

  void disposeAudioPlayer() {
    playerStateSubscription.cancel();
    durationSubscription.cancel();
    positionSubscription.cancel();
    playerCompleteSubscription.cancel();

    audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<double>? decibels = widget.decibels;

    decibels = decibels ?? [];

    final bool isDecibeled = decibels.isNotEmpty;
    int index = 0;
    return Padding(
      padding: const EdgeInsets.only(left: 3.0, top: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.teal,
                size: 35.0,
              ),
              onPressed: () async {
                if (isPlaying) {
                  await audioPlayer.pause();
                } else {
                  await audioPlayer.resume();
                }
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      isDecibeled
                          ? Padding(
                              padding: const EdgeInsets.only(left: 9.0),
                              child: Row(
                                children: decibels.map((double decibel) {
                                  index = decibels!.indexOf(decibel) == 0
                                      ? 0
                                      : index;

                                  final duration = audioDuration.inMicroseconds;

                                  double position = isPlaying || duration > 0
                                      ? (audioPosition.inMicroseconds /
                                              audioDuration.inMicroseconds) *
                                          45
                                      : 0;

                                  int decibelIndex = index;
                                  index++;
                                  int currentIndex = position.floor();

                                  double colorRatio = position - currentIndex;

                                  double value;
                                  if (decibel < 15) {
                                    value = 15;
                                  } else if (decibel > 55) {
                                    value = 55;
                                  } else {
                                    value = decibel;
                                  }
                                  final double height = ((value.abs() - 15) *
                                          (3 / 4)) +
                                      5; // Scale the decibel value to the height range of 0-100 pixels
                                  double width = 0;

                                  if (decibelIndex < currentIndex) {
                                    width = 3.0;
                                  } else if (decibelIndex > currentIndex) {
                                    width = 0;
                                  } else {
                                    width = colorRatio * 3;
                                  }

                                  return Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 0.5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                        ),
                                        height: height,
                                        width: 3.0,
                                        // child:
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                        ),
                                        height: height,
                                        width: width,
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            )
                          : const SizedBox(),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 7.0,
                            right: 4.0,
                            bottom: 10.0,
                            left: (isDecibeled ? 0 : 5.0)),
                        child: Opacity(
                          opacity: isDecibeled ? 0 : 1,
                          child: SliderTheme(
                            data: SliderThemeData(
                                overlayShape: SliderComponentShape.noOverlay,
                                thumbColor: Colors.green,
                                thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: isDecibeled ? 10 : 5),
                                valueIndicatorColor: Colors.lightGreenAccent,
                                activeTrackColor: Colors.lightBlueAccent,
                                trackShape: const RectangularSliderTrackShape(),
                                // trackShape: SliderTrackShape.,
                                // overlayColor: Colors.white,
                                // tickMarkShape: SliderTickMarkShape.noTickMark,
                                trackHeight: 3.0),
                            child: Slider(
                              min: 0,
                              max: audioDuration.inMilliseconds.toDouble() /
                                  1000,
                              value: audioPosition.inMilliseconds.toDouble() /
                                  1000,
                              onChanged: (value) async {
                                final position = Duration(
                                    milliseconds: (value * 1000).toInt());
                                await audioPlayer.seek(position);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      getFormattedTime(isPlaying
                          ? audioPosition.inSeconds
                          : audioDuration.inSeconds),
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 15.0),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
