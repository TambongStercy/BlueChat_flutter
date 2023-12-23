// import 'package:chatapp/CustomUI/AvtarCard.dart';
// import 'package:chatapp/CustomUI/ButtonCard.dart';
// import 'package:chatapp/CustomUI/ContactCard.dart';
// import 'package:chatapp/Model/ChatModel.dart';
import 'package:blue_chat_v1/api_call.dart';
import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/components/search_field.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class AddGroupMembers extends StatefulWidget {
  AddGroupMembers({required this.group});

  final Chat group;

  @override
  _AddGroupMembersState createState() => _AddGroupMembersState();
}

class _AddGroupMembersState extends State<AddGroupMembers> {
  List<ChatModel> contacts = [];

  final FocusNode _focusNode = FocusNode();

  bool _isVisible = false;
  bool _isSearching = false;
  String draft = '';
  List<ChatModel> searchedChats = [];

  bool init = false;

  List<ChatModel> groupmember = [];

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

  @override
  Widget build(BuildContext context) {
    final List<Chat> chats = Provider.of<ChatHiveBox>(
      context,
      listen: false,
    ).getChats();

    final String userID = Provider.of<UserHiveBox>(context, listen: false).id;

    if (!init) {
      contacts = chats
          .map((chat) {
            /// Check if chat is not yet member of the group
            if ((widget.group.participants != null &&
                    !widget.group.participants!
                        .any((participant) => chat.id == participant)) ||
                widget.group.participants == null) {
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

    final name = widget.group.name;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Add participants",
              style: TextStyle(
                fontSize: 13,
              ),
            )
          ],
        ),
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
      floatingActionButton: (contacts.any((contact) => contact.select))
          ? FloatingActionButton(
              backgroundColor: Color(0xFF128C7E),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Add these contacts?'),
                      content: Text(
                          'These contacts will now be memebers of the group ${widget.group.name}'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Ok'),
                          onPressed: () async {
                            final group = widget.group;

                            List<String> newParticipants = [];
                            
                            for (ChatModel member in groupmember) {
                              final chat = member.id;
                              newParticipants.add(chat!);
                            }

                            await addGroupParticipants(
                              context: context,
                              groupId: group.id,
                              newParticipants: newParticipants,
                            );

                            int count = 0;

                            Navigator.popUntil(context, (route) {
                              return count++ == 2;
                            });
                          },
                        ),
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Icon(Icons.arrow_forward),
            )
          : null,
      body: Stack(
        children: [
          ListView.builder(
            itemCount: contacts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  height: groupmember.isNotEmpty ? 90 : 10,
                );
              }
              return (!_isSearching) ||
                      searchedChats
                          .any((chat) => chat.id == contacts[index - 1].id) ||
                      (_isSearching && draft == '')
                  ? InkWell(
                      onTap: () {
                        setState(() {
                          if (contacts[index - 1].select == true) {
                            groupmember.remove(contacts[index - 1]);
                            contacts[index - 1].select = false;
                            print('remove :${groupmember.length}');
                          } else {
                            groupmember.add(contacts[index - 1]);
                            contacts[index - 1].select = true;
                            print('added :${groupmember.length}');
                          }
                        });
                      },
                      child: NewContactCard(
                        contact: contacts[index - 1],
                      ),
                    )
                  : SizedBox();
            },
          ),
          groupmember.isNotEmpty
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      Container(
                        height: 75,
                        color: Colors.white,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: contacts.length,
                          // itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            if (contacts[index].select == true) {
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    groupmember.remove(contacts[index]);
                                    contacts[index].select = false;
                                  });
                                },
                                child: AvatarCard(
                                  chatModel: contacts[index],
                                ),
                              );
                            }
                            return Container();
                          },
                        ),
                      ),
                      const Divider(
                        thickness: 1,
                        height: 1,
                      ),
                    ],
                  ),
                )
              : Container(),
        ],
      ),
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

class AvatarCard extends StatelessWidget {
  const AvatarCard({required this.chatModel});
  final ChatModel chatModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: Colors.blueGrey[200],
                child: SvgPicture.asset(
                  "assets/svg/person.svg",
                  color: Colors.white,
                  height: 30,
                  width: 30,
                ),
              ),
              const Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 11,
                  child: Icon(
                    Icons.clear,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            chatModel.name,
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
