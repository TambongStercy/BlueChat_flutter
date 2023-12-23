import 'dart:io';

import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/screens/account_setting.dart';
import 'package:blue_chat_v1/screens/display_settings.dart';
import 'package:blue_chat_v1/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserSettings extends StatelessWidget {
  static const String id = 'user_settings';
  const UserSettings({super.key});

  @override
  Widget build(BuildContext context) {

    final userBox = Provider.of<UserHiveBox>(context, listen: false);

    final avatarUrl = userBox.avatar;

    final ppFile = File(avatarUrl);

    final ppWidget = ppFile.existsSync()
        ? CircleAvatar(
            backgroundImage: FileImage(ppFile),
            radius: 30.0,
          )
        : const CircleAvatar(
            backgroundImage: AssetImage('assets/images/user.png'),
            radius: 30.0,
          );

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: const Text('Settings'),
      ),
      body: Consumer<UserHiveBox>(builder: (context, user, child) {
        String name = user.name;
        String email = user.email;
        return ListView(
          children: [
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, UserProfileScreen.id);
              },
              contentPadding: const EdgeInsets.all(15.0),
              leading: Hero(
                tag: 'user_profile',
                child: ppWidget,
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              subtitle: Text(
                email,
                style: const TextStyle(
                  fontSize: 15.0,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, AccountSettings.id);
              },
              leading: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Icon(
                  Icons.account_circle,
                  size: 28.0,
                ),
              ),
              title: Text('Account'),
              subtitle: Text('Acount info, Delete acount'),
            ),
            const Divider(height: 1),
            ListTile(
              onTap: () {
                Navigator.pushNamed(context, DisplaySettings.id);
              },
              leading: const Padding(
                padding: EdgeInsets.all(5.0),
                child: Icon(
                  Icons.message,
                  size: 28.0,
                ),
              ),
              title: Text('Display'),
              subtitle: Text('Theme, Wallpaper'),
            ),
            const Divider(height: 1),
            ListTile(
              onTap: () {
                // Open app lisence
              },
              leading: Container(
                child: Icon(
                  Icons.help,
                  size: 35.0,
                ),
              ),
              title: Text('Help'),
              minLeadingWidth: 30,
              subtitle: Text('Get information about the app'),
            ),
            const Divider(height: 1),
          ],
        );
      }),
    );
  }
}
