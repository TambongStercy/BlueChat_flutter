import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class UserHiveBox extends ChangeNotifier {
  Box box;

  UserHiveBox(this.box);

  String get id {
    final values = box.get('values');
    return values['id']??'';
  }

  String get name {
    final values = box.get('values');
    return values['name'];
  }

  String get email {
    final values = box.get('values');
    return values['email'];
  }

  String get avatar {
    final values = box.get('values');
    return values['avatar'];
  }

  String get token {
    final values = box.get('values');
    return values?['token']??'';
  }

  Future<void> closeBox() async {
    await box.close();
  }

  Future<void> saveToken(token) async {
    await box.put(
      'values',
      {
        'id': id,
        'name': name,
        'email': email,
        'avatar': avatar,
        'token': token,
      },
    );

    // notifyListeners();
  }

  Future<void> updateUser({
    id,
    name,
    email,
    avatar,
  }) async {
    print('Putting ID: $id, name: $name, email: $email, avatar: $avatar');
    await box.put(
      'values',
      {
        'id': id ?? this.id,
        'name': name ?? this.name,
        'email': email ?? this.email,
        'avatar': avatar ?? this.avatar,
        'token': token,
      },
    );

    
    print('user info saved');
    print(box.get('values'));
  }

  Future<void> logoutUser() async {
    await box.put(
      'values',
      {
        'id': '',
        'name': '',
        'email': '',
        'avatar': '',
        'token': '',
      },
    );
  }
}