import 'package:blue_chat_v1/api_call.dart';
// import 'package:blue_chat_v1/classes/chat.dart';
// import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:provider/provider.dart';

class NewGroupInfo extends StatefulWidget {
  const NewGroupInfo({super.key, required this.contacts});

  final List<ChatModel> contacts;

  @override
  State<NewGroupInfo> createState() => _NewGroupInfoState();
}

class _NewGroupInfoState extends State<NewGroupInfo> {
  String groupName = '';
  String groupDescp = '';
  String avatar = '';
  @override
  Widget build(BuildContext context) {
    final contacts = widget.contacts;

    // final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Group',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF128C7E),
        onPressed: () async {
          try {
            print(groupDescp);
            print(groupName);
            List<String> participants = [];

            for (ChatModel member in contacts) {
              final chat = member.id;
              participants.add(chat!);
            }

            await createGroup(
              context: context,
              name: groupName,
              description: groupDescp,
              avatar: avatar,
              participants: participants,
            );

            int count = 0;

            // ignore: use_build_context_synchronously
            Navigator.popUntil(context, (route) {
              return count++ == 2;
            });
          } on Exception catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.done),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Padding(
          //   padding: const EdgeInsets.all(10.0),
          //   child: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       CircleAvatar(
          //         radius: 15.0,
          //       ),
          //       const SizedBox(
          //         width: 15.0,
          //       ),
          //       TextField(
          //         textAlignVertical: TextAlignVertical.center,
          //         decoration: const InputDecoration(
          //           isCollapsed: true,
          //           hintText: 'Group name here*',
          //           hintStyle: TextStyle(color: Colors.white30),
          //         ),
          //         onChanged: (newValue) {
          //           setState(() => groupName = newValue);
          //           print(newValue);
          //         },
          //       ),
          //     ],
          //   ),
          // ),
          // Padding(
          //   padding: const EdgeInsets.all(10.0),
          //   child: TextField(
          //     textAlignVertical: TextAlignVertical.center,
          //     decoration: const InputDecoration(
          //       isCollapsed: true,
          //       hintText: 'Group description here*',
          //       hintStyle: TextStyle(color: Colors.white30),
          //       // contentPadding: const EdgeInsets.symmetric(
          //       //   vertical: 0.0,
          //       //   horizontal: 0.0,
          //       // ),
          //     ),
          //     onChanged: (newValue) {
          //       setState(() => groupDescp = newValue);
          //       print(newValue);
          //     },
          //   ),
          // ),

          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 35.0,
                ),
                const SizedBox(
                  width: 15.0,
                ),
                Expanded(
                  // Wrap the TextField with Expanded
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.blueAccent,
                      hintText: 'Group name',
                      border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    onChanged: (newValue) {
                      setState(() => groupName = newValue);
                      print(groupName);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Expanded(
              // Wrap the TextField with Expanded
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.blueAccent,
                  hintText: 'Group description',
                  border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(50)),
                ),
                onChanged: (newValue) {
                  setState(() => groupDescp = newValue);
                  print(groupDescp);
                },
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(1.0),
              itemCount: contacts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.0,
                crossAxisSpacing: 5.0,
                mainAxisSpacing: 5.0,
              ),
              itemBuilder: (context, index) {
                final contact = contacts[index];

                return Column(
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
                    const SizedBox(
                      height: 5.0,
                    ),
                    Text(contact.name)
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
