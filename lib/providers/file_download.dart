import 'dart:async';
import 'dart:io';

import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/screens/chat_screen.dart';
import 'package:blue_chat_v1/screens/chats.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    if (!file!.existsSync()) {
      file!.createSync(recursive: true);
    }
    receivedBytes = file!.lengthSync();

    if (receivedBytes == totalBytes) {
      status = DownloadStatus.completed;
    }
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

    for (final chat in chats) {
      for (final message in chat.messages) {
        if (message.type != MessageType.text) {
          final file = File(message.filePath!);
          final size = message.size;
          if ((!file.existsSync() || file.lengthSync() < size!)) {
            final path = message.filePath;

            if (path == null) return;

            if (isDownloadItem(path)) continue;

            final item = DownloadItem(
              path: path,
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

  void _emptyDownloadItems() {
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

      final serverPath = getServerPath(item.file!.path);

      final response = await dio.get(
        '$kServerURL/download',
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            HttpHeaders.rangeHeader: hed,
          },
        ),
        cancelToken: item.cancelToken,
        queryParameters: {
          'filePath': serverPath,
        },
      );

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
    } catch (e) {
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

  bool isDownloadItem(String? path) {
    return _downloadItems.any((item) => item.path == path);
  }
}
