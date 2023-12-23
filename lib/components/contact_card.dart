import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({required this.chat, required this.isAdmin});
  final chat;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    String name = chat.name;
    final String email = chat.email!;
    if (chat.id == Provider.of<UserHiveBox>(context, listen: false).id)
      name = 'You';

    return ListTile(
      leading: Container(
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
            // contact.select
            //     ? Positioned(
            //         bottom: 4,
            //         right: 5,
            //         child: CircleAvatar(
            //           backgroundColor: Colors.teal,
            //           radius: 11,
            //           child: Icon(
            //             Icons.check,
            //             color: Colors.white,
            //             size: 18,
            //           ),
            //         ),
            //       )
            //     : Container(),
          ],
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          if(isAdmin)
          Container(
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: const Text(
              'admin',
              style: TextStyle(color: Colors.blue, fontSize: 12.0),
            ),
          )
        ],
      ),
      subtitle: Text(
        email,
        style: const TextStyle(
          fontSize: 13,
        ),
      ),
    );
  }
}
