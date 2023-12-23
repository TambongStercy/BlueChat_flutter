import 'package:blue_chat_v1/classes/chat.dart';
// import 'package:blue_chat_v1/classes/message.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ChatHiveBox extends ChangeNotifier {
  Box<Chat> box;

  ChatHiveBox(this.box);

  /// Adds or Updates a chat
  Future<void> addUpdateChat(Chat chat) async {
    box.put(chat.id, chat);
    await chat.save;
    notifyListeners();
  }

  bool isChat(String id){
    return  box.get(id) != null;
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
  List<Chat> getGroups(){
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
  List<Chat> getChats(){
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
    final value = box.toMap().values.toList().where((chat) => chat.isAsearch == null || !chat.isAsearch!).toList();
    if(value.isEmpty) return false;

    return value.any((element) => element.isGroup);
  }

  /// Check if chats are found in DB
  bool hasChat() {
    final value = box.toMap().values.toList().where((chat) => chat.isAsearch == null || !chat.isAsearch!).toList();
    if(value.isEmpty) return false;
    
    return value.any((element) => !element.isGroup);
  }

  /// Empty chat from DB
  Future<void> emptyChat(String id)async{
    box.delete(id);
    notifyListeners();
  }

  /// Delete all chats from DB
  Future<void> emptyBox()async {
    await box.clear();
    notifyListeners();
  }
}
