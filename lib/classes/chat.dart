import 'dart:async';
import 'dart:io';

import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

part 'chat.g.dart';

@HiveType(typeId: 0)
class Chat extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String avatar;

  @HiveField(4)
  bool isGroup;

  @HiveField(5)
  String status;

  @HiveField(6)
  DateTime? lastSeen;

  @HiveField(7)
  List<MessageModel> messages;

  @HiveField(8)
  bool? isClosed;

  @HiveField(9)
  List<String>? participants = [];

  @HiveField(10)
  String? description;

  @HiveField(11)
  bool? onlyAdmins;

  @HiveField(12)
  List<String>? adminsId;

  @HiveField(13)
  bool? isAsearch;

  @HiveField(14)
  bool? isTyping = false;

  
  @HiveField(14)
  String? avatarBuffer;

  Timer? timer;

  Chat({
    required this.id,
    required this.name,
    required this.avatar,
    required this.email,
    required this.status,
    required this.lastSeen,
    required this.messages,
    required this.isGroup,
    this.isClosed,
    this.participants,
    this.description,
    this.onlyAdmins,
    this.adminsId,
    this.isAsearch,
    this.avatarBuffer,
  });

  int getUnreadMessages() {
    int count = 0;
    for (MessageModel message in messages) {
      if (message.status != MessageStatus.seen && !message.isMe) {
        count++;
      }
    }
    return count;
  }

  void removeMessage(MessageModel cMsg) {
    // messages = messages.where((msg) => msg.id != cMsg.id).toList();

    for (MessageModel message in messages) {
      if (cMsg.id == message.id) {
        messages.remove(message);
        break;
      }
    }
    save();
  }

  bool addParticipants({required List<String> chats, required String adminId}) {
    if (!adminsId!.contains(adminId)) return false;

    participants ??= [];

    for (String chat in chats) {
      participants?.add(chat);
    }
    save();
    return true;
  }

  String formatedLastSeen() {
    String val;
    print(lastSeen);
    if (status == 'online') {
      val = status;
    } else {
      val = 'last seen ${getDuration(lastSeen ?? DateTime.now())}';
    }
    return val;
  }

  bool removeParticipant({required Chat chat, required String adminId}) {
    if (!adminsId!.contains(adminId)) return false;

    if (participants == null) return true;
    participants!.removeWhere((participant) => participant == chat.id);

    save();
    return true;
  }

  bool addAdmins({required List<String> chats, required String adminId}) {
    if (!adminsId!.contains(adminId)) return false;

    adminsId ??= [];

    for (String chat in chats) {
      adminsId?.add(chat);
    }

    save();
    return true;
  }

  void exitGroup({required String userId}) {
    participants?.remove(userId);
    save();
  }

  bool changeDescription(
      {required String newDescription, required String adminId}) {
    if (!adminsId!.contains(adminId)) return false;

    description = newDescription;
    save();
    return true;
  }

  bool isGroupAdmin(id) {
    return adminsId == null ? false : adminsId!.contains(id);
  }

  bool isMember(id) {
    return isGroup &&
        participants != null &&
        (participants!.any((participant) => participant == id) ||
            adminsId!.any((adminId) => adminId == id));
  }

  void typing() {
    if (timer != null) timer?.cancel();
    isTyping = true;
    timer = Timer(const Duration(seconds: 2), () {
      isTyping = false;
      print('isTyping: ');
      print(isTyping);
      save();
    });
    save();
  }

  Future<void> updateStatus(String newStatus, DateTime newLastSeen) async {
    status = newStatus;
    lastSeen = newLastSeen;
    await save();
  }

  void makeMyMessageReceived(String messageID) {
    for (final message in messages) {
      if (message.isMe && message.id == messageID) {
        message.updateStatus(MessageStatus.received);
        break;
      }
    }
  }

  /// Mark all the messages user sent to chat as seen
  void makeMyMessageSeen(String messageID) {
    for (final message in messages) {
      if (message.isMe && message.id == messageID) {
        message.updateStatus(MessageStatus.seen);
        break;
      }
    }
  }

  /// Mark all the messages chat sent to user as seen
  void makeChatMessageSeen(String messageID, BuildContext context) async {
    for (final message in messages) {
      if (!message.isMe &&
          message.id == messageID &&
          message.status != MessageStatus.seen) {
        message.updateStatus(MessageStatus.seen);
        Provider.of<SocketIo>(context).messageSeen(id, messageID);
        break;
      }
    }
  }

  void updateMessageStatus(String messageID, MessageStatus messageStatus) {
    for (MessageModel message in messages) {
      if (message.id == messageID) {
        message.updateStatus(messageStatus);
      }
    }
    save();
  }

  void changeAdminOnlyTo(value) {
    onlyAdmins = value;
    save();
  }

  String getParticipantsNames(BuildContext context) {
    final chatBox = Provider.of<ChatHiveBox>(context, listen: false);
  final userBox = Provider.of<UserHiveBox>(context, listen: false);
    final List<String> memberNames = [];

    for (final id in participants!) {
      if(userBox.id == id){
        continue;
      }

      final member = chatBox.getChat(id);
      if(member == null){
        continue;
      }
      memberNames.add(member.name);
    }

    memberNames.sort();

    final str = memberNames.join(', ');

    return str;
  }

  List<MessageModel> getMediaMessages() {
    return messages
        .where((msg) =>
            (msg.type == MessageType.image || msg.type == MessageType.video) &&
            File(msg.filePath ?? '').existsSync() &&
            File(msg.filePath ?? '').lengthSync() >= msg.size!)
        .toList();
  }

  Future<MessageModel> sendYourMessage({
    required BuildContext context,
    required String msg,
    required MessageType type,
    String? path,
    List<double>? decibels,
    // bool? ,
  }) async {
    final user = Provider.of<UserHiveBox>(context, listen: false);
    final repMsg = Provider.of<RepliedMessage>(context, listen: false);
    final uploadProvider =
        Provider.of<FileUploadProvider>(context, listen: false);
    final String yourName = user.name;

    DateTime now = DateTime.now();
    String timeOfDay =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final userID = user.id;
    final chatID = id;

    String? realPath = path;
    int size = 0;

    if (type != MessageType.text && path != null) {
      realPath = (await saveFileFromCache(path, type))!;
      size = getFileSize(realPath);
    } else {
      print('what type of message is this?');
    }

    final msgID = userID + chatID + now.toIso8601String();

    final message = MessageModel(
      id: msgID,
      sender: yourName,
      chatID: chatID,
      message: msg,
      time: timeOfDay,
      date: now,
      isMe: true,
      type: type,
      size: size,
      filePath: realPath,
      decibels: decibels,
      status: MessageStatus.sending,
      repliedToId: repMsg.message != null ? repMsg.message!.id : null,
    );
    isAsearch = false;
    messages.add(message);

    print('yes yes, msgID: $msgID');

    await save();

    // ignore: use_build_context_synchronously
    final socket = Provider.of<SocketIo>(context, listen: false);
    if (type == MessageType.text) {
      socket.sendMessage(chatID: chatID, message: message);
    } else {
      final item = UploadItem(selectedFilePath: realPath);
      uploadProvider.addUploadItem(item);
    }

    return message;
  }

  ///Add message model to chat messages
  Future<void> addMessage(MessageModel message) async {
    messages.add(message);
    await save();
  }

  ///Creates a Json object from Chat object input
  Map<String, dynamic> toMap() {
    final chatMap = <String, dynamic>{
      'id': id,
      'username': name,
      'email': email,
      'avatar': avatar,
      'isGroup': isGroup,
      'status': status,
      'lastSeen': lastSeen,
      'messages': messages.map((message) => message.toMap()).toList(),
    };

    if (isClosed != null) {
      chatMap['isClosed'] = isClosed;
    }

    if (participants != null) {
      chatMap['participants'] = participants;
    }

    if (description != null) {
      chatMap['description'] = description;
    }

    if (onlyAdmins != null) {
      chatMap['onlyAdmins'] = onlyAdmins;
    }

    if (adminsId != null) {
      chatMap['adminsId'] = adminsId;
    }

    return chatMap;
  }

  ///Creates a Chat object from json object that was sent
  factory Chat.fromJson(Map<String, dynamic> chat, BuildContext context) {
    final object = chat['messages'];

    final List<String>? participants = chat['participants']?.cast<String>();
    final List<String>? adminsId = chat['adminsId']?.cast<String>();

    final List<MessageModel> messages = object != null && object.isNotEmpty
        ? object
            .map((message) {
              return MessageModel.fromJson(message, context);
            })
            .toList()
            .cast<MessageModel>()
        : [];

    final lastSeen =
        chat['lastSeen'] != null ? DateTime.parse(chat['lastSeen']) : null;
    
    final avatarBuffer = chat['avatarBuffer'];

    final serverPath = chat['avatar'];
    
    final path = getMobilePath(serverPath);


    return Chat(
      id: chat['id'],
      name: chat['username'],
      avatar: path,
      avatarBuffer: avatarBuffer,
      email: chat['email'],
      status: chat['status'],
      lastSeen: lastSeen,
      messages: messages,
      isGroup: chat['isGroup'],
      isClosed: chat['isClosed'],
      participants: participants,
      description: chat['description'],
      onlyAdmins: chat['onlyAdmins'],
      adminsId: adminsId,
      isAsearch: false,
    );
  }

}
