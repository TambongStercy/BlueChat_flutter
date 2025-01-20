import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/providers/file_upload.dart';
import 'package:blue_chat_v1/providers/socket_io.dart';
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
  bool isGroup = false;

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

  @HiveField(15)
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

  MessageModel get lastMessage => messages.last;
  MessageModel getMessageById(String id) =>
      messages.firstWhere((msg) => msg.id == id);

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

  bool removeAdmins({required List<String> chats, required String adminId}) {
    if (adminsId!.contains(adminId)) return false;

    for (String chat in chats) {
      adminsId?.remove(chat);
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

  Future<void> typing(context) async {
    if (timer != null) timer?.cancel();
    isTyping = true;

    final updater = Provider.of<Updater>(context, listen: false);
    updater.updateChatScreen();
    updater.updateChatsScreen();

    timer = Timer(const Duration(seconds: 1), () async {
      isTyping = false;
      await save();
      updater.updateChatScreen();
      updater.updateChatsScreen();
    });

    await save();
  }

  Future<void> updateStatus(String newStatus, DateTime newLastSeen) async {
    status = newStatus;
    lastSeen = newLastSeen;
    await save();
  }

  void makeMyMessageReceived(
    String messageID,
    String chatId,
    DateTime time,
  ) {
    for (final message in messages) {
      if (message.isMe && message.id == messageID) {
        if (isGroup && participants!.length - 1 <= message.readBy!.length) {
          message.updateStatus(MessageStatus.received, chatId, time);
        }
        if (!isGroup)
          message.updateStatus(MessageStatus.received, chatId, time);
        break;
      }
    }
    save();
  }

  /// Mark all the messages user sent to chat as seen
  void makeMyMessageSeen(
    String messageID,
    String chatId,
    DateTime time,
  ) {
    for (final message in messages) {
      if (message.isMe && message.id == messageID) {
        if (isGroup && participants!.length - 1 <= message.seenBy!.length) {
          message.updateStatus(MessageStatus.seen, chatId, time);
        }
        if (!isGroup) message.updateStatus(MessageStatus.seen, chatId, time);
        break;
      }
    }
    save();
  }

  /// Mark all the messages chat sent to user as seen
  void makeChatMessageSeen(
    String messageID,
    BuildContext context,
    String chatId,
    DateTime time,
  ) async {
    for (final message in messages) {
      if (!message.isMe &&
          message.id == messageID &&
          message.status != MessageStatus.seen) {
        message.updateStatus(MessageStatus.seen, chatId, time);
        Provider.of<SocketIo>(context, listen: false)
            .messageSeen(id, messageID);
        break;
      }
    }
    save();
  }

  void makeMessageSeenByMe(
    String messageID,
    BuildContext context,
  ) async {
    for (final message in messages) {
      if (!message.isMe &&
          message.id == messageID &&
          message.status != MessageStatus.seen) {
        final userBox = Provider.of<UserHiveBox>(context, listen: false);
        message.updateStatus(MessageStatus.seen, userBox.id, DateTime.now());
        Provider.of<SocketIo>(context, listen: false)
            .messageSeen(id, messageID);
        break;
      }
    }
    save();
  }

  void updateMessageStatus(
    String messageID,
    MessageStatus messageStatus,
    String chatId,
    DateTime time,
  ) {
    for (MessageModel message in messages) {
      if (message.id == messageID) {
        message.updateStatus(messageStatus, chatId, time);
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
      if (userBox.id == id) {
        continue;
      }

      final member = chatBox.getChat(id);
      if (member == null) {
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
      repliedToId: repMsg.message?.id,
    );
    isAsearch = false;
    messages.add(message);

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

  Future<void> sendAllYourMessages(BuildContext context) async {
    for (final message in messages) {
      if (message.isMe && message.status == MessageStatus.sending) {
        final socket = Provider.of<SocketIo>(context, listen: false);
        if(socket.isConnected) {
          socket.sendMessage(chatID: id, message: message);
        }
      }
    }
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
      chatMap['admins'] = adminsId;
    }

    return chatMap;
  }

  ///Creates a Chat object from json object that was sent
  factory Chat.fromJson(Map<String, dynamic> chat, BuildContext context) {
    final object = chat['messages'];
    final id = chat['id'];

    final List<String>? participants = chat['participants']?.cast<String>();
    final List<String>? adminsId = chat['admins']?.cast<String>();

    print('is a group: ${chat['isGroup']}');

    final List<MessageModel> messages = object != null && object.isNotEmpty
        ? object
            .map((message) {
              return MessageModel.fromJson(message, id, context);
            })
            .toList()
            .cast<MessageModel>()
        : [];

    final lastSeen =
        chat['lastSeen'] != null ? DateTime.parse(chat['lastSeen']) : null;

    final avatarBuffer = chat['avatarBuffer'];

    final serverPath = chat['avatar'];

    final path = getMobilePath(serverPath);

    final ppFile = File(path);

    if (avatarBuffer != null) {
      if (ppFile.existsSync()) {
        ppFile.deleteSync();
      }
      ppFile.createSync(recursive: true);
      final Uint8List bytes = base64Decode(avatarBuffer);
      ppFile.writeAsBytesSync(bytes);

      roundImageAndSave(ppFile);
    }

    return Chat(
      id: id,
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

  factory Chat.fromJsonNotif(Map<String, dynamic> chat) {
    final object = chat['messages'];
    final id = chat['id'];

    final List<String>? participants = chat['participants']?.cast<String>();
    final List<String>? adminsId = chat['admins']?.cast<String>();

    final List<MessageModel> messages = object != null && object.isNotEmpty
        ? object
            .map((message) {
              return MessageModel.fromJsonNotif(message, id);
            })
            .toList()
            .cast<MessageModel>()
        : [];

    final lastSeen =
        chat['lastSeen'] != null ? DateTime.parse(chat['lastSeen']) : null;

    final avatarBuffer = chat['avatarBuffer'];

    final serverPath = chat['avatar'];

    final path = getMobilePath(serverPath);

    final ppFile = File(path);

    if (avatarBuffer != null) {
      if (ppFile.existsSync()) {
        ppFile.deleteSync();
      }
      ppFile.createSync(recursive: true);
      final Uint8List bytes = base64Decode(avatarBuffer);
      ppFile.writeAsBytesSync(bytes);
    }

    return Chat(
      id: id,
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
