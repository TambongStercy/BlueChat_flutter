import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/components/search_field.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/screens/chats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ShareToPage extends StatefulWidget {
  const ShareToPage({super.key, required this.chat});

  final Chat chat;

  @override
  State<ShareToPage> createState() => _ShareToPageState();
}

class _ShareToPageState extends State<ShareToPage> {
  List<ChatModel> contacts = [];

  final FocusNode _focusNode = FocusNode();

  bool _isVisible = false;
  bool _isSearching = false;
  String draft = '';
  List<ChatModel> searchedChats = [];

  bool init = false;

  List<ChatModel> selectedChats = [];

  String names = '';

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void toogleSearching() {
    _isVisible = !_isVisible;
    draft = '';
    if (_isVisible) {
      _focusNode.requestFocus();
      _isSearching = true;
    } else {
      _focusNode.unfocus();
      _isSearching = false;
    }
  }

  void searchChat(String newValue) {
    draft = newValue;
    searchedChats = contacts
        .where((contact) =>
            contact.name.toLowerCase().contains(newValue.toLowerCase()))
        .toList();
    // setState(() {});
  }

  void forwardMessages(context) async {
    final selectedMessage =
        Provider.of<Selection>(context, listen: false).selected;

    print('selected messages: ${selectedMessage.length}');

    for (ChatModel member in selectedChats) {
      final chat = Provider.of<ChatHiveBox>(
        context,
        listen: false,
      ).getChat(member.id!)!;

      for (MessageModel msg in selectedMessage) {
        await chat.sendYourMessage(
          context: context,
          msg: msg.message,
          type: msg.type,
          path: msg.filePath,
          decibels: msg.decibels,
        );
      }
      await chat.save();
    }

    setState(() {});

    Navigator.popUntil(context, (route) {
      if (route.settings.name == ChatsScreen.id) {
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Chat> chats = Provider.of<ChatHiveBox>(
      context,
      listen: false,
    ).getAllChats();
    final double width = MediaQuery.of(context).size.width;

    final String userID = Provider.of<UserHiveBox>(context, listen: false).id;

    if (!init) {
      contacts = chats
          .map((chat) {
            /// Check if chat is not yet member of the group
            if (chat.isGroup &&
                    (((chat.onlyAdmins == null || !chat.onlyAdmins!) &&
                            chat.isMember(userID)) ||
                        ((chat.onlyAdmins == null || chat.onlyAdmins!) &&
                            chat.isGroupAdmin(userID))) ||
                (!chat.isGroup)) {
              return ChatModel(
                name: chat.name,
                status: chat.email,
                id: chat.id,
                avatar: chat.avatar,
              );
            } else {
              return ChatModel(name: '');
            }
          })
          .where((chat) => chat.name != '')
          .toList();
      init = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Forward to ..'),
        bottom: _isVisible
            ? AppBar(
                elevation: 0,
                leadingWidth: 0,
                leading: SizedBox(),
                title: AnimatedContainer(
                  duration: const Duration(milliseconds: 1000),
                  height: _isVisible ? 50 : 0,
                  child: Visibility(
                    visible: _isVisible,
                    child: SearchField(
                      onCancel: () {
                        setState(() {
                          toogleSearching();
                        });
                      },
                      onChanged: (newValue) {
                        setState(() {
                          searchChat(newValue);
                        });
                      },
                      focusNode: _focusNode,
                    ),
                  ),
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              size: 26,
            ),
            onPressed: () {
              setState(() {
                toogleSearching();
              });
            },
          ),
        ],
      ),
      body: Consumer<ChatHiveBox>(builder: (context, chatHive, child) {
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100.0),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            return (!_isSearching) ||
                    searchedChats
                        .any((chat) => chat.id == contacts[index].id) ||
                    (_isSearching && draft == '')
                ? InkWell(
                    onTap: () {
                      setState(() {
                        if (contacts[index].select == true) {
                          selectedChats.remove(contacts[index]);
                          contacts[index].select = false;
                          print('remove :${selectedChats.length}');
                        } else {
                          selectedChats.add(contacts[index]);
                          contacts[index].select = true;
                          print('added :${selectedChats.length}');
                        }
                        names = '';
                        for (ChatModel meb in selectedChats) {
                          if (names.length > 25) {
                            names += '${meb.name}...';

                            break;
                          }

                          names += '${meb.name}, ';
                        }
                      });
                    },
                    child: NewContactCard(
                      contact: contacts[index],
                    ),
                  )
                : const SizedBox();
          },
        );
      }),
      bottomSheet: (contacts.any((contact) => contact.select))
          ? Material(
              elevation: 1.0,
              child: Container(
                padding: const EdgeInsets.all(10.0),
                width: width,
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(names),
                    FloatingActionButton(
                      elevation: 0.5,
                      backgroundColor: const Color(0xFF128C7E),
                      onPressed: () {
                        forwardMessages(context);
                      },
                      child: const Icon(Icons.send),
                    )
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class NewContactCard extends StatelessWidget {
  const NewContactCard({required this.contact});
  final ChatModel contact;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 50,
        height: 53,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 23,
              child: SvgPicture.asset(
                "assets/svg/person.svg",
                color: Colors.white,
                height: 30,
                width: 30,
              ),
              backgroundColor: Colors.blueGrey[200],
            ),
            contact.select
                ? const Positioned(
                    bottom: 4,
                    right: 5,
                    child: CircleAvatar(
                      backgroundColor: Colors.teal,
                      radius: 11,
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
      title: Text(
        contact.name,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        contact.status!,
        style: TextStyle(
          fontSize: 13,
        ),
      ),
    );
  }
}

class ChatModel {
  String name;
  String? avatar;
  bool? isGroup;
  String? time;
  String? currentMessage;
  String? status;
  bool select = false;
  String? id;
  ChatModel({
    required this.name,
    this.avatar,
    this.isGroup,
    this.time,
    this.currentMessage,
    this.status,
    this.select = false,
    this.id,
  });
}
