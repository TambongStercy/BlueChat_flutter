import 'dart:convert';
import 'dart:io';

import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/providers/socket_io.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class UploadItem {
  String? selectedFilePath;
  double uploadProgress = 0.0;
  String uploadStatus = '';
  bool uploadPaused = false;
  int initOffset = 0;
  late String name;
  late File file;

  UploadItem({required this.selectedFilePath}) {
    file = File(selectedFilePath!);
    name = file.path.split('/').last;
    initOffset = Hive.box('uploadBox').get(name, defaultValue: 0);
  }

  void saveInitOffset() {
    Hive.box('uploadBox').put(name, initOffset);
  }
}

class FileUploadProvider extends ChangeNotifier {
  final List<UploadItem> _uploadItems = [];

  List<UploadItem> get uploadItems => _uploadItems;

  late BuildContext context;

  FileUploadProvider(this.context);

  void resetUploadItems() {
    final chats =
        Provider.of<ChatHiveBox>(context, listen: false).getAllChats();
    for (final chat in chats) {
      for (final message in chat.messages) {
        if (message.status == MessageStatus.sending &&
            message.type != MessageType.text) {
          
          final path = message.filePath;

          if (isUploadItem(path)) continue;
          

          final item = UploadItem(selectedFilePath: path);
          _uploadItems.add(item);
        }
      }
    }
  }

  void addUploadItem(UploadItem item) {
    _uploadItems.add(item);
    notifyListeners();
  }

  void _emptyUploadItems() {
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
    item.saveInitOffset();
    notifyListeners();
  }

  void resumeUpload(UploadItem item) {
    if (item.uploadPaused) {
      item.uploadPaused = false;
      item.uploadStatus = 'Resumed';
      notifyListeners();
      print('init: ${item.initOffset}');
      _chunkUpload(item);
    }
  }

  void clearUpload(UploadItem item) {
    _uploadItems.remove(item);
    notifyListeners();
  }

  Future<void> _uploadFile(UploadItem item) async {
    try {
      final path = item.selectedFilePath;
      final initOffset = item.initOffset;
      final size = item.file.lengthSync();

      if (item.uploadStatus == 'Resumed') {
        item.uploadStatus = 'Uploading';
        await _chunkUpload(item);
      } else {
        final body = {
          'path': getServerPath(path!),
          'size': size,
          'initOffset': initOffset
        };

        final uploadRequestResponse = await http.post(
          Uri.parse('$kServerURL/upload-request'),
          body: jsonEncode(body),
          headers: {'Content-Type': 'application/json'},
          encoding: Encoding.getByName('utf-8'),
        );
        final code = json.decode(uploadRequestResponse.body)['message'];

        if (uploadRequestResponse.statusCode == 200) {
          if (code == 'CNF') return await _chunkUpload(item);
          if (code == 'FTM') {
            print(
                'This file is already in the server so just forward the message');
            return;
          }
        } else {
          print(
              'request failed with status code ${uploadRequestResponse.statusCode}');
              
          item.uploadStatus = 'Upload Request Failed';
          notifyListeners();
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _chunkUpload(UploadItem item) async {
    final totalBytes = item.file.lengthSync();
    const chunkSize = 1024 * 24;
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

        if (!item.uploadPaused) {
          item.uploadStatus = 'Uploading';
        }
        notifyListeners();
      } else {
        print('request failed with status code ${response.statusCode}');
        print(message);
        item.uploadStatus = 'Upload Failed';
        notifyListeners();
        break;
      }

      item.saveInitOffset();

      if (item.uploadPaused) {
        item.initOffset = offset;
        break;
      }
    }

    if (uploadedBytes == totalBytes) {
      item.uploadStatus = 'Upload Completed';
      item.uploadProgress = 1;
      item.initOffset = 0;
      sendChunkMessage(context, path);

      notifyListeners();
    }
  }

  UploadItem getUploadItem(String path) {
    return _uploadItems.firstWhere((item) => item.selectedFilePath == path);
  }

  bool isUploadItem(String? path) {
    return (_uploadItems.any((item) => item.selectedFilePath == path));
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
        // saving into DataBase Online
        socket.sendMessage(chatID: chatID, message: message);
      }
    }
  }
}
