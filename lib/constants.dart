import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/screens/chat_screen.dart';
import 'package:blue_chat_v1/screens/chats.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/components/chat_message.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

const kServerURL =
    'http://192.168.225.174:3000'; //type ipConfig in cmd to see pc's ip address
// const kServerURL = 'http://10.0.2.2:3000'; //for emulators only

late Directory kAppDirectory;
late Directory kTempDirectory;

const kTitleStyle = TextStyle(
  color: Colors.black54,
  fontSize: 30.0,
  fontWeight: FontWeight.w600,
);

const kTextFielDecoration = InputDecoration(
  fillColor: Colors.white,
  hoverColor: Colors.black,
  hintText: 'Enter a value.',
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(15.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.lightBlueAccent, width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(15.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(15.0)),
  ),
);

class SlideRightToLeftPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  SlideRightToLeftPageRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        );
}

class FadePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  FadePageRoute({required this.builder});
  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return FadeTransition(
      opacity: animation,
      child: builder(context),
    );
  }

  @override
  Duration get transitionDuration => Duration(milliseconds: 400);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;
}

class RightAngleTriangleContainer extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final bool isMe;

  const RightAngleTriangleContainer(
      {Key? key,
      required this.color,
      required this.width,
      required this.height,
      required this.isMe})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: RightAngleTrianglePainter(color: color, isMe: isMe),
      child: null,
    );
  }
}

class RightAngleTrianglePainter extends CustomPainter {
  final Color color;
  final bool isMe;

  RightAngleTrianglePainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final double topRight = isMe ? 0 : size.height;
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(topRight, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

//Notifier Providers

class Selection extends ChangeNotifier {
  bool _selectionMode = false;

  int _selectedItems = 0;

  bool get selectionMode {
    return _selectionMode;
  }

  int get selectedItems {
    return _selectedItems;
  }

  void _toggleSelectMode() {
    _selectionMode = !_selectionMode;
  }

  final Map<String, MessageModel> _selected = Map();

  List<MessageModel> get selected {
    return _selected.values.toList();
  }

  void incrementSelectedMessage({
    required bool incrementing,
    required ChatMessage message,
  }) {
    if (incrementing) {
      if (_selectedItems == 0) _toggleSelectMode();

      final objMsg = chatmsgToMsgobj(message);
      _selected[objMsg.id] = objMsg;
      _selectedItems++;
    } else {
      final objMsg = chatmsgToMsgobj(message);
      _selected.remove(objMsg.id);
      _selectedItems--;

      if (_selectedItems == 0) _toggleSelectMode();
    }

    notifyListeners();

    // for (String text in _selected) {
    //   print(text);
    // }
  }

  void quitSelectionMode() {
    _selectedItems = 0;
    _selectionMode = false;
    _selected.clear();
    notifyListeners();
  }
}

class FilesToSend extends ChangeNotifier {
  List<AccFiles> files = [];
  List<String> ids = [];

  void addFiles(List<AccFiles> values) {
    for (AccFiles value in values) {
      files.add(value);
    }
    notifyListeners();
  }

  void emptyFiles() {
    files.length = 0;
    // notifyListeners();
  }
}

class ConstantAppData extends ChangeNotifier {
  String? _wallPaper;

  String? get wallPaper {
    return _wallPaper;
  }

  void changeWallPaper(String? path) {
    _wallPaper = path;
    notifyListeners();
  }
}

class CurrentChat extends ChangeNotifier {
  Chat? _chat;

  Chat? get openedChat {
    return _chat;
  }

  void addChat(Chat chat) {
    _chat = null;
    _chat = chat;
    notifyListeners();
  }

  void empty() {
    _chat = null;
    notifyListeners();
  }
}

class RepliedMessage extends ChangeNotifier {
  MessageModel? message;
  bool isEmpty = true;

  void update(MessageModel msg) {
    message = msg;
    isEmpty = false;
    notifyListeners();
  }

  void clear() {
    message = null;
    isEmpty = true;
    notifyListeners();
  }
}

class SocketIo extends ChangeNotifier {
  late IO.Socket _socket;

  late BuildContext context;

  SocketIo(this.context) {
    // Call your initialization method or perform any other desired actions

    final UserHiveBox userBox =
        Provider.of<UserHiveBox>(context, listen: false);

    final String email = userBox.email;

    _socket = IO.io(
      kServerURL,
      IO.OptionBuilder()
          .setTransports(['websocket']).setQuery({'email': email}).build(),
    );

    _socket.onConnect((_) {
      print('connected');
      Provider.of<SocketIo>(context, listen: false);
      initGeneralListeners();
    });

    _socket.onDisconnect((_) => print('Socket server disconnected'));
    _socket.onConnectError((err) => print(err));
    _socket.onError((err) => print(err));

    _socket.connect();
  }

  void initGeneralListeners() async {
    final UserHiveBox userBox =
        Provider.of<UserHiveBox>(context, listen: false);

    final String token = userBox.token;

    print('initilizing...');

    final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

    if (!_socket.hasListeners('success')) {
      _socket.on('success', (token) async {
        print('this is a success');
        print(token);
        await userBox.saveToken(token);
      });
    } else {
      print('has already this listener');
    }

    if (!_socket.hasListeners('new-messages')) {
      _socket.on('new-messages', (data) async {
        try {
          print('getting notifications');
          print(data);
          final updatedChatsJson = data?['chatUpdates'] ?? [];

          final updatedMsgsJson = data?['messageUpdates'] ?? [];

          ///To add Messages to old Chats or new Chats
          for (final updatedChatJson in updatedChatsJson) {
            final chatID = updatedChatJson['id'];

            // ignore: use_build_context_synchronously
            final List<dynamic> jsonMessages = updatedChatJson['messages'];

            //if chat is not found in local database
            if (!chatBox.isChat(chatID)) {
              // create new chats
              // ignore: use_build_context_synchronously
              final chat = Chat.fromJson(updatedChatJson, context);
              await chat.save();
              print('saved new chat');
            }

            final chat = chatBox.getChat(chatID);

            if (chat == null) {
              print('chat(part2) is empty');
              continue;
            }

            chat.isGroup = updatedChatJson['isGroup'];
            chat.isClosed = updatedChatJson['isClosed'];
            chat.participants = updatedChatJson['participants'];
            chat.description = updatedChatJson['description'];
            chat.onlyAdmins = updatedChatJson['onlyAdmins'];
            chat.adminsId = updatedChatJson['adminsId'];
            chat.name = updatedChatJson['username'];
            chat.status = updatedChatJson['status'];
            chat.email = updatedChatJson['email'];
            chat.avatar = updatedChatJson['avatar'];

            await chat.save();

            for (final jsonMessage in jsonMessages) {
              final MessageModel message =
                  MessageModel.fromJson(jsonMessage, context);
              await chat.addMessage(message);
            }
          }

          ///To Update Messages
          for (final updatedMsgJson in updatedMsgsJson) {
            final messageStatus = updatedMsgJson['messageStatus'];
            final chatID = updatedMsgJson['chatID'];
            final messageID = updatedMsgJson['messageID'];
            final chat = chatBox.getChat(chatID);

            if (chat == null) {
              // print('Chats have not yet being completely saved');
              print('chat(part1) is empty');
              continue;
            }

            if (messageStatus == 'seen') {
              chat.makeMyMessageSeen(messageID);
              continue;
            }
            //else it's recieved
            chat.updateMessageStatus(messageID, messageStatus);
          }

          final updaters =
              Provider.of<Updater>(context, listen: false).updaters;
          if (updaters.keys.contains(ChatScreen.id)) {
            final updatePage = updaters[ChatScreen.id];
            updatePage!();
          }
          if (updaters.keys.contains(ChatsScreen.id)) {
            final updatePage = updaters[ChatsScreen.id];
            updatePage!();
          }

          print('all done');
        } on Exception catch (e) {
          print(e);
        }
      });
    } else {
      print('has already this listener');
    }

    if (!_socket.hasListeners('searched')) {
      _socket.on('searched', (chatInfoList) async {
        // final chatJsons = json.decode(chatInfoList);
        for (final chatJson in chatInfoList) {
          print('id: ${chatJson['id']}');
          print('email: ${chatJson['email']}');
          print('description: ${chatJson['description']}');
          final chatID = chatJson['id'];
          if (chatBox.isChat(chatID)) {
            continue;
          }
          await saveSearchChat(chatJson, context);
        }
      });
    } else {
      print('has already this listener');
    }

    if (!_socket.hasListeners('update-status')) {
      _socket.on('update-status', (data) async {
        final chatID = data['id'];
        final status = data['status'] ?? 'offline';
        final lastSeen = data['lastSeen'] != null
            ? DateTime.parse(data['lastSeen'])
            : DateTime.now();

        final chat = chatBox.getChat(chatID)!;

        print('${chat.name} is $status');
        if (status == 'offline')
          print('lastSeen at ${getTimeOrDate(lastSeen, true)}');

        await chat.updateStatus(status, lastSeen);

        final updaters = Provider.of<Updater>(context, listen: false).updaters;
        if (updaters.keys.contains(ChatScreen.id)) {
          final updatePage = updaters[ChatScreen.id];
          updatePage!();
        }
        if (updaters.keys.contains(ChatsScreen.id)) {
          final updatePage = updaters[ChatsScreen.id];
          updatePage!();
        }
      });
    } else {
      print('has already this listener');
    }

    if (!_socket.hasListeners('msg-sent')) {
      _socket.on('msg-sent', (data) {
        final messageID = data[0];
        final receiverId = data[1];
        const kMessageStatus = MessageStatus.sent;

        print('my message was sent');

        final Chat chat = chatBox.getChat(receiverId)!;

        print('1');

        chat.updateMessageStatus(messageID, kMessageStatus);
        print('2');

        final updaters = Provider.of<Updater>(context, listen: false).updaters;
        if (updaters.keys.contains(ChatScreen.id)) {
          final updatePage = updaters[ChatScreen.id];
          updatePage!();
        }
        if (updaters.keys.contains(ChatsScreen.id)) {
          final updatePage = updaters[ChatsScreen.id];
          updatePage!();
        }
      });
    } else {
      print('has already this listener');
    }

    if (!_socket.hasListeners('msg-recieved')) {
      _socket.on('msg-recieved', (data) async {
        final recieverID = data['recieverID'];
        final messageID = data['messageID'];

        print('my message was recieved');

        final chat = chatBox.getChat(recieverID)!;
        chat.updateMessageStatus(messageID, MessageStatus.received);
        await chat.save();

        final updaters = Provider.of<Updater>(context, listen: false).updaters;
        if (updaters.keys.contains(ChatScreen.id)) {
          final updatePage = updaters[ChatScreen.id];
          updatePage!();
        }
        if (updaters.keys.contains(ChatsScreen.id)) {
          final updatePage = updaters[ChatsScreen.id];
          updatePage!();
        }
      });
    } else {
      print('has already this listener');
    }

    if (!_socket.hasListeners('msgs-seen')) {
      _socket.on('msgs-seen', (data) async {
        final chatID = data['chatID'];
        final messageID = data['messageID'];

        final chat = chatBox.getChat(chatID)!;
        chat.updateMessageStatus(messageID, MessageStatus.seen);
        // chat.makeMyMessageSeen(messageID);
        await chat.save();
      });
    } else {
      print('has already this listener');
    }

    if (!_socket.hasListeners('message')) {
      _socket.on('message', (data) async {
        final jsonMessage = data[0];
        final senderID = data[1];
        print('jsonMessage: $jsonMessage');
        print('bluredFrame: ${jsonMessage['bluredFrame']}');
        print('senderID: $senderID');

        final message = MessageModel.fromJson(jsonMessage, context);
        final updaters = Provider.of<Updater>(context, listen: false).updaters;
        final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);

        final type = message.type;

        _socket.emit('msg-recieved', {
          'senderID': senderID,
          'messageID': message.id,
        });

        final Chat chat = chatBox.getChat(senderID)!;

        if (type == MessageType.text) {
          await chat.addMessage(message);
          await chat.save();

          if (updaters.keys.contains(ChatScreen.id)) {
            final updatePage = updaters[ChatScreen.id];
            updatePage!();
          }
          if (updaters.keys.contains(ChatsScreen.id)) {
            final updatePage = updaters[ChatsScreen.id];
            updatePage!();
          }
          return;
        }else{
          final file = File(message.filePath!);
          final size = message.size;
          if ((!file.existsSync() || file.lengthSync() < size!)) {
            final item = DownloadItem(
              path: message.filePath!,
              totalBytes: size!,
            );
            downloadProvider.addDownloadItem(item);
          }
        }

        final path = message.filePath!;

        // final int fileSize = jsonMessage['file']['size'];
        // final size = formatFileSize(fileSize);

        if (type == MessageType.video || type == MessageType.image) {
          final imageData = jsonMessage['bluredFrame'];

          final bluredPath = getBluredPath(path);

          await saveImageToFile(imageData, bluredPath);
        }

        await chat.addMessage(message);
        await chat.save();

        // print(updaters);
        if (updaters.keys.contains(ChatScreen.id)) {
          final updatePage = updaters[ChatScreen.id];
          updatePage!();
        }
        if (updaters.keys.contains(ChatsScreen.id)) {
          final updatePage = updaters[ChatsScreen.id];
          updatePage!();
        }
      });
    } else {
      print('has already this listener');
    }

    if (!_socket.hasListeners('message')) {
      _socket.on('typing', (typerID) {
        final chat = chatBox.getChat(typerID)!;
        chat.typing();

        final updaters = Provider.of<Updater>(context, listen: false).updaters;
        if (updaters.keys.contains(ChatScreen.id)) {
          final updatePage = updaters[ChatScreen.id];
          updatePage!();
        }
        if (updaters.keys.contains(ChatsScreen.id)) {
          final updatePage = updaters[ChatsScreen.id];
          updatePage!();
        }
      });
    } else {
      print('has already this listener');
    }

    _socket.emit('token', token);
  }

  void disconnect() {
    _socket.dispose();
  }

  void messageRecieved(String senderID, String msgID) {
    _socket.emit('msg-recieved', {
      'senderID': senderID,
      'messageID': msgID,
    });
  }

  void messageSeen(String chatID, String messageID) {
    print('sending "I have seen" to chat');
    _socket.emit('msgs-seen', {
      'chatID': chatID,
      'messageID': messageID,
    });
  }

  void startDownload(String path) {
    _socket.emit('download', {'path': path});
  }

  void pauseDownload(String path) {
    _socket.emit('pause-download-$path');
  }

  void resumeDownload(String path) {
    _socket.emit('resume-download-$path');
  }

  void cancelDownload(String path) {
    _socket.emit('cancel-download-$path');
  }

  void searchName(name) {
    _socket.emit('search', name);
  }

  void typing(chatID) {
    _socket.emit('search', typing);
  }

  void validateStatus() {
    _socket.emit('validation');
  }

  void requestChatStatus(chatID) {
    _socket.emit('chat-status', chatID);
  }

  void sendMessage({
    required String chatID,
    required MessageModel message,
  }) {
    // final chatID = chat.id;
    final msg = message.message;
    final date = message.date.toIso8601String();
    final msgID = message.id;
    final type = getMessageTypeString(message.type);
    final mobilePath = message.filePath;
    final path = mobilePath == null ? null : getServerPath(mobilePath);
    final size = message.size;
    final fileName = path == null ? null : path.split('/').last;
    final decibels = message.decibels;
    final repliedToId = message.repliedToId;

    _socket.emit('new-msg', {
      'msgID': msgID,
      'chatID': chatID,
      'msg': msg,
      'date': date,
      'type': type,
      'file': {
        'path': path,
        'size': size,
        'name': fileName,
        'decibels': decibels,
        'repliedToId': repliedToId,
      },
    });
  }
}

Future<void> saveSearchChat(chatJson, context) async {
  final chat = Chat.fromJson(chatJson, context);
  chat.isAsearch = true;
  await Provider.of<ChatHiveBox>(
    context,
    listen: false,
  ).addUpdateChat(chat);
  chat.save();
}

MessageModel chatmsgToMsgobj(ChatMessage msg) {
  return MessageModel(
    id: msg.id,
    date: msg.dateTime,
    sender: msg.sender,
    message: msg.message,
    time: msg.time,
    isMe: msg.isMe,
    chatID: msg.chatID,
    type: msg.type,
    status: msg.status ?? MessageStatus.sending,
    filePath: msg.filePath,
    decibels: msg.decibels,
    index: msg.index,
    size: msg.size,
    repliedToId: msg.repliedToId,
  );
}

// ChatMessage msgobjToChatmsg(MessageModel msg) {
//   return ChatMessage(
//     id: msg.id,
//     dateTime: msg.date,
//     sender: msg.sender,
//     message: msg.message,
//     time: msg.time,
//     isMe: msg.isMe,
//     chatID: msg.chatID,
//     type: msg.type,
//     status: msg.status ?? MessageStatus.sending,
//     filePath: msg.filePath,
//     decibels: msg.decibels,
//     index: msg.index,
//     size: msg.size,
//     repliedToId: msg.repliedToId,
//   );
// }

class AccFiles {
  final String path;
  final String caption;
  final MessageType type;
  AccFiles({required this.path, required this.caption, required this.type});
}

String formatFileSize(int fileSizeInBytes) {
  if (fileSizeInBytes < 1024) {
    return '$fileSizeInBytes B';
  } else if (fileSizeInBytes < (1024 * 1024)) {
    final fileSizeInKB = fileSizeInBytes ~/ 1024;
    return '$fileSizeInKB KB';
  } else if (fileSizeInBytes < (1024 * 1024 * 1024)) {
    final fileSizeInMB = fileSizeInBytes ~/ (1024 * 1024);
    return '$fileSizeInMB MB';
  } else {
    final fileSizeInGB = fileSizeInBytes ~/ (1024 * 1024 * 1024);
    return '$fileSizeInGB GB';
  }
}

int getFileSize(String path) {
  final file = File(path);
  final fileExists = file.existsSync();

  if (fileExists) {
    final fileStat = file.statSync();
    return fileStat.size;
  } else {
    // Handle the case where the file does not exist
    return -1;
  }
}

String getDuration(DateTime pastDateTime) {
  Duration duration = DateTime.now().difference(pastDateTime);
  if (duration.inDays >= 365) {
    int years = (duration.inDays / 365).floor();
    return '$years year${years > 1 ? "s" : ""} ago';
  } else if (duration.inDays >= 30) {
    int months = (duration.inDays / 30).floor();
    return '$months month${months > 1 ? "s" : ""} ago';
  } else if (duration.inDays >= 7) {
    int weeks = (duration.inDays / 7).floor();
    return '$weeks week${weeks > 1 ? "s" : ""} ago';
  } else if (duration.inDays > 0) {
    return '${duration.inDays} day${duration.inDays > 1 ? "s" : ""} ago';
  } else if (duration.inHours > 0) {
    return '${duration.inHours} hour${duration.inHours > 1 ? "s" : ""} ago';
  } else if (duration.inMinutes > 0) {
    return '${duration.inMinutes} minute${duration.inMinutes > 1 ? "s" : ""} ago';
  } else {
    return 'just now';
  }
}

bool isSameDay(DateTime dateTime1, DateTime dateTime2) {
  return dateTime1.year == dateTime2.year &&
      dateTime1.month == dateTime2.month &&
      dateTime1.day == dateTime2.day;
}

String getTimeOrDate(DateTime dateTime, bool inTime) {
  DateTime now = DateTime.now();
  Duration difference = now.difference(dateTime);

  if (now.day == dateTime.day &&
      now.month == dateTime.month &&
      now.year == dateTime.year) {
    String timeOfDay = inTime
        ? '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
        : 'Today';
    return timeOfDay;
  } else if (difference.inDays == 0 || difference.inHours <= 24) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    String dayOfWeek = inTime
        ? toFullWeekday(dateTime.weekday).substring(0, 3)
        : toFullWeekday(dateTime.weekday);

    String timeOfDay =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return inTime ? '$dayOfWeek $timeOfDay' : dayOfWeek;
  } else if (difference.inDays > 7 && difference.inDays < 30) {
    String monthOfYear = inTime
        ? toFullWeekday(dateTime.weekday).substring(0, 3)
        : toFullWeekday(dateTime.weekday);

    return '${dateTime.day.toString().padLeft(2, '0')} $monthOfYear ${dateTime.year.toString().substring(2)}';
  } else {
    String day = dateTime.day.toString().padLeft(2, '0');
    String month = dateTime.month.toString().padLeft(2, '0');
    String year = dateTime.year.toString().substring(2);
    String formattedDateTime = "$day/$month/$year";
    return formattedDateTime;
  }
}

String getTimeFromDate(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

String getFormattedTime(int secondsElapsed) {
  int minutes = secondsElapsed ~/ 60;
  int seconds = secondsElapsed % 60;

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String toFullWeekday(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Monday';
    case DateTime.tuesday:
      return 'Tuesday';
    case DateTime.wednesday:
      return 'Wednesday';
    case DateTime.thursday:
      return 'Thursday';
    case DateTime.friday:
      return 'Friday';
    case DateTime.saturday:
      return 'Saturday';
    case DateTime.sunday:
      return 'Sunday';
    default:
      return '';
  }
}

String toFullMonth(int month) {
  switch (month) {
    case DateTime.january:
      return 'January';
    case DateTime.february:
      return 'Februray';
    case DateTime.march:
      return 'March';
    case DateTime.april:
      return 'April';
    case DateTime.may:
      return 'May';
    case DateTime.june:
      return 'June';
    case DateTime.july:
      return 'July';
    case DateTime.august:
      return 'August';
    case DateTime.september:
      return 'September';
    case DateTime.october:
      return 'October';
    case DateTime.november:
      return 'November';
    case DateTime.december:
      return 'December';
    default:
      return '';
  }
}

void setStatusBarTextDark() async {
  await FlutterStatusbarcolor.setStatusBarWhiteForeground(false);
  FlutterStatusbarcolor.setStatusBarColor(Colors.transparent);
}

void setStatusBarTextLight() async {
  await FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
  FlutterStatusbarcolor.setStatusBarColor(Colors.transparent);
}

void showPopupMessage(BuildContext context, String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
  );
  // final snackBar = SnackBar(content: Text(message));
  // ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

String getBluredPath(String path) {
  final name = path.split('/').last;
  final nameNoExt = name.split('.').first;
  final ext = name.split('.').last;

  final fileDirectory = Directory('${kAppDirectory.path}/Blured');
  if (!fileDirectory.existsSync()) {
    fileDirectory.createSync(recursive: true);
  }

  final bluredPath = '${fileDirectory.path}/${nameNoExt}_blured$ext';
  return bluredPath;
}

///Takes a cached path and will copy the file in this path to the app's document directory
///
///If the path inputed is already part of the app's document directory, it will return back the same file path
Future<String?> saveFileFromCache(String cachedPath, MessageType type) async {
  if (cachedPath.startsWith(kAppDirectory.path)) {
    return cachedPath;
  }

  try {
    final file = File(cachedPath);

    final folderName = switch (type) {
      MessageType.audio => 'Audios',
      MessageType.files => 'Documents',
      MessageType.image => 'Images',
      MessageType.video => 'Videos',
      _ => ''
    };
    final name = folderName.substring(0, 2).toUpperCase(); //AUD,DOC,IMG,VID
    final ext = cachedPath.split('.').last;

    final fileDirectory = Directory('${kAppDirectory.path}/$folderName');
    if (!fileDirectory.existsSync()) {
      fileDirectory.createSync(recursive: true);
    }

    final fileName = '${name}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final filePath = '${fileDirectory.path}/$fileName';

    await file.copy(filePath);
    print('Image saved to: $filePath');
    return filePath;
  } catch (e) {
    print('Error saving image: $e');
  }
  return null;
}

Future<String> avatarPath(String oldPath) async {
  final file = File(oldPath);

  const folderName = 'Profile Pictures';
  final name = folderName.substring(0, 2).toUpperCase();
  final ext = oldPath.split('.').last;

  final imageDirectory = Directory('${kAppDirectory.path}/$folderName');
  if (!imageDirectory.existsSync()) {
    imageDirectory.createSync(recursive: true);
  }

  final fileName = '${name}_${DateTime.now().millisecondsSinceEpoch}.$ext';
  final filePath = '${imageDirectory.path}/$fileName';

  await file.copy(filePath);

  return filePath;
}

Future<void> deleteFileFromCache(String fileName) async {
  try {
    final cacheDirectory = await getTemporaryDirectory();
    final filePath = '${cacheDirectory.path}/$fileName';

    final file = File(filePath);

    if (file.existsSync()) {
      await file.delete();
      print('File deleted from cache: $filePath');
    } else {
      print('File not found in cache: $filePath');
    }
  } catch (e) {
    print('Error deleting file from cache: $e');
  }
}

Future<void> saveImageToFile(String base64Data, String filePath) async {
  final Uint8List bytes = Uint8List.fromList(base64.decode(base64Data));
  final File imageFile = File(filePath);

  await imageFile.writeAsBytes(bytes);
  print('Image saved to $filePath');
}

String getMobilePath(String serverPath) {
  if (serverPath.contains(kAppDirectory.path)) {
    return serverPath;
  }

  if(!serverPath.startsWith('/')){
    serverPath = '/$serverPath';
  }

  return '${kAppDirectory.path}$serverPath';
}

String getServerPath(String mobilePath) {
  final start = kAppDirectory.path.length;
  if (!mobilePath.contains(kAppDirectory.path)) {
    return mobilePath;
  }

  return mobilePath.substring(start);
}

IconData? iconFromMessageType(type) {
  switch (type) {
    case MessageType.image:
      return Icons.image;
    case MessageType.video:
      return Icons.videocam;
    case MessageType.audio:
      return Icons.headphones_rounded;
    case MessageType.voice:
      return Icons.headphones_rounded;
    case MessageType.files:
      return Icons.file_present_rounded;
    default:
      return null;
  }
}

class UploadItem {
  String? selectedFilePath;
  double uploadProgress = 0.0;
  String uploadStatus = '';
  bool uploadPaused = false;
  int initOffset = 0;
  String fileId = '';
  late String name;
  late File file;

  UploadItem({required this.selectedFilePath}) {
    file = File(selectedFilePath!);
    name = file.path.split('/').last;
  }
}

class FileUploadProvider extends ChangeNotifier {
  // final kServerURL = 'http://192.168.1.138:1234';
  final List<UploadItem> _uploadItems = [];

  List<UploadItem> get uploadItems => _uploadItems;

  late BuildContext context;

  FileUploadProvider(this.context);

  void resetUploadItems() {
    final chats =
        Provider.of<ChatHiveBox>(context, listen: false).getAllChats();
    emptyUploadItems();
    for (final chat in chats) {
      for (final message in chat.messages) {
        if (message.status == MessageStatus.sending &&
            message.type != MessageType.text) {
          final item = UploadItem(selectedFilePath: message.filePath);
          _uploadItems.add(item);
        }
      }
    }
  }

  void addUploadItem(UploadItem item) {
    print('why');
    _uploadItems.add(item);
    notifyListeners();
  }

  void emptyUploadItems() {
    _uploadItems.length = 0;
  }

  void toggleUpload(UploadItem item) {
    print('upload button ${item.uploadStatus}');
    if (item.uploadStatus == 'Paused') {
      return resumeUpload(item);
    }
    if (item.uploadStatus == 'Uploading') {
      return pauseUpload(item);
    }
    if (item.uploadStatus == '' || item.uploadStatus == 'Request Failed') {}
    return startUpload(item);
  }

  void startUpload(UploadItem item) {
    if (!_uploadItems.contains(item)) {
      print('this uploaditem is not in UploadProvider');
      print(item.toString());
      return;
    }
    _uploadFile(item);
  }

  void pauseUpload(UploadItem item) {
    item.uploadPaused = true;
    item.uploadStatus = 'Paused';
    notifyListeners();
  }

  void resumeUpload(UploadItem item) {
    if (item.uploadPaused) {
      // Implement resuming the upload
      item.uploadPaused = false;
      item.uploadStatus = 'Resumed';
      notifyListeners();
      print('init: ${item.initOffset}');
      _chunkUpload(item);
    }
  }

  void clearUpload(UploadItem item) {
    // Implement clearing the upload
    _uploadItems.remove(item);
    notifyListeners();
  }

  Future<void> _uploadFile(UploadItem item) async {
    // Step 1: Request the server to create an upload request and get the fileId
    try {
      final path = item.selectedFilePath;
      final uploadID = item.name;
      final size = item.file.lengthSync();

      if (item.uploadStatus == 'Resumed') {
        item.uploadStatus = 'Uploading';
        await _chunkUpload(item);
      } else {
        final body = {
          'path': getServerPath(path!),
          'uploadID': uploadID,
          'size': size,
        };

        print(jsonEncode(body));

        final uploadRequestResponse = await http.post(
          Uri.parse('$kServerURL/upload-request'),
          body: jsonEncode(body),
          headers: {'Content-Type': 'application/json'},
          encoding: Encoding.getByName('utf-8'),
        );
        final code = json.decode(uploadRequestResponse.body)['message'];

        if (uploadRequestResponse.statusCode == 200) {
          // item.fileId = json.decode(uploadRequestResponse.body)['fileId'];

          // Step 2: Upload the file in chunks
          print('success');
          //send CNF to user if file does not exist
          if (code == 'CNF') return await _chunkUpload(item);

          //send FTM to user if file does not exist
          if (code == 'FTM') {
            print(
                'This file is already in the server so just forward the message');
            return;
          }
        } else {
          print(
              'request failed with status code ${uploadRequestResponse.statusCode}');
          print('mesage ${code}');
          // Handle upload request failure
          item.uploadStatus = 'Upload Request Failed';
          notifyListeners();
        }
      }
    } on Exception catch (e) {
      print(e);
      print('element');
    }
  }

  Future<void> _chunkUpload(UploadItem item) async {
    final totalBytes = item.file.lengthSync();
    const chunkSize = 1024 * 24; // 24KB chunks (adjust as needed)
    int uploadedBytes = item.initOffset;
    final path = item.file.path;
    final uploadID = item.name;

    final file = item.file;
    for (int offset = item.initOffset; offset < totalBytes;) {
      final fileBytes = file.readAsBytesSync();
      final sendingBytes =
          (offset + chunkSize <= totalBytes) ? chunkSize : totalBytes - offset;

      final chunk = fileBytes.buffer.asUint8List(
        offset,
        sendingBytes,
      );

      final body = {
        'path': getServerPath(path),
        'chunk': chunk,
        'offset': offset,
        'size': totalBytes,
        'uploadID': uploadID,
      };

      final response = await http.post(
        Uri.parse('$kServerURL/upload'),
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
        encoding: Encoding.getByName('utf-8'),
      );

      final message = jsonDecode(response.body);

      if (response.statusCode == 200) {
        offset += chunk.length;
        uploadedBytes += chunk.length;
        item.uploadProgress = offset / totalBytes;
        print(item.uploadProgress);

        if (!item.uploadPaused) {
          item.uploadStatus = 'Uploading';
        }
        notifyListeners();
        // print('uploadedBytes: $uploadedBytes');
        // print('totalBytes: $totalBytes');
      } else {
        print('request failed with status code ${response.statusCode}');
        print(message);
        // Handle upload failure
        item.uploadStatus = 'Upload Failed';
        notifyListeners();
        break;
      }

      if (item.uploadPaused) {
        // Handle pausing
        item.initOffset = offset;
        break;
      }
    }

    if (uploadedBytes == totalBytes) {
      print('Upload Completed');
      print('Upload Completed');
      print(uploadedBytes);
      print(uploadedBytes);
      item.uploadProgress = 1;
      item.initOffset = 0;
      item.uploadStatus = 'Upload Completed';

      if (item.uploadStatus == 'Upload Completed') {
        // ignore: use_build_context_synchronously
        sendChunkMessage(context, path);
      }
      notifyListeners();
    }
  }

  UploadItem getUploadItem(String path) {
    return _uploadItems.firstWhere((item) => item.selectedFilePath == path);
  }
}

class DownloadItem {
  late String fileName;
  final String path;
  File? file;
  int receivedBytes = 0;
  int totalBytes = 0;
  double get progress => receivedBytes / totalBytes;
  DownloadStatus status = DownloadStatus.notStarted;
  CancelToken cancelToken = CancelToken();
  StreamSubscription<List<int>>? downloadSubscription;

  DownloadItem({
    required this.path,
    required this.totalBytes,
  }) {
    fileName = path.split('/').last;
    file = File(path);
  }
}

enum DownloadStatus { notStarted, downloading, paused, completed }

class DownloadProvider with ChangeNotifier {
  // final String kServerURL = 'http://192.168.1.138:1234';

  final List<DownloadItem> _downloadItems = [];

  List<DownloadItem> get downloadItems => _downloadItems;

  final BuildContext context;

  DownloadProvider(this.context);

  void resetDownloadItems() {
    final chats =
        Provider.of<ChatHiveBox>(context, listen: false).getAllChats();
    emptyDownloadItems();
    for (final chat in chats) {
      for (final message in chat.messages) {
        if (message.type != MessageType.text) {
          final file = File(message.filePath!);
          final size = message.size;
          if ((!file.existsSync() || file.lengthSync() < size!)) {
            final item = DownloadItem(
              path: message.filePath!,
              totalBytes: size!,
            );
            _downloadItems.add(item);
          }
        }
      }
    }
  }

  void addDownloadItem(DownloadItem item) {
    _downloadItems.add(item);
    notifyListeners();
  }

  void emptyDownloadItems() {
    _downloadItems.length = 0;
  }

  Future<void> downloadFile(DownloadItem item) async {
    try {
      item.status = DownloadStatus.downloading;
      notifyListeners();

      if (!item.file!.existsSync()) {
        item.file!.createSync(recursive: true);
      }

      final dio = Dio();

      final fileLength = item.file!.lengthSync();
      final start = fileLength;
      const end = -1;
      final hed = 'bytes=$start-${end != -1 ? end : ''}';

      print(start);

      print(item.file!.lengthSync());

      final serverPath = getServerPath(item.file!.path);

      final response = await dio.get('$kServerURL/download',
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              HttpHeaders.rangeHeader: hed,
            },
          ),
          cancelToken: item.cancelToken,
          queryParameters: {
            'filePath': serverPath,
          });

      final headers = response.headers;
      final contentRange = headers.value(HttpHeaders.contentRangeHeader);
      final contentLength = int.parse(contentRange!.split('/').last.trim());

      final receivedStream = response.data.stream;

      item.downloadSubscription?.cancel();

      item.downloadSubscription = receivedStream.listen((List<int> data) {
        if (item.cancelToken.isCancelled) {
          item.downloadSubscription?.cancel();
          return;
        }
        item.file!.writeAsBytesSync(data, mode: FileMode.append);
        item.receivedBytes += data.length;
        notifyListeners();
      }, onDone: () {
        item.status = DownloadStatus.completed;

        final updaters = Provider.of<Updater>(context, listen: false).updaters;
        if (updaters.keys.contains(ChatScreen.id)) {
          final updatePage = updaters[ChatScreen.id];
          updatePage!();
        }
        if (updaters.keys.contains(ChatsScreen.id)) {
          final updatePage = updaters[ChatsScreen.id];
          updatePage!();
        }
        notifyListeners();
      });

      print('size: $contentLength');

      // item.totalBytes = contentLength;
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<void> pauseResumeDownload(DownloadItem item) async {
    if (item.status == DownloadStatus.downloading) {
      item.status = DownloadStatus.paused;
      item.cancelToken.cancel('Download paused');
    } else if (item.status == DownloadStatus.paused) {
      item.status = DownloadStatus.downloading;
      item.cancelToken = CancelToken();
      await downloadFile(item);
    } else {
      await downloadFile(item);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (DownloadItem item in _downloadItems) {
      item.cancelToken.cancel('Download canceled');
      item.downloadSubscription?.cancel();
    }
    super.dispose();
  }

  DownloadItem getDownloadItem(String path) {
    return _downloadItems.firstWhere((item) => item.path == path);
  }
}

void sendChunkMessage(BuildContext context, String path) {
  final socket = Provider.of<SocketIo>(context, listen: false);
  final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

  final chats = chatBox.getAllChats();

  for (final chat in chats) {
    final chatID = chat.id;
    for (final message in chat.messages) {
      if (message.filePath == path) {
        print('Testing the saving into DataBase');
        socket.sendMessage(chatID: chatID, message: message);
      }
    }
  }
}

class ChatModel {
  String name;
  String? avatar;
  bool? isGroup;
  String? time;
  String? currentMessage;
  String? status;
  bool select = false;
  String? id;
  ChatModel({
    required this.name,
    this.avatar,
    this.isGroup,
    this.time,
    this.currentMessage,
    this.status,
    this.select = false,
    this.id,
  });
}

class Updater extends ChangeNotifier {
  void Function()? updater;

  Map<String, void Function()> updaters = {};

  void setUpdateFunc(func) {
    updater = func;
    print(func.toString());
  }

  void addUpdater(key, func) {
    updaters[key] = func;
  }
}
