import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/main.dart';
import 'package:blue_chat_v1/providers/file_download.dart';
import 'package:blue_chat_v1/screens/chat_screen.dart';
import 'package:blue_chat_v1/screens/chats.dart';
import 'package:blue_chat_v1/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketIo extends ChangeNotifier {
  late IO.Socket _socket;

  List<Map<String, dynamic>> _messageQueue = [];

  bool get exist => _exist;

  bool get isConnected => _socket.connected;

  String token = '';

  bool _exist = false;

  AudioPlayer audioPlayer = AudioPlayer();

  void _sendQueuedMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? queuedMessagesJson = prefs.getString('messageQueue');
    if (queuedMessagesJson != null) {
      List<Map<String, dynamic>> queuedMessages =
          List<Map<String, dynamic>>.from(json.decode(queuedMessagesJson));

      _messageQueue = [];
      prefs.remove('messageQueue');

      print('messages queued:');
      for (Map<String, dynamic> message in queuedMessages) {
        String event = message['event'];
        String data = message['data'];

        _sendMessage(event, json.decode(data));
      }
    }
  }

  void _queueMessage(String event, dynamic data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _messageQueue.add({'event': event, 'data': json.encode(data)});

    String messageQueueJson = json.encode(_messageQueue);

    await prefs.setString('messageQueue', messageQueueJson);
  }

  void _sendMessage(String event, dynamic data, {bool? volatile}) {
    if (volatile == true) {
      return _socket.emit(event, data);
    }

    if (_socket.connected) {
      _socket.emit(event, data);
    } else {
      _queueMessage(event, data);
    }
  }

  void connectSocket(context) async {
    final UserHiveBox userBox =
        Provider.of<UserHiveBox>(context, listen: false);

    final String email = userBox.email;
    token = userBox.token;

    _socket = IO.io(
      kServerURL,
      IO.OptionBuilder().setTransports(['websocket']).setQuery(
          {'email': email, 'token': token}).build(),
    );

    _exist = true;

    _socket.onConnect((_) {
      print('socket connected');
      final currentChatProvider =
          Provider.of<CurrentChat>(context, listen: false);
      if (currentChatProvider.openedChat != null) {
        requestChatStatus(currentChatProvider.openedChat?.id);
      }
      _sendQueuedMessages();
      // notifyListeners();
      //send all sending messages to server
    });

    _socket.onDisconnect((_) {
      print('socket disconnected');
      notifyListeners();
    });

    _socket.onConnectError((err) => print(err));
    _socket.onError((err) => print(err));

    _socket.connect();

    final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

    addEventListener('success', (data) => _onSuccess(userBox, token));

    addEventListener(
        'new-messages', (data) => _onNewMessages(data, chatBox, context));

    addEventListener('searched', (data) => _onSearched(data, chatBox, context));

    addEventListener(
        'update-status', (data) => _onUpdateStatus(data, chatBox, context));

    addEventListener(
        'update-chat', (data) => _onUpdateChat(data, context, chatBox));

    addEventListener(
        'msg-sent', (data) => _onMessageSent(data, chatBox, context));

    addEventListener(
        'msg-recieved', (data) => _onMessageReceived(data, chatBox, context));

    addEventListener(
        'msgs-seen', (data) => _onMessageSeen(data, context, chatBox));

    addEventListener('message', (data) => _onMessage(data, context, chatBox));

    addEventListener('typing', (data) => _onTyping(chatBox, data, context));

    _socket.emit('token', token);
  }

  void addEventListener(String event, Function func) {
    if (!_socket.hasListeners(event)) {
      _socket.on(event, (data) async {
        try {
          await func(data);
        } catch (e) {
          print(e);
        }
      });
    } else {
      print('has already this listener');
    }
  }

  void _onUpdateChat(chatJson, context, ChatHiveBox chatBox) async {
    final chatID = chatJson['id'];
    final members = chatJson['members'];
    final userBox = UserHiveBox(await Hive.openBox('user'));

    if (members != null) {
      for (final chatJson in members) {
        if (chatJson['id'] == userBox.id) continue;
        final chat = Chat.fromJson(chatJson, context);
        await chatBox.addUpdateChat(chat);
      }
    }

    // ignore: use_build_context_synchronously
    final List<dynamic> jsonMessages = chatJson['messages'] ?? [];

    final chat = Chat.fromJson(chatJson, context);

    await chatBox.addUpdateChat(chat);

    final localChat = chatBox.getChat(chatID);

    if (localChat == null) return print('Could not find chat');

    for (final jsonMessage in jsonMessages) {
      final MessageModel message =
          MessageModel.fromJson(jsonMessage, chatID, context);
      await localChat.addMessage(message);
    }

    final updaters = Provider.of<Updater>(context, listen: false).updaters;
    if (updaters.keys.contains(ChatScreen.id)) {
      final updatePage = updaters[ChatScreen.id];
      updatePage!();
    }
    if (updaters.keys.contains(ChatsScreen.id)) {
      final updatePage = updaters[ChatsScreen.id];
      updatePage!();
    }
  }

  void _onTyping(ChatHiveBox chatBox, typerID, context) {
    final chat = chatBox.getChat(typerID)!;
    chat.typing(context);
  }

  Future<void> _onMessage(data, context, ChatHiveBox chatBox) async {
    final jsonMessage = data['message'];
    final senderID = data['senderID'];
    final jsonSender = data['sender'];
    final groupID = data['groupID'];
    final jsonGroup = data['group'];

    final userBox = Provider.of<UserHiveBox>(context, listen: false);
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

    final localChat = chatBox.getChat(groupID ?? senderID)!;

    await localChat.addMessage(message);
    await localChat.save();

    final updaters = Provider.of<Updater>(context, listen: false).updaters;
    final currentChat = Provider.of<CurrentChat>(context, listen: false);
    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);

    if (type != MessageType.text) {
      final file = File(message.filePath!);
      final size = message.size;
      if ((!file.existsSync() || file.lengthSync() < size!)) {
        final item = DownloadItem(
          path: message.filePath!,
          totalBytes: size!,
        );
        downloadProvider.addDownloadItem(item);
      }
      final path = message.filePath!;

      if (type == MessageType.video || type == MessageType.image) {
        final imageData = jsonMessage['bluredFrame'];

        final bluredPath = getBluredPath(path);

        await saveImageToFile(imageData, bluredPath);
      }
    }

    messageRecieved(senderID, message.id);

    if (updaters.keys.contains(ChatScreen.id)) {
      final updatePage = updaters[ChatScreen.id];
      updatePage!();
    }
    if (updaters.keys.contains(ChatsScreen.id)) {
      final updatePage = updaters[ChatsScreen.id];
      updatePage!();
    }

    if (routeObserver.currentRoute == ChatScreen.id &&
        currentChat.openedChat!.id == localChat.id) {
      //sound wawawawawa
      playChatSound(false);
      messageSeen(senderID, message.id);
    } else if (routeObserver.currentRoute != ChatsScreen.id) {
      //create notification
      if (localChat.isGroup) {
        final senderChat = chatBox.getChat(senderID)!;
        PushNotifications.createGroupChatLocalNotification(
          sender: localChat,
          groupChat: senderChat,
          message: message,
        );
      } else {
        PushNotifications.createChatLocalNotification(
          chat: localChat,
          message: message,
        );
      }
    }
  }

  Future<void> _onMessageSeen(data, context, ChatHiveBox chatBox) async {
    final chatID = data['recieverID'];
    final groupID = data['groupID'];
    final messageID = data['messageID'];

    final time = DateTime.parse(data["time"] as String);

    final chat = chatBox.getChat(groupID ?? chatID)!;

    chat.updateMessageStatus(messageID, MessageStatus.seen, chatID, time);

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
  }

  Future<void> _onMessageReceived(data, ChatHiveBox chatBox, context) async {
    final recieverID = data['recieverID'];
    final messageID = data['messageID'];
    final groupID = data['groupID'];

    final time = DateTime.parse(data["time"] as String);

    final chat = chatBox.getChat(groupID ?? recieverID)!;

    chat.updateMessageStatus(
        messageID, MessageStatus.received, recieverID, time);

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
  }

  void _onMessageSent(data, ChatHiveBox chatBox, context) {
    final messageID = data['messageID'];
    final receiverId = data['receiverId'];
    const kMessageStatus = MessageStatus.sent;

    final Chat chat = chatBox.getChat(receiverId)!;


    chat.updateMessageStatus(
        messageID, kMessageStatus, receiverId, DateTime.now());

    final updaters = Provider.of<Updater>(context, listen: false).updaters;
    final currentChat = Provider.of<CurrentChat>(context, listen: false);

    if (updaters.keys.contains(ChatScreen.id)) {
      final updatePage = updaters[ChatScreen.id];
      updatePage!();
    }
    if (updaters.keys.contains(ChatsScreen.id)) {
      final updatePage = updaters[ChatsScreen.id];
      updatePage!();
    }

    if (routeObserver.currentRoute == ChatScreen.id &&
        currentChat.openedChat!.id == receiverId) {
      playChatSound(true);
      //sound tuc
    }
  }

  Future<void> _onUpdateStatus(data, ChatHiveBox chatBox, context) async {
    final chatID = data['id'];
    final status = data['status'] ?? 'offline';
    final lastSeen = data['lastSeen'] != null
        ? DateTime.parse(data['lastSeen'])
        : DateTime.now();

    final currentChatProvider =
        Provider.of<CurrentChat>(context, listen: false);

    final chat = chatBox.getChat(chatID)!;

    print('${chat.name} is $status');
    if (status == 'offline')
      print('lastSeen at ${getTimeOrDate(lastSeen, true)}');

    await chat.updateStatus(status, lastSeen);

    String val;
    if (status == 'online') {
      val = status;
    } else {
      val = 'last seen ${getDuration(lastSeen)}';
    }
    currentChatProvider.updateLastSeen(val);

    print(currentChatProvider.openedChat);
  }

  Future<void> _onSearched(chatInfoList, ChatHiveBox chatBox, context) async {
    for (final chatJson in chatInfoList) {
      final chatID = chatJson['id'];
      if (chatBox.isChat(chatID)) {
        continue;
      }
      await saveSearchChat(chatJson, context);
    }
  }

  Future<void> _onNewMessages(data, ChatHiveBox chatBox, context) async {
    print('getting notifications');

    final updatedChatsJson = data?['chatUpdates'] ?? [];

    final updatedMsgsJson = data?[' '] ?? [];

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
        await chatBox.addUpdateChat(chat);
      }

      final chat = chatBox.getChat(chatID);

      if (chat == null) {
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
            MessageModel.fromJson(jsonMessage, chat.id, context);
        await chat.addMessage(message);
      }
    }

    ///To Update Messages
    for (final updatedMsgJson in updatedMsgsJson) {
      final messageStatus = updatedMsgJson['messageStatus'];
      final chatID = updatedMsgJson['chatID'];
      final messageID = updatedMsgJson['messageID'];
      final readSeenByJson = updatedMsgJson['receivedSeenBy'];
      final chat = chatBox.getChat(chatID);

      if (chat == null) {
        // print('Chats have not yet being completely saved');
        print('chat(part1) is empty');
        continue;
      }

      ReadSeenBy recievedSeenBy = ReadSeenBy.fromJson(readSeenByJson);

      if (messageStatus == 'seen') {
        chat.makeMyMessageSeen(
          messageID,
          recievedSeenBy.chatId,
          recievedSeenBy.time,
        );
        continue;
      }
      //else it's recieved
      chat.updateMessageStatus(
        messageID,
        messageStatus,
        recievedSeenBy.chatId,
        recievedSeenBy.time,
      );
    }

    final updaters = Provider.of<Updater>(context, listen: false).updaters;
    if (updaters.keys.contains(ChatScreen.id)) {
      final updatePage = updaters[ChatScreen.id];
      updatePage!();
    }
    if (updaters.keys.contains(ChatsScreen.id)) {
      final updatePage = updaters[ChatsScreen.id];
      updatePage!();
    }

    print('all done');
  }

  Future<void> _onSuccess(UserHiveBox userBox, token) async {
    await userBox.saveToken(token);
  }

  void disconnect() {
    print('EXITING SOCKET!!!!');
    _socket.dispose();
    _socket.destroy();
    _exist = false;
  }

  void messageRecieved(String senderID, String msgID) {
    const event = 'msg-recieved';
    final data = {
      'senderID': senderID,
      'messageID': msgID,
    };

    _sendMessage(event, data);
  }

  void messageSeen(String chatID, String messageID) {
    const event = 'msgs-seen';
    final data = {
      'chatID': chatID,
      'messageID': messageID,
    };

    _sendMessage(event, data);
  }

  void searchName(name) {
    const event = 'search';
    final data = name;

    _sendMessage(event, data, volatile: true);
  }

  void typing(chatID) {
    const event = 'typing';
    final data = chatID;

    _sendMessage(event, data, volatile: true);
  }

  void requestChatStatus(chatID) {
    const event = 'chat-status';
    final data = chatID;

    _sendMessage(event, data);
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
    final fileName = path?.split('/').last;
    final decibels = message.decibels;
    final repliedToId = message.repliedToId;

    const event = 'new-msg';
    final data = {
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
    };

    _sendMessage(event, data);
  }

  void playChatSound(bool isMsgSent) async {
    final soundName = isMsgSent
        ? 'audio/message-sent2.mp3'
        : 'audio/message.mp3';

    await audioPlayer.play(AssetSource(soundName));
  }
}
