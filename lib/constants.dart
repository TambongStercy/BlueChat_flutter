import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/screens/chat_screen.dart';
import 'package:blue_chat_v1/screens/chats.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/components/chat_message.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

const serverHost = '192.168.1.101:3000';

const kServerURL =
    'http://$serverHost'; //type ipConfig in cmd to see pc's ip address
// const kServerURL = 'http://10.0.2.2:3000'; //for emulators only

late Directory kAppDirectory;
late Directory kTempDirectory;

Size screenSize = const Size(410, 700);

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

  RouteSettings? routeSettings;

  SlideRightToLeftPageRoute({required this.builder, this.routeSettings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          settings: routeSettings,
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
  String _lastSeen = '';

  Chat? get openedChat {
    return _chat;
  }

  String get lastSeen {
    return _lastSeen;
  }

  void updateLastSeen(String value) {
    _lastSeen = value;
    notifyListeners();
  }

  void addChat(Chat chat) {
    _chat = null;
    _chat = chat;
    notifyListeners();
  }

  void empty() {
    print('EMPTYING CURRENT CHAT');
    _chat = null;
    _lastSeen = '';
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
        ? toFullMonth(dateTime.month).substring(0, 3)
        : toFullMonth(dateTime.month);

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
  // final ext = name.split('.').last;

  final fileDirectory = Directory('${kAppDirectory.path}/Blured');
  if (!fileDirectory.existsSync()) {
    fileDirectory.createSync(recursive: true);
  }

  final bluredPath = '${fileDirectory.path}/${nameNoExt}_blured.png';
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
    print('File saved to: $filePath');
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

  if (!serverPath.startsWith('/')) {
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
  Map<String, void Function()> updaters = {};

  void addUpdater(key, func) {
    updaters[key] = func;
  }

  void updateChatScreen() {
    if (updaters.keys.contains(ChatScreen.id)) {
      final updatePage = updaters[ChatScreen.id];
      updatePage!();
    }
  }

  void updateChatsScreen() {
    if (updaters.keys.contains(ChatsScreen.id)) {
      final updatePage = updaters[ChatsScreen.id];
      updatePage!();
    }
  }
}

File roundImageAndSave(File imageFile) {
  // Read the image file into a `img.Image` object
  img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;

  // Create a square canvas with dimensions of the smallest side
  int size = image.width < image.height ? image.width : image.height;
  img.Image squareImage = img.copyResizeCropSquare(image, size);

  // Create a circular mask
  img.Image mask = img.Image(size, size);
  img.fill(mask, img.getColor(0, 0, 0, 0));
  img.fillCircle(
      mask, size ~/ 2, size ~/ 2, size ~/ 2, img.getColor(255, 255, 255, 255));

  // Apply the mask to the image
  img.Image roundedImage = img.Image(size, size);
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      int pixel = squareImage.getPixel(x, y);
      int maskPixel = mask.getPixel(x, y);
      if (maskPixel == img.getColor(255, 255, 255, 255)) {
        roundedImage.setPixel(x, y, pixel);
      } else {
        roundedImage.setPixel(x, y, img.getColor(0, 0, 0, 0));
      }
    }
  }

  // Generate the new file path with "_rounded" added to the file name
  String newFilePath = getRoundedPath(imageFile.path);

  // Save the image to the new file path
  final roundedImageFile = File(newFilePath);
  roundedImageFile.writeAsBytesSync(img.encodePng(roundedImage));

  return roundedImageFile;
}

String getRoundedPath(String filePath) {
  String directory = path.dirname(filePath);
  String filenameWithoutExtension = path.basenameWithoutExtension(filePath);
  String extension = path.extension(filePath);
  String newFilePath =
      path.join(directory, '${filenameWithoutExtension}_rounded$extension');

  return newFilePath;
}
