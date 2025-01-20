import 'package:blue_chat_v1/api_call.dart';
import 'package:flutter/material.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  static const String id = 'account_settings';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Account'),
        ),
        body: Column(
          children: [
            ListTile(
              onTap: () {
              },
              leading: const Padding(
                padding: EdgeInsets.all(5.0),
                child: Icon(
                  Icons.file_open,
                  size: 25.0,
                ),
              ),
              title: Text('Account info'),
            ),
            ListTile(
              onTap: () {
                logout(context: context);
              },
              leading: const Padding(
                padding: EdgeInsets.all(5.0),
                child: Icon(
                  Icons.logout,
                  size: 25.0,
                ),
              ),
              title: Text('Log out'),
            ),
            ListTile(
              onTap: () {
                
              },
              leading: const Padding(
                padding: EdgeInsets.all(5.0),
                child: Icon(
                  Icons.delete,
                  size: 25.0,
                ),
              ),
              title: Text('Delete account'),
            ),
          ],
        ),
      ),
    );
  }
}