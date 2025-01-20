import 'package:blue_chat_v1/classes/chat.dart';
// import 'package:blue_chat_v1/classes/message.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ChatHiveBox extends ChangeNotifier {
  Box<Chat> box;

  ChatHiveBox(this.box);

  //for backgroubd processes
  Future<void> closeBox() async {
    await box.close();
  }

  /// Adds or Updates a chat
  Future<void> addUpdateChat(Chat chat) async {
    final localChat = getChat(chat.id);

    //if chat does not yet exist in DB
    if (localChat == null) {
      box.put(chat.id, chat);
      await chat.save();
      notifyListeners();
      return;
    }

    localChat.isGroup = chat.isGroup;
    localChat.isClosed = chat.isClosed;
    localChat.participants = chat.participants;
    localChat.description = chat.description;
    localChat.onlyAdmins = chat.onlyAdmins;
    localChat.adminsId = chat.adminsId;
    localChat.name = chat.name;
    localChat.status = chat.status;
    localChat.email = chat.email;
    localChat.avatar = chat.avatar;
    localChat.lastSeen = chat.lastSeen;
    localChat.messages = chat.messages.length >= localChat.messages.length
        ? chat.messages
        : localChat.messages;

    await localChat.save();

    notifyListeners();
  }

  bool isChat(String id) {
    return box.get(id) != null;
  }

  /// Get's a specific chat by it's id
  Chat? getChat(String id) {
    return box.get(id);
  }

  /// Get all chats including groups
  List<Chat> getAllChats() {
    final value = box.toMap().values;
    List<Chat> sortValues = value.toList()
      ..sort((a, b) {
        if (a.messages.isEmpty && b.messages.isEmpty) {
          return 0;
        } else if (a.messages.isEmpty) {
          return 1;
        } else if (b.messages.isEmpty) {
          return -1;
        } else {
          return b.messages.last.date.compareTo(a.messages.last.date);
        }
      });
    return sortValues;
  }

  /// Get all groups without chats
  List<Chat> getGroups() {
    final value = box.toMap().values;
    List<Chat> sortValues = value.where((chat) => chat.isGroup).toList()
      ..sort((a, b) {
        if (a.messages.isEmpty && b.messages.isEmpty) {
          return 0;
        } else if (a.messages.isEmpty) {
          return 1;
        } else if (b.messages.isEmpty) {
          return -1;
        } else {
          return b.messages.last.date.compareTo(a.messages.last.date);
        }
      });
    return sortValues;
  }

  /// Get all chats without groups
  List<Chat> getChats() {
    final value = box.toMap().values;
    List<Chat> sortValues = value.where((chat) => !chat.isGroup).toList()
      ..sort((a, b) {
        if (a.messages.isEmpty && b.messages.isEmpty) {
          return 0;
        } else if (a.messages.isEmpty) {
          return 1;
        } else if (b.messages.isEmpty) {
          return -1;
        } else {
          return b.messages.last.date.compareTo(a.messages.last.date);
        }
      });
    return sortValues;
  }

  /// Check if groups are found in DB
  bool hasGroup() {
    final value = box
        .toMap()
        .values
        .toList()
        .where((chat) => chat.isAsearch == null || !chat.isAsearch!)
        .toList();
    if (value.isEmpty) return false;

    return value.any((element) => element.isGroup);
  }

  /// Check if chats are found in DB
  bool hasChat() {
    final value = box
        .toMap()
        .values
        .toList()
        .where((chat) => chat.isAsearch == null || !chat.isAsearch!)
        .toList();
    if (value.isEmpty) return false;

    return value.any((element) => !element.isGroup);
  }

  /// Empty chat from DB
  Future<void> emptyChat(String id) async {
    box.delete(id);
    notifyListeners();
  }

  /// Delete all chats from DB
  Future<void> emptyBox() async {
    await box.clear();
    notifyListeners();
  }

  void sendMessages() {
    final chats = getChats();
    for (final chat in chats) {
      chat.messages.forEach((message) {});
    }
  }
}
