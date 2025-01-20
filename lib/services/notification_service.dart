import 'dart:convert';
import 'dart:math';

import 'package:blue_chat_v1/api_call.dart';
import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

const channelId = 'blue_chat_v1';
const channelName = 'Blue Chat V1';

Future<String> copyAssetToLocalFile(String assetPath, String fileName) async {
  final byteData = await rootBundle.load(assetPath);
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(byteData.buffer.asUint8List());
  return file.path;
}

class PushNotifications {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin()
        ..cancelAll();

  static void cancelAll() {
    _flutterLocalNotificationsPlugin.cancelAll();
  }

  // request notification permission
  static Future init() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
  }

  // get the fcm device token
  static Future getDeviceToken({int maxRetires = 3}) async {
    try {
      String? token;
      if (kIsWeb) {
        // get the device fcm token
        token = await _firebaseMessaging.getToken(
            vapidKey:
                "BPA9r_00LYvGIV9GPqkpCwfIl3Es4IfbGqE9CSrm6oeYJslJNmicXYHyWOZQMPlORgfhG8RNGe7hIxmbLXuJ92k");
        print("for web device token: $token");
      } else {
        // get the device fcm token
        token = await _firebaseMessaging.getToken();
        print("for android device token: $token");
      }
      return token;
    } catch (e) {
      print("failed to get device token");
      if (maxRetires > 0) {
        print("try after 10 sec");
        await Future.delayed(Duration(seconds: 10));
        return getDeviceToken(maxRetires: maxRetires - 1);
      } else {
        return null;
      }
    }
  }

  // initalize local notifications
  static Future localNotiInit() async {
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) => null,
    );
    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    // request notification permissions for android 13 or above
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .requestNotificationsPermission();

    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onNotificationResponse,
    );
  }

  static const replyAction = AndroidNotificationAction(
    'reply_action', // unique ID for the action
    'Reply',
    icon: null,
    allowGeneratedReplies: true,
    inputs: [AndroidNotificationActionInput(label: 'Type your message...')],
  );

  static const markAsRead = AndroidNotificationAction(
    'mark_as_read', // unique ID for the action
    'Mark as read',
    icon: null,
  );

  static void createGroupChatLocalNotification({
    String? userMessage,
    required Chat sender,
    required Chat groupChat,
    required MessageModel message,
  }) async {
    final id = groupChat.id;
    final groupName = groupChat.name;
    final groupAvatar = roundImageAndSave(File(groupChat.avatar)).path;
    final chatName = sender.name;
    final chatAvatar = roundImageAndSave(File(sender.avatar)).path;

    int numericId = addOrGetUniqueId(id);

    List<Message> messages = [
      Message(
        message.message,
        message.date,
        Person(
          name: chatName,
          key: chatName,
          icon: BitmapFilePathAndroidIcon(chatAvatar),
        ),
      ),
    ];

    // Add the user's message to the conversation
    if (userMessage != null && userMessage.isNotEmpty) {
      messages.add(
        Message(
          userMessage,
          DateTime.now(),
          const Person(
            name: 'You',
            key: 'you',
          ),
        ),
      );
    }

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelId,
      autoCancel: true,
      channelDescription: '$channelName description',
      largeIcon: FilePathAndroidBitmap(groupAvatar),
      styleInformation: MessagingStyleInformation(
        const Person(
          name: 'Group Chat',
          key: 'group',
        ),
        groupConversation: true,
        conversationTitle: groupName,
        messages: messages,
      ),
      actions: [replyAction, markAsRead],
    );

    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final payload = {
      'chatID': id,
      'messageID': message.id,
    };

    await _flutterLocalNotificationsPlugin.show(
      numericId,
      groupName,
      message.message,
      platformChannelSpecifics,
      payload: jsonEncode(payload),
    );
  }

  static void createChatLocalNotification({
    String? userMessage,
    required Chat chat,
    required MessageModel message,
  }) async {
    final id = chat.id;
    final name = chat.name;
    final avatarUrl = (chat.avatar);
    final rounded = roundImageAndSave(File(avatarUrl)).path;

    int numericId = addOrGetUniqueId(id);

    List<Message> messages = [
      Message(
        message.getNotificationMessage(),
        message.date,
        Person(
          name: name,
          key: name,
          icon: BitmapFilePathAndroidIcon(rounded),
        ),
      ),
    ];

    // Add the user's message to the conversation
    if (userMessage != null && userMessage.isNotEmpty) {
      messages.add(
        Message(
          userMessage,
          DateTime.now(),
          const Person(
            name: 'You',
            key: 'you',
          ),
        ),
      );
    }

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: '$channelName description',
      styleInformation: MessagingStyleInformation(
        const Person(
          name: 'Group Chat',
          key: 'group',
        ),
        messages: messages,
      ),
      actions: [replyAction, markAsRead],
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final payload = {
      'chatID': id,
      'messageID': message.id,
    };

    await _flutterLocalNotificationsPlugin.show(
      numericId,
      name,
      message.message,
      platformChannelSpecifics,
      payload: jsonEncode(payload),
    );
  }

  static Map<String, int> ids = {};

  static int addOrGetUniqueId(String key) {
    if (ids.containsKey(key)) {
      return ids[key]!;
    } else {
      Random random = Random();
      int newId;

      do {
        newId = random.nextInt(
            400); // Generate a random number between 0 and 4095 (12-bit number)
      } while (
          ids.containsValue(newId)); // Ensure the number is unique in the map

      ids[key] = newId;
      return newId;
    }
  }

  static Future<void> onNotificationResponse(
      NotificationResponse notificationResponse) async {
    await Hive.initFlutter('bluechat_database');

    if (!Hive.isAdapterRegistered(ChatAdapter().typeId))
      Hive.registerAdapter(ChatAdapter());
    if (!Hive.isAdapterRegistered(MessageModelAdapter().typeId))
      Hive.registerAdapter(MessageModelAdapter());
    if (!Hive.isAdapterRegistered(MessageTypeAdapter().typeId))
      Hive.registerAdapter(MessageTypeAdapter());
    if (!Hive.isAdapterRegistered(MessageStatusAdapter().typeId))
      Hive.registerAdapter(MessageStatusAdapter());

    final chatBox = ChatHiveBox(await Hive.openBox('chats'));
    final userBox = UserHiveBox(await Hive.openBox('user'));

    final encPayload = notificationResponse.payload;
    if (encPayload == null) return;
    final payload = jsonDecode(encPayload);
    final chatID = payload['chatID'];
    final messageID = payload['messageID'];

    if (notificationResponse.actionId == 'reply_action') {
      final String replyMessage = notificationResponse.input ?? 'No message';
      final String yourName = userBox.name;
      final chat = chatBox.getChat(chatID)!;

      DateTime now = DateTime.now();
      String timeOfDay =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final userID = userBox.id;

      final msgID = userID + chatID + now.toIso8601String();

      final message = MessageModel(
        id: msgID,
        sender: yourName,
        chatID: chatID,
        message: replyMessage,
        time: timeOfDay,
        date: now,
        isMe: true,
        type: MessageType.text,
        status: MessageStatus.sending,
      );

      chat.isAsearch = false;
      chat.messages.add(message);

      await chat.save();
      await sendMessageAPI(message: message, userBox: userBox, chatID: chatID);
      print('User replied: $replyMessage');
    }

    if (notificationResponse.actionId == 'mark_as_read') {
      await messageSeenAPI(
          chatID: chatID, messageID: messageID, userBox: userBox);

      print('User Marked as read');
    }

    await _flutterLocalNotificationsPlugin.cancel(notificationResponse.id!);

    // await userBox.closeBox();
    // await chatBox.closeBox();
  }

  static Future<void> handlePayload(Map<String, dynamic> payloadData) async {
    //SEND I HAVE RECEIVED MESSAGE

    final chatBox = ChatHiveBox(await Hive.openBox('chats'));
    final userBox = UserHiveBox(await Hive.openBox('user'));

    final event = payloadData['event'];
    final jsondata = (payloadData['data']);
    final initiatorID = payloadData['initiatorID'];

    final data = jsonDecode(jsondata);

    //Remove event from online notifications or stop if event is not more relevant
    final relevant = await removeEventFromNotif(
      event: event,
      data: jsondata,
      initiatorID: initiatorID,
      userBox: userBox,
    );

    if (!relevant) return;

    if (event == 'message') {
      final jsonMessage = data['message'];
      final senderID = data['senderID'];
      final jsonSender = data['sender'];
      final groupID = data['groupID'];
      final jsonGroup = data['group'];

      if (senderID == userBox.id) return;
      if (jsonSender != null) {
        final chat = Chat.fromJsonNotif(jsonSender); //can be group
        await chatBox.addUpdateChat(chat);
      }
      if (jsonGroup != null) {
        final groupChat = Chat.fromJsonNotif(jsonGroup);
        await chatBox.addUpdateChat(groupChat);
      }

      final sender = chatBox.getChat(senderID)!;
      await chatBox.addUpdateChat(sender);

      final message = await MessageModel.fromJsonNotif(jsonMessage, senderID);

      final type = message.type;

      if (type == MessageType.video || type == MessageType.image) {
        final path = message.filePath!;
        final imageData = jsonMessage['bluredFrame'];

        final bluredPath = getBluredPath(path);

        await saveImageToFile(imageData, bluredPath);
      }

      final localChat = chatBox.getChat(groupID ?? senderID)!;

      await messageRecievedAPI(
        chatID: localChat.id,
        userBox: userBox,
        messageID: message.id,
      );

      await localChat.addMessage(message);
      await localChat.save();

      if (localChat.isGroup) {
        createGroupChatLocalNotification(
          groupChat: localChat,
          sender: sender,
          message: message,
        );
      } else {
        createChatLocalNotification(
          chat: localChat,
          message: message,
        );
      }
    }
    if (event == 'msg-sent') {
      final messageID = data['messageID'];
      final receiverId = data['receiverId'];
      const kMessageStatus = MessageStatus.sent;

      final Chat chat = chatBox.getChat(receiverId)!;

      chat.updateMessageStatus(
        messageID,
        kMessageStatus,
        receiverId,
        DateTime.now(),
      );
    }
    if (event == 'msg-received') {
      final recieverID = data['recieverID'];
      final messageID = data['messageID'];
      final groupID = data['groupID'];

      final time = DateTime.parse(data["time"] as String);

      final chat = chatBox.getChat(groupID ?? recieverID)!;

      chat.updateMessageStatus(
        messageID,
        MessageStatus.received,
        recieverID,
        time,
      );
    }
    if (event == 'msgs-seen') {
      final chatID = data['recieverID'];
      final groupID = data['groupID'];
      final messageID = data['messageID'];
      final time = DateTime.parse(data["time"] as String);

      final chat = chatBox.getChat(groupID ?? chatID)!;

      chat.updateMessageStatus(messageID, MessageStatus.seen, chatID, time);
    }
    if (event == 'update-chat') {
      final chatID = data['id'];
      final members = data['members'];

      if (members != null) {
        for (final chatJson in members) {
          if (chatJson['id'] == userBox.id) continue;

          final chat = Chat.fromJsonNotif(chatJson);
          await chatBox.addUpdateChat(chat);
        }
      }

      // ignore: use_build_context_synchronously
      final List<dynamic> jsonMessages = data['messages'] ?? [];

      final chat = Chat.fromJsonNotif(data);

      await chatBox.addUpdateChat(chat);

      final localChat = chatBox.getChat(chatID);

      if (localChat == null) return print('Could not find chat');

      for (final jsonMessage in jsonMessages) {
        final MessageModel message =
            await MessageModel.fromJsonNotif(jsonMessage, chatID);
        await localChat.addMessage(message);
      }
    }

    await userBox.closeBox();
    await chatBox.closeBox();
  }
}
