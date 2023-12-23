import 'package:blue_chat_v1/api_call.dart';
import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/level_hive_box.dart';
import 'package:blue_chat_v1/classes/levels.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/screens/course_selection.dart';
import 'package:blue_chat_v1/screens/creat_course.dart';
import 'package:blue_chat_v1/screens/newgroup_members.dart';
import 'package:blue_chat_v1/screens/upload_question.dart';
import 'package:blue_chat_v1/screens/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/components/chat_box.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ChatsScreen extends StatefulWidget {
//  ChatsScreen({super.key});

  static const id = 'chats_screen';

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with SingleTickerProviderStateMixin {
  bool _selectionMode = false;
  bool _isVisible = false;
  final FocusNode _focusNode = FocusNode();
  int _selectedItemsCount = 0;
  final List<String> _selectedItems = [];
  bool _isSearching = false;
  int _currentPage = 0;
  List<Chat> searchedChats = [];
  TabController? _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController!.addListener(_handleTabChange);
    super.initState();
  }

  void _updatePage() {
    if (mounted) {
      Provider.of<CurrentChat>(context, listen: false).empty();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _tabController!.removeListener(_handleTabChange);
    super.dispose();
  }

  void _toggleSelectMode() {
    setState(() {
      _selectionMode = !_selectionMode;
    });
  }

  void _incrementSelectedItems(bool increamenting, String id) {
    if (increamenting) {
      if (_selectedItemsCount == 0) _toggleSelectMode();
      // _selectionMode=true;

      // print(_selectionMode);

      setState(() {
        _selectedItems.add(id);
        _selectedItemsCount++;
      });
    } else {
      setState(() {
        _selectedItems.remove(id);
        _selectedItemsCount--;
      });
      if (_selectedItemsCount == 0) _toggleSelectMode();

      // _selectionMode=false;
      // print(_selectionMode);
    }
    for (String items in _selectedItems) {
      print('itemNumber: $items');
    }
    // print(_selectedItems.length);
  }

  void quitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedItems.length = 0;
      _selectedItemsCount = 0;
    });
  }

  void _handleTabChange() {
    setState(() {
      quitSelectionMode();
      _currentPage = _tabController!.index;
      _isVisible = false;
      print('Tab changed to index: ${_tabController!.index}');
      if (_tabController!.indexIsChanging) {
        print(_selectedItems.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<Updater>(context, listen: false)
        .addUpdater(ChatsScreen.id, _updatePage);
    Provider.of<SocketIo>(context, listen: false).context = (context);

    return DefaultTabController(
      length: 3,
      child: WillPopScope(
        onWillPop: () async {
          if (_selectionMode) {
            quitSelectionMode();
            return false;
          } else {
            return true;
          }
        },
        child: Consumer<ChatHiveBox>(
          builder: ((context, chatBox, child) => SafeArea(
                child: Scaffold(
                  backgroundColor: Colors.grey[100],
                  body: Consumer<UserHiveBox>(builder: (context, user, child) {
                    String name = user.name;
                    print('userID: ${user.id}');
                    return Column(
                      children: [
                        Container(
                          color: !_selectionMode
                              ? Colors.blue
                              : Color.fromARGB(255, 59, 154, 250),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 25.0,
                              left: 10.0,
                              right: 10.0,
                              bottom: 0.0,
                            ),
                            child: Column(
                              children: [
                                !_selectionMode
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              name,
                                              style: kTitleStyle.copyWith(
                                                  color: Colors.white),
                                            ),
                                            Row(
                                              children: [
                                                if (_currentPage < 2)
                                                  IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        toogleSearching();
                                                      });
                                                    },
                                                    icon: const Icon(
                                                      Icons.search_rounded,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                IconButton(
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      UserSettings.id,
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.settings,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              IconButton(
                                                padding: const EdgeInsets.only(
                                                    right: 35),
                                                onPressed: () {
                                                  quitSelectionMode();
                                                },
                                                icon: const Icon(
                                                  Icons.arrow_back,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                '$_selectedItemsCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title: const Text(
                                                        'Delete this chat?',
                                                      ),
                                                      content: const Text(
                                                          'This will also delete all the media files you sent to this user!'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: const Text(
                                                              'Cancel'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            for (String id
                                                                in _selectedItems) {
                                                              chatBox.emptyChat(
                                                                  id);
                                                            }
                                                            quitSelectionMode();
                                                            // _selectionMode = false;
                                                            setState(() {});
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: const Text(
                                                            'Delete anyway',
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {},
                                                icon: const Icon(
                                                  Icons.push_pin,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    toogleSearching();
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.search_rounded,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {},
                                                icon: const Icon(
                                                  Icons.archive,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                const SizedBox(
                                  height: 10.0,
                                ),
                                if (_currentPage < 2)
                                  AnimatedContainer(
                                    // padding: const EdgeInsets.symmetric(vertical: 20.0),
                                    duration: const Duration(milliseconds: 0),
                                    height: _isVisible ? 50 : 0,
                                    child: Visibility(
                                      visible: _isVisible,
                                      child: TextField(
                                        focusNode: _focusNode,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        cursorColor: Colors.white,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          isCollapsed: true,
                                          fillColor: Colors.white,
                                          hoverColor: Colors.black,
                                          prefixIcon: IconButton(
                                            padding: const EdgeInsets.only(
                                                right: 20.0),
                                            onPressed: () {
                                              setState(() => toogleSearching());
                                            },
                                            icon: const Icon(Icons.arrow_back),
                                          ),
                                          prefixIconColor: Colors.white,
                                          hintText: 'Search a Chat.',
                                          hintStyle: const TextStyle(
                                              color: Colors.white30),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 0.0,
                                            horizontal: 0.0,
                                          ),
                                          disabledBorder:
                                              const UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.transparent,
                                                width: 0.0),
                                          ),
                                          border: const UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.transparent,
                                                width: 0.0),
                                          ),
                                          enabledBorder:
                                              const UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.transparent,
                                                width: 0.0),
                                          ),
                                          focusedBorder:
                                              const UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.transparent,
                                                width: 1.0),
                                          ),
                                        ),
                                        onChanged: (newValue) {
                                          searchChat(newValue);
                                          print(newValue);
                                        },
                                      ),
                                    ),
                                  ),
                                !_isVisible
                                    ? TabBar(
                                        indicatorColor: Colors.lightBlueAccent,
                                        labelPadding: const EdgeInsets.only(
                                          top: 10.0,
                                          bottom: 10.0,
                                        ),
                                        indicatorWeight: 4.0,
                                        controller: _tabController,
                                        tabs: const <Widget>[
                                          Tab(text: 'Chats', height: 20.0),
                                          Tab(text: 'Groups', height: 20.0),
                                          Tab(
                                              text: 'Past Questions',
                                              height: 20.0),
                                        ],
                                      )
                                    : const SizedBox(
                                        height: 10.0,
                                      ),
                              ],
                            ),
                          ),
                        ),
                        Consumer<ChatHiveBox>(
                          builder: (context, chatHive, child) {
                            return Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: <Widget>[
                                  (chatHive.hasChat() && !_isSearching) ||
                                          (searchedChats.isNotEmpty &&
                                              _isSearching)
                                      ? ListView.builder(
                                          padding: const EdgeInsets.all(0),
                                          itemCount: _isSearching
                                              ? searchedChats.length
                                              : chatHive.getChats().length,
                                          itemBuilder: (context, index) {
                                            final chat = _isSearching
                                                ? searchedChats[index]
                                                : chatHive.getChats()[index];
                                            final prevChat =
                                                _isSearching && index > 0
                                                    ? searchedChats[index - 1]
                                                    : null;
                                            if (!chat.isGroup &&
                                                (!chat.isAsearch! ||
                                                    (chat.isAsearch! &&
                                                        _isSearching))) {
                                              final unReadMsgs =
                                                  chat.getUnreadMessages();

                                              dynamic lastMessage;

                                              String msg;

                                              String lastMsgTime;
                                              bool isMe;
                                              MessageStatus? mess;

                                              if (chat.messages.isEmpty) {
                                                lastMessage = '';
                                                msg = '';
                                                isMe = false;
                                                lastMsgTime = '';
                                              } else {
                                                lastMessage =
                                                    chat.messages.last;
                                                msg =
                                                    chat.messages.last.message;
                                                lastMsgTime = getTimeOrDate(
                                                    chat.messages.last.date,
                                                    true);
                                                isMe = chat.messages.last.isMe;
                                                mess =
                                                    chat.messages.last.status;
                                              }

                                              final chatBoxWidget = ChatBox(
                                                id: chat.id,
                                                avatarURL: chat.avatar,
                                                name: chat.name,
                                                isMe: isMe,
                                                unreadNumber: unReadMsgs,
                                                lastMessage: msg,
                                                lastMessageType:
                                                    chat.messages.isEmpty
                                                        ? null
                                                        : lastMessage.type,
                                                isSelected: _selectedItems
                                                    .contains(chat.id),
                                                lastMessageDate: lastMsgTime,
                                                lastMessageStatus: mess,
                                                selectionMode: _selectionMode,
                                                selectedItems: _selectedItems,
                                                updatePage: _updatePage,
                                                incrementSelectedChats:
                                                    _incrementSelectedItems,
                                              );

                                              if (chat.isAsearch! &&
                                                  (index == 0 ||
                                                      (prevChat != null &&
                                                          !prevChat
                                                              .isAsearch!))) {
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      color: Colors.grey[300],
                                                      child: const Text(
                                                        'Searched Online',
                                                        style: TextStyle(
                                                          color: Colors.black45,
                                                          fontSize: 16.0,
                                                        ),
                                                      ),
                                                    ),
                                                    chatBoxWidget,
                                                  ],
                                                );
                                              }

                                              return chatBoxWidget;
                                            }
                                            return null;
                                          },
                                        )
                                      : const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'No chat found',
                                              style: TextStyle(
                                                color: Colors.black38,
                                                fontSize: 20.0,
                                              ),
                                            )
                                          ],
                                        ),
                                  (chatHive.hasGroup() && !_isSearching) ||
                                          (searchedChats.isNotEmpty &&
                                              _isSearching)
                                      ? ListView.builder(
                                          padding: const EdgeInsets.all(0),
                                          itemCount: _isSearching
                                              ? searchedChats.length
                                              : chatHive.getGroups().length,
                                          itemBuilder: (context, index) {
                                            final chat = _isSearching
                                                ? searchedChats[index]
                                                : chatHive.getGroups()[index];

                                            if (chat.isGroup &&
                                                (!chat.isAsearch! ||
                                                    (chat.isAsearch! &&
                                                        _isSearching))) {
                                              final unReadMsgs =
                                                  chat.getUnreadMessages();

                                              dynamic lastMessage;

                                              String msg;

                                              String lastMsgTime;

                                              bool isMe;
                                              MessageStatus? status;

                                              if (chat.messages.isEmpty) {
                                                lastMessage = '';
                                                msg = '';
                                                isMe = false;
                                                lastMsgTime = '';
                                              } else {
                                                lastMessage =
                                                    chat.messages.last;
                                                msg =
                                                    chat.messages.last.message;
                                                lastMsgTime = getTimeOrDate(
                                                    chat.messages.last.date,
                                                    true);
                                                isMe = chat.messages.last.isMe;
                                                status =
                                                    chat.messages.last.status;
                                              }

                                              return ChatBox(
                                                id: chat.id,
                                                avatarURL: chat.avatar,
                                                name: chat.name,
                                                isMe: isMe,
                                                unreadNumber: unReadMsgs,
                                                lastMessage: msg,
                                                lastMessageType:
                                                    chat.messages.isEmpty
                                                        ? null
                                                        : lastMessage.type,
                                                lastMessageDate: lastMsgTime,
                                                lastMessageStatus: status,
                                                isSelected: _selectedItems
                                                    .contains(chat.id),
                                                selectionMode: _selectionMode,
                                                selectedItems: _selectedItems,
                                                updatePage: _updatePage,
                                                incrementSelectedChats:
                                                    _incrementSelectedItems,
                                              );
                                            }
                                            return null;
                                          },
                                        )
                                      : const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'No chat found',
                                              style: TextStyle(
                                                color: Colors.black38,
                                                fontSize: 20.0,
                                              ),
                                            )
                                          ],
                                        ),
                                  QuestionPage(),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }),
                  floatingActionButton: _currentPage < 2
                      ? FloatingActionButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupCreationScreen(),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.add,
                            size: 30.0,
                          ),
                        )
                      : null,
                ),
              )),
        ),
      ),
    );
  }

  void toogleSearching() {
    _isVisible = !_isVisible;
    if (_isVisible) {
      _focusNode.requestFocus();
      _isSearching = true;
      searchedChats = _currentPage == 0
          ? Provider.of<ChatHiveBox>(
              context,
              listen: false,
            ).getChats()
          : Provider.of<ChatHiveBox>(
              context,
              listen: false,
            ).getGroups();
    } else {
      _focusNode.unfocus();
      _isSearching = false;
    }
  }

  void searchChat(String newValue) async {
    await searchChats(context: context, name: newValue);

    final chats = _currentPage == 0
        ? Provider.of<ChatHiveBox>(
            context,
            listen: false,
          ).getChats()
        : Provider.of<ChatHiveBox>(
            context,
            listen: false,
          ).getGroups();

    /// Search for names in db
    searchedChats = chats
        .where(
            (chat) => chat.name.toLowerCase().contains(newValue.toLowerCase()))
        .toList();

    /// Sort by placing searched cats below the normal once
    searchedChats.sort((a, b) {
      if (a.isAsearch == null || a.isAsearch == false) {
        return -1;
      }
      return 1;
    });

    setState(() {});
  }
}

class QuestionPage extends StatelessWidget {
  const QuestionPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UploadQuestion(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.upload_file_rounded,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  const Text('upload question'),
                ],
              ),
              const SizedBox(
                width: 50.0,
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateCourse(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  const Text('create course'),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: Text(
              'Select your level',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<LevelHiveBox>(builder: (context, levelBox, child) {
            return Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    topRight: Radius.circular(15.0),
                  ),
                ),
                margin: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 30.0,
                ),
                child: Theme(
                  data: ThemeData().copyWith(dividerColor: Colors.transparent),
                  child: FutureBuilder<List<Level>?>(
                      future: levelBox.getAllLevels,
                      builder: (context, snapshot) {
                        List<Level> levels = [];
                        if (snapshot.connectionState ==
                            ConnectionState.waiting && levelBox.isEmpty) {
                          return const Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            ],
                          ); // Show a loading indicator.
                        } else if(!levelBox.isEmpty){
                          levels = levelBox.getAllLevelsSync;
                        }else{
                          levels = snapshot.data!;
                        }
                        
                          return ListView(
                            padding: const EdgeInsets.all(10),
                            children: levels.map((level) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ExpansionTile(
                                    onExpansionChanged: (isExpanded) {
                                      print(isExpanded);
                                    },
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.transparent,
                                      child: SvgPicture.asset(
                                        'assets/svg/bookmark.svg',
                                        width: 20.0,
                                      ),
                                    ),
                                    title: Text(
                                      'Level ${level.value}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    children: [
                                      ListTile(
                                        title: const Text(
                                          '1st Semester',
                                        ),
                                        onTap: () async {
                                          try {
                                            await getLevelCourses(
                                              context: context,
                                              level: level.value,
                                              semester: 'first',
                                            );

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CourseSelectionScreen(
                                                  courses: level.semester1,
                                                  level: level.value,
                                                  semester: 'first',
                                                ),
                                              ),
                                            );
                                            print(
                                                'Navigate to level ${level.value} 1st semester courses.');
                                          } on Exception catch (e) {
                                            print(e);
                                          }
                                        },
                                        trailing: const Icon(Icons.arrow_right),
                                      ),
                                      ListTile(
                                        title: const Text('2nd Semester'),
                                        onTap: () async {
                                          try {
                                            await getLevelCourses(
                                              context: context,
                                              level: level.value,
                                              semester: 'second',
                                            );

                                            // ignore: use_build_context_synchronously
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CourseSelectionScreen(
                                                  courses: level.semester2,
                                                  level: level.value,
                                                  semester: 'second',
                                                ),
                                              ),
                                            );
                                            print(
                                                'Navigate to level ${level.value} 2nd semester courses.');
                                          } on Exception catch (e) {
                                            print(e);
                                          }
                                          // Navigator.push(
                                          //   context,
                                          //   MaterialPageRoute(
                                          //     builder: (context) =>
                                          //         CourseSelectionScreen(
                                          //       courses: level.semester2,
                                          //       level: level.value,
                                          //       semester: 'second',
                                          //     ),
                                          //   ),
                                          // );
                                          // print(
                                          //     'Navigate to level ${level.value} 2st semester courses.');
                                        },
                                        trailing: const Icon(
                                          Icons.arrow_right,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    height: 2,
                                    color: Colors.black12,
                                  ),
                                ],
                              );
                            }).toList(),
                          );
                        
                      }),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
