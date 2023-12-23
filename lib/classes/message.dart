import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

part 'message.g.dart';

@HiveType(typeId: 1)
class MessageModel extends HiveObject {
  @HiveField(0)
  String sender;

  @HiveField(1)
  String message;

  @HiveField(2)
  String time;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  bool isMe;

  @HiveField(5)
  MessageType type;

  @HiveField(6)
  bool read = false;

  @HiveField(7)
  String? filePath;

  @HiveField(8)
  int? index;

  @HiveField(9)
  List<double>? decibels;

  @HiveField(10)
  String id;

  @HiveField(11)
  String? repliedToId;

  @HiveField(12)
  MessageStatus status;

  @HiveField(13)
  int? size = 0;

  @HiveField(14)
  String chatID;

  @HiveField(15)
  int? initOffset;

  MessageModel({
    required this.id,
    required this.sender,
    required this.message,
    required this.time,
    required this.date,
    required this.isMe,
    required this.type,
    required this.status,
    required this.chatID,
    this.size,
    this.index,
    this.initOffset,
    this.decibels,
    this.filePath,
    this.repliedToId,
  });

  Map<String, dynamic> toMap() {
    final messageMap = <String, dynamic>{
      'id': id,
      'sender': sender,
      'message': message,
      'time': time,
      'date': date.toIso8601String(),
      'isMe': isMe,
      'size': size,
      'type': getMessageTypeString(type),
      'status': getMessageStatusString(status),
      'repliedToId': repliedToId,
    };

    if (filePath != null) {
      messageMap['file']['path'] = getServerPath(filePath!);
    }

    if (index != null) {
      messageMap['index'] = index;
    }

    if (decibels != null) {
      messageMap['decibels'] = decibels;
    }

    return messageMap;
  }

  // factory MessageModel.fromJson(
  //   Map<String, dynamic> json,
  //   BuildContext context,
  // ) {
  //   return MessageModel(
  //     id: json['id'] as String,
  //     sender: json['sender'] as String,
  //     message: json['message'] as String,
  //     time: json['time'] as String,
  //     date: DateTime.parse(json['date'] as String),
  //     isMe: json['isMe'] as bool,
  //     type: MessageType
  //         .values[json['type'] as int], // Assuming MessageType is an enum
  //     status: MessageStatus
  //         .values[json['status'] as int], // Assuming MessageStatus is an enum
  //     chatID: json['chatID'] as String,
  //     size: json['size'] as int?,
  //     index: json['index'] as int?,
  //     initOffset: json['initOffset'] as int?,
  //     decibels: (json['decibels'] as List<dynamic>?)
  //         ?.map((e) => (e as num).toDouble())
  //         .toList(),
  //     filePath: json['filePath'] as String?,
  //     repliedToId: json['repliedToId'] as String?,
  //   );
  // }

  factory MessageModel.fromJson(
    Map<String, dynamic> message,
    BuildContext context,
  ) {
    // ignore: use_build_context_synchronously
    final user = Provider.of<UserHiveBox>(context, listen: false);
    final socket = Provider.of<SocketIo>(context, listen: false);

    socket.context = context;

    final messageID = message['id'];

    final file = message['file'] ?? {};
    final sender = message['sender'] as String;
    final recipient = message['recipient'] as String;
    final serverPath = file['path'] ?? '';
    List<double>? decibels;

    if (file['decibels'] != null) {
      decibels = (file['decibels'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList();
    } else {
      decibels = null;
    }

    final size = file['size'] ?? 0;
    final date = DateTime.parse(message['date'] as String);
    final time = message['time'] ?? getTimeOrDate(date, true);

    final isMe = sender == user.id;
    final chatId = isMe ? recipient : sender;

    final imageData = message['bluredFrame'];

    final path = getMobilePath(serverPath);

    if (imageData != null && serverPath != '') {
      final bluredPath = getBluredPath(path);
      saveImageToFile(imageData, bluredPath);
    }

    final stringStatus = message['status'];

    MessageStatus status = getMessageStatusFromString(stringStatus);

    print('message converted');
    if (stringStatus == 'sent' && !isMe) {
      print('sending "recieved" to chat');

      status = MessageStatus.received;
      socket.messageRecieved(chatId, messageID);
    }

    return MessageModel(
      id: messageID,
      sender: message['senderName'] as String,
      message: message['value'] as String,
      time: time,
      chatID: chatId,
      date: date,
      isMe: isMe,
      type: getMessageTypeFromString(message['type']),
      status: status,
      filePath: path,
      size: size,
      decibels: decibels,
      repliedToId: message['repliedToId'] as String?,
    );
  }

  void updateStatus(MessageStatus newStatus) => status = newStatus;
}

@HiveType(typeId: 2)
enum MessageType {
  @HiveField(0)
  text,
  @HiveField(1)
  image,
  @HiveField(2)
  video,
  @HiveField(3)
  audio,
  @HiveField(4)
  voice,
  @HiveField(5)
  files,
}

@HiveType(typeId: 3)
enum MessageStatus {
  @HiveField(0)
  sending,
  @HiveField(1)
  sent,
  @HiveField(2)
  received,
  @HiveField(3)
  seen,
}

MessageStatus getMessageStatusFromString(String statusString) {
  switch (statusString) {
    case 'sending':
      return MessageStatus.sending;
    case 'sent':
      return MessageStatus.sent;
    case 'received':
      return MessageStatus.received;
    case 'seen':
      return MessageStatus.seen;
    default:
      throw Exception('Invalid message status: $statusString');
  }
}

MessageType getMessageTypeFromString(String typeString) {
  switch (typeString) {
    case 'text':
      return MessageType.text;
    case 'image':
      return MessageType.image;
    case 'video':
      return MessageType.video;
    case 'audio':
      return MessageType.audio;
    case 'voice':
      return MessageType.voice;
    case 'files' || 'file':
      return MessageType.files;
    default:
      throw Exception('Invalid message type: $typeString');
  }
}

String getMessageTypeString(MessageType type) {
  switch (type) {
    case MessageType.text:
      return 'text';
    case MessageType.image:
      return 'image';
    case MessageType.video:
      return 'video';
    case MessageType.audio:
      return 'audio';
    case MessageType.voice:
      return 'voice';
    case MessageType.files:
      return 'file';
    default:
      throw Exception('Invalid message type: $type');
  }
}

String getMessageStatusString(MessageStatus status) {
  switch (status) {
    case MessageStatus.sending:
      return 'sending';
    case MessageStatus.sent:
      return 'sent';
    case MessageStatus.received:
      return 'received';
    case MessageStatus.seen:
      return 'seen';
    default:
      throw Exception('Invalid message status: $status');
  }
}
