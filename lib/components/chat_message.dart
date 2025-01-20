import 'dart:async';
import 'dart:io';

import 'package:blue_chat_v1/classes/chat_hive_box.dart';
import 'package:blue_chat_v1/classes/user_hive_box.dart';
import 'package:blue_chat_v1/providers/file_download.dart';
import 'package:blue_chat_v1/providers/file_upload.dart';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/screens/mediafiles_slider_screen.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ChatMessage extends StatefulWidget {
  final String sender;
  final String message;
  final DateTime dateTime;
  final String time;
  final bool isMe;
  final MessageType type;
  final MessageStatus? status;
  final String? filePath;
  final int? index;
  final String id;
  final List<double>? decibels;
  final Function scrollTo;
  final String? repliedToId;
  final int? size;
  final String chatID;

  ChatMessage({
    super.key,
    required this.sender,
    required this.chatID,
    required this.message,
    required this.time,
    required this.dateTime,
    required this.isMe,
    required this.type,
    required this.status,
    required this.id,
    required this.scrollTo,
    required this.repliedToId,
    this.filePath,
    this.index,
    this.decibels,
    this.size,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage>
    with AutomaticKeepAliveClientMixin<ChatMessage> {
  bool selected = false;
  double dx = 0;
  double originx = 0;
  double originy = 0;
  bool vM = false;

  @override
  bool get wantKeepAlive => true;

  String get chatID => widget.chatID;

  @override
  void dispose() {
    super.dispose();
  }

  void _showMessageInfo(
      BuildContext context, MessageModel message, bool isGroup) {
    final chatBox = Provider.of<ChatHiveBox>(context, listen: false);
    final userID = Provider.of<UserHiveBox>(context, listen: false).id;

    // if (!message.isMe) return;

    final isSending = message.status == MessageStatus.sending;

    final sendX = isSending ? 'Sending' : 'Sent';

    final icon1 = isSending
        ? getStatusIcon(MessageStatus.sending)
        : getStatusIcon(MessageStatus.sent);
    final icon2 = getStatusIcon(MessageStatus.received)!;
    final icon3 = getStatusIcon(MessageStatus.seen)!;

    final time1 = getDuration(message.date);

    final viewRecipts = message.readBy
        ?.map((deliveredRecipt) {
          if (deliveredRecipt.chatId == userID) {
            return null;
          }

          final chat = chatBox.getChat(deliveredRecipt.chatId)!;
          final deliveredTime = getDuration(deliveredRecipt.time);

          final seenBy = message.seenBy;

          final seenDate = (seenBy != null && seenBy.isNotEmpty)
              ? seenBy.firstWhere((element) => element.chatId == chat.id).time
              : null;
          final seenTime = seenDate == null ? '____' : getDuration(seenDate);

          final ppFile = File(chat.avatar);

          final CircleAvatar ppWidget;
          if (ppFile.existsSync()) {
            ppWidget = CircleAvatar(
              backgroundImage: FileImage(ppFile),
              radius: 20.0,
            );
          } else {
            ppWidget = const CircleAvatar(
              backgroundImage: AssetImage('assets/images/user.png'),
              radius: 20.0,
            );
          }

          return ListTile(
            leading: ppWidget,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
            title: Text(
              chat.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.0,
              ),
            ),
            subtitle: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      deliveredTime,
                      style: const TextStyle(
                        fontSize: 10.0,
                      ),
                    ),
                    Icon(
                      icon2,
                      size: 12.0,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      seenTime,
                      style: const TextStyle(
                        fontSize: 10.0,
                      ),
                    ),
                    Icon(icon3, size: 12.0, color: Colors.blue),
                  ],
                ),
              ],
            ),
          );
        })
        .whereType<ListTile>()
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Message info',
            style: TextStyle(fontSize: 30),
          ),
          content: SizedBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                  tileColor: Colors.grey.shade200,
                  title: Row(
                    children: [
                      Icon(
                        icon1,
                        size: 20.0,
                      ),
                      const SizedBox(
                        width: 5.0,
                      ),
                      Text(
                        '$sendX $time1',
                        style: const TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                    ],
                  ),
                  // subtitle: Text(
                  //   time1,
                  // ),
                ),
                const Divider(height: 1.0),
                if (viewRecipts != null && viewRecipts.isNotEmpty)
                  Container(
                    height: 500,
                    width: 300,
                    color: Colors.grey.shade200,
                    child: SingleChildScrollView(
                      child: Column(
                        children: viewRecipts.map((tile) {
                          return Column(
                            children: [
                              tile,
                              const Divider(height: 1.0),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    selected = Provider.of<Selection>(context).selectionMode ? selected : false;
    final chatBox = Provider.of<ChatHiveBox>(context, listen: false);

    final chat = chatBox.getChat(chatID)!;

    final message = chat.getMessageById(widget.id);

    final avatarUrl = chat.avatar;

    final ppFile = File(avatarUrl);

    final ppWidget = ppFile.existsSync()
        ? CircleAvatar(
            backgroundImage: FileImage(ppFile),
            radius: 25.0,
          )
        : const CircleAvatar(
            backgroundImage: AssetImage('assets/images/user.png'),
            radius: 25.0,
          );

    return Consumer<Selection>(
      builder: (context, selection, child) => Transform.translate(
        offset: Offset(dx, 0),
        child: GestureDetector(
          onTap: () async {
            print('$selected');
            if (selection.selectionMode) {
              setState(() {
                selected = !selected;
              });
              selection.incrementSelectedMessage(
                incrementing: selected,
                message: widget,
              );
            }
          },
          onDoubleTap: () {
            _showMessageInfo(context, message, chat.isGroup);
          },
          onLongPress: () async {
            if (!selection.selectionMode) {
              await HapticFeedback.vibrate();
            }
            setState(() {
              selected = !selected;
            });
            selection.incrementSelectedMessage(
              incrementing: selected,
              message: widget,
            );
          },
          onHorizontalDragStart: (DragStartDetails details) {
            micLongPressStartHandler(details);
          },
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            final newDx = details.localPosition.dx - originx;
            final newDy = details.localPosition.dy - originy;
            if (newDy > newDx || vM == true) {
              vM = true;
            } else {
              vM = false;
              micLongPressUpdateHandler(newDx, newDy);
            }
          },
          onHorizontalDragEnd: (details) async {
            !vM ? await micLongPressEndHandler(context) : null;
            vM = false;
          },
          child: Stack(
            children: [
              Container(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: widget.isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      widget.isMe ? const SizedBox() : ppWidget,
                      widget.isMe
                          ? const SizedBox(width: 30.0)
                          : RightAngleTriangleContainer(
                              width: 10.0,
                              height: 10.0,
                              color: Colors.blue[100]!,
                              isMe: false,
                            ),
                      Container(
                        decoration: BoxDecoration(
                          color:
                              widget.isMe ? Colors.grey[300] : Colors.blue[100],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(10.0),
                            topRight: const Radius.circular(10.0),
                            bottomLeft: widget.isMe
                                ? const Radius.circular(10.0)
                                : const Radius.circular(0.0),
                            bottomRight: widget.isMe
                                ? const Radius.circular(0.0)
                                : const Radius.circular(10.0),
                          ),
                        ),
                        padding: const EdgeInsets.all(4.0),
                        child: MessageContent(
                          widget: widget,
                          selected: selected,
                        ),
                      ),
                      widget.isMe
                          ? RightAngleTriangleContainer(
                              width: 10.0,
                              height: 10.0,
                              isMe: true,
                              color: Colors.grey[300]!,
                            )
                          : const SizedBox(width: 30.0),
                      // widget.isMe
                      //     ? CircleAvatar(
                      //         radius: 15.0,
                      //         backgroundImage: AssetImage('assets/images/nezuko.png'),
                      //       )
                      //     : const SizedBox(),
                    ],
                  ),
                ),
              ),
              (selection.selectionMode)
                  ? Positioned.fill(
                      child: Container(
                        color: selected
                            ? Color.fromARGB(88, 132, 199, 255)
                            : Colors.transparent,
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  void micLongPressStartHandler(DragStartDetails details) {
    originx = details.globalPosition.dx;
    originy = details.globalPosition.dy;
  }

  Future<void> micLongPressEndHandler(BuildContext context) async {
    try {
      if (dx > 20) {
        if (Platform.isAndroid || Platform.isIOS) {
          // Vibrate the device for a specified duration (e.g., 500 milliseconds)
          await HapticFeedback.vibrate();
        } else {
          print('Vibration is not supported on this platform.');
        }
        Provider.of<RepliedMessage>(context, listen: false)
            .update(chatmsgToMsgobj(widget));
      }

      setState(() {
        dx = 0;
        originx = 0;
        originy = 0;
      });
    } on Exception catch (e) {
      print(e);
    }
  }

  void micLongPressUpdateHandler(double newDx, double newDy) {
    setState(() {
      if (newDx > 10 && newDx < 700) {
        // dx = newDx - newDx;

        dx = newDx * ((700 - newDx) / 700);
      } else {
        dx = 0;
      }
    });
  }
}

// ignore: must_be_immutable
class MessageContent extends StatelessWidget {
  MessageContent({
    super.key,
    required this.widget,
    required this.selected,
    // this.videoPlayerController,
  });

  final bool selected;
  final ChatMessage widget;
  double maxWidth = 290.0;
  double minHeigth = 0.0;
  double maxHeigth = double.infinity;

  Widget getContent() {
    final path = widget.filePath ?? '';
    final type = widget.type;
    final isMe = widget.isMe;
    final status = getMessageStatusString(widget.status!);
    final file = File(path);

    if (type == MessageType.text) {
      return TextContent(message: widget.message);
    }

    if (type == MessageType.image) {
      if (isMe && status == 'sending') {
        return UploadableImage(
          widget: widget,
        );
      }
      if (file.existsSync() && file.lengthSync() == widget.size) {
        return ImageMsg(
          widget: widget,
        );
      }
      return DownloadableImage(
        widget: widget,
      );
    }

    if (type == MessageType.video) {
      if (isMe && status == 'sending') {
        return UploadableVideo(
          widget: widget,
        );
      }
      if (file.existsSync() && file.lengthSync() == widget.size) {
        return VideoMsg(
          widget: widget,
        );
      }
      return DownloadableVideo(
        widget: widget,
      );
    }

    if (type == MessageType.audio) {
      if (isMe && status == 'sending') {
        return UploadableAudio(
          widget: widget,
        );
      }

      if (file.existsSync() && file.lengthSync() >= widget.size!) {
        return AudioMsg(
          widget: widget,
        );
      }

      return DownloadableAudio(
        widget: widget,
      );
    }

    if (type == MessageType.files) {
      if (isMe && status == 'sending') {
        return UploadableFile(
          widget: widget,
        );
      }

      if (file.existsSync() && file.lengthSync() == widget.size) {
        return FileMsg(
          widget: widget,
        );
      }

      return DownloadableFile(
        widget: widget,
      );
    }

    return const Text('No message');
  }

  @override
  Widget build(BuildContext context) {
    final icon2 = getStatusIcon(widget.status!);

    final date = widget.dateTime;

    final time = getTimeFromDate(date);

    final type = widget.type;

    if (type == MessageType.files || type == MessageType.audio) {
      // if(type == MessageType.files)maxHeigth = 78.0;
      // if(type == MessageType.audio)maxHeigth = 67.0;
      // if(type == MessageType.audio)minHeigth = 60.0;
      maxWidth = 250;
      // maxHeigth = 80.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.repliedToId != null &&
                Provider.of<CurrentChat>(context, listen: false).openedChat !=
                    null
            ? Container(
                // constraints: BoxConstraints(
                //   maxWidth: maxWidth,
                //   maxHeight: maxHeigth,
                //   minHeight: minHeigth,
                // ),
                child: RepliedCard(
                  scrollTo: widget.scrollTo,
                  id: widget.repliedToId!,
                ),
              )
            : const SizedBox(),
        Container(
          // color: Colors.white,
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeigth,
            minHeight: minHeigth,
          ),
          child: widget.message != ''
              ? Container(
                  // color: Colors.green,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      getContent(),
                      Container(
                        // color: Colors.red,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12.0,
                              ),
                            ),
                            const SizedBox(
                              width: 1.0,
                            ),
                            icon2 != null && widget.isMe
                                ? Icon(
                                    icon2,
                                    color: widget.status == MessageStatus.seen
                                        ? Colors.blue
                                        : Colors.grey,
                                    size: 17.0,
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    getContent(),
                    Positioned(
                      // alignment: Alignment.bottomRight,
                      right: 4.0,
                      bottom: 3.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: widget.type == MessageType.image ||
                                  widget.type == MessageType.values
                              ? LinearGradient(
                                  colors: [
                                    Colors.black
                                        .withOpacity(0.0), // Transparent black
                                    Colors.black.withOpacity(
                                        0.5), // Semi-transparent black
                                    Colors.black
                                        .withOpacity(1.0), // Opaque black
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.0,
                              ),
                            ),
                            const SizedBox(
                              width: 1.0,
                            ),
                            icon2 != null && widget.isMe
                                ? Icon(
                                    icon2,
                                    color: widget.status == MessageStatus.seen
                                        ? Colors.blue
                                        : Colors.grey,
                                    // color: Colors.blue,
                                    size: 17.0,
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class RepliedCard extends StatelessWidget {
  const RepliedCard({
    super.key,
    required this.scrollTo,
    required this.id,
  });
  final Function scrollTo;
  final String id;

  @override
  Widget build(BuildContext context) {
    final currentChat = Provider.of<CurrentChat>(context, listen: false);

    int index = currentChat.openedChat!.messages
        .indexWhere((element) => element.id == id);

    String name = '';

    String messageValue = 'message was deleted';

    MessageModel? message;

    MessageType type = MessageType.text;

    if (index != -1) {
      name = currentChat.openedChat!.messages[index].sender;
      message = currentChat.openedChat!.messages[index];
      messageValue = message.message;
      type = message.type;
      messageValue = messageValue.length > 50
          ? '${messageValue.substring(0, 50)}...'
          : messageValue == ''
              ? getMessageTypeString(type)
              : messageValue;
    }

    final IconData? icon;

    switch (type) {
      case MessageType.image:
        icon = Icons.image;
        break;
      case MessageType.video:
        icon = Icons.videocam;
        break;
      case MessageType.audio:
        icon = Icons.headphones_rounded;
        break;
      case MessageType.voice:
        icon = Icons.headphones_rounded;
        break;
      case MessageType.files:
        icon = Icons.file_present_rounded;
        break;
      default:
        icon = null;
        break;
    }

    return InkWell(
      onTap: () {
        scrollTo(index);
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
          decoration: BoxDecoration(
            border: const Border(
              left: BorderSide(
                color: Colors.blue,
                width: 6.0,
              ),
            ),
            color: Colors.grey[400],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  icon != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Icon(icon, color: Colors.white, size: 18.0),
                        )
                      : const SizedBox(),
                  Text(messageValue),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

IconData? getStatusIcon(MessageStatus status) {
  switch (status) {
    // switch (MessageStatus.seen) {
    case MessageStatus.sending:
      return Icons.access_time_outlined;

    case MessageStatus.sent:
      return Icons.check;

    case MessageStatus.received:
      return Icons.done_all_rounded;

    case MessageStatus.seen:
      // return Icons.remove_red_eye_rounded;
      return Icons.done_all_rounded;

    default:
      return null;
  }
}

// Normal message

class FileMsg extends StatefulWidget {
  const FileMsg({
    super.key,
    required this.widget,
  });
  final ChatMessage widget;
  @override
  State<FileMsg> createState() => _FileMsgState();
}

class _FileMsgState extends State<FileMsg> {
  void openFile(String path) {
    OpenFile.open(path);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.widget.filePath ?? '';

    final file = File(path);

    final fileName = path.split('/').last;

    final name =
        fileName.length <= 45 ? fileName : '${fileName.substring(0, 45)}...';

    final fileExtension = fileName.split('.').last;

    final mimeType = lookupMimeType(file.path);

    String type = mimeType != null ? mimeType.split('/').last : fileExtension;

    type = type.length > 3 ? 'BIN' : type;

    final int fileSize = file.lengthSync();

    return GestureDetector(
      onTap: () {
        openFile(path);
      },
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: widget.widget.isMe ? Colors.grey[700] : Colors.blue[400]),
        padding: const EdgeInsets.all(5.0),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            type.toUpperCase() != 'PDF'
                ? Container(
                    decoration: BoxDecoration(color: Colors.blueGrey[800]),
                    alignment: Alignment.center,
                    height: 45.0,
                    width: 35.0,
                    child: Text(
                      type.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : SvgPicture.asset(
                    'assets/svg/pdf.svg',
                    width: 40.0,
                  ),
            const SizedBox(width: 10.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180,
                  child: Text(
                    '${name}',
                    softWrap: true,
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ),
                Text(
                  formatFileSize(fileSize),
                  style: TextStyle(
                    color: Colors.white38,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class AudioMsg extends StatefulWidget {
  const AudioMsg({
    super.key,
    required this.widget,
  });
  final ChatMessage widget;
  @override
  State<AudioMsg> createState() => _AudioMsgState();
}

class _AudioMsgState extends State<AudioMsg> {
  AudioPlayer audioPlayer = AudioPlayer();

  late StreamSubscription<PlayerState> playerStateSubscription;
  late StreamSubscription<Duration> durationSubscription;
  late StreamSubscription<Duration> positionSubscription;
  late StreamSubscription<void> playerCompleteSubscription;

  bool isPlaying = false;
  Duration audioDuration = Duration.zero;
  Duration audioPosition = Duration.zero;
  int secondsPlayed = 0;

  void initAudioPlayer() async {
    final path = widget.widget.filePath;

    audioPlayer.setReleaseMode(ReleaseMode.stop);
    audioPlayer.setSourceDeviceFile(path!);

    playerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });
    durationSubscription = audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          audioDuration = newDuration;
          secondsPlayed = newDuration.inSeconds;
        });
      }
    });
    positionSubscription = audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          audioPosition = newPosition;
          secondsPlayed = newPosition.inSeconds;
        });
      }
    });
    playerCompleteSubscription = audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          secondsPlayed = audioDuration.inSeconds;
        });
      }
    });
  }

  @override
  void initState() {
    initAudioPlayer();
    super.initState();
  }

  @override
  void dispose() {
    disposeAudioPlayer();
    super.dispose();
  }

  void disposeAudioPlayer() {
    playerStateSubscription.cancel();
    durationSubscription.cancel();
    positionSubscription.cancel();
    playerCompleteSubscription.cancel();

    audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatMsg = widget.widget;

    List<double>? decibels = chatMsg.decibels;

    decibels = decibels ?? [];

    final bool isDecibeled = decibels.isNotEmpty;
    int index = 0;

    return Padding(
      padding: const EdgeInsets.only(left: 3.0, top: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.teal,
                size: 35.0,
              ),
              onPressed: () async {
                if (isPlaying) {
                  await audioPlayer.pause();
                } else {
                  await audioPlayer.resume();
                }
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      isDecibeled
                          ? Padding(
                              padding: const EdgeInsets.only(left: 9.0),
                              child: Row(
                                children: decibels.map((double decibel) {
                                  index = decibels!.indexOf(decibel) == 0
                                      ? 0
                                      : index;

                                  final duration = audioDuration.inMicroseconds;

                                  double position = (isPlaying || duration > 0)
                                      ? (audioPosition.inMicroseconds /
                                              audioDuration.inMicroseconds) *
                                          45
                                      : 0;

                                  int decibelIndex = index;
                                  index++;
                                  int currentIndex = position.floor();

                                  double colorRatio = position - currentIndex;

                                  double value;
                                  if (decibel < 15) {
                                    value = 15;
                                  } else if (decibel > 55) {
                                    value = 55;
                                  } else {
                                    value = decibel;
                                  }
                                  final double height = ((value.abs() - 15) *
                                          (3 / 4)) +
                                      5; // Scale the decibel value to the height range of 0-100 pixels
                                  double width = 0;

                                  if (decibelIndex < currentIndex) {
                                    width = 3.0;
                                  } else if (decibelIndex > currentIndex) {
                                    width = 0;
                                  } else {
                                    width = colorRatio * 3;
                                  }

                                  return Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 0.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                        ),
                                        height: height,
                                        width: 3.0,
                                        // child:
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                        ),
                                        height: height,
                                        width: width,
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            )
                          : const SizedBox(),
                      Padding(
                        padding: EdgeInsets.only(
                            top: 7.0,
                            right: 4.0,
                            bottom: 10.0,
                            left: (isDecibeled ? 0 : 5.0)),
                        child: Opacity(
                          opacity: isDecibeled ? 0 : 1,
                          child: SliderTheme(
                            data: SliderThemeData(
                              overlayShape: SliderComponentShape.noOverlay,
                              thumbColor: Colors.green,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: isDecibeled ? 10 : 5,
                              ),
                              valueIndicatorColor: Colors.lightGreenAccent,
                              activeTrackColor: Colors.lightBlueAccent,
                              trackShape: const RectangularSliderTrackShape(),
                              trackHeight: 3.0,
                            ),
                            child: Slider(
                              min: 0,
                              max: audioDuration.inMilliseconds.toDouble() /
                                  1000,
                              value: audioPosition.inMilliseconds.toDouble() /
                                  1000,
                              onChanged: (value) async {
                                final position = Duration(
                                    milliseconds: (value * 1000).toInt());
                                await audioPlayer.seek(position);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      getFormattedTime(
                        isPlaying
                            ? audioPosition.inSeconds
                            : audioDuration.inSeconds,
                      ),
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 15.0),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImageMsg extends StatelessWidget {
  const ImageMsg({
    super.key,
    required this.widget,
  });
  final ChatMessage widget;
  @override
  Widget build(BuildContext context) {
    final chatMsg = widget;
    final path = chatMsg.filePath ?? '';

    final chat = Provider.of<ChatHiveBox>(context).getChat(chatMsg.chatID)!;

    // print(screenSize.width);
    // print(screenSize.height);

    // final fileDimension = getImageDimensions(path);

    return VideoImageFile(
      onPress: () {
        if (!Provider.of<Selection>(context, listen: false).selectionMode) {
          Navigator.push(
            context,
            FadePageRoute(
              builder: ((context) => ImageSliderPage(
                    initialIndex: chatMsg.index!,
                    chat: chat,
                  )),
            ),
          );
        }
      },
      widgetFile: Hero(
        tag: 'chatImage ${chatMsg.index}',
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          width: screenSize.width.toDouble() * 0.75,
          height: 350,
        ),
      ),
      widget: widget,
    );
  }
}

// img.Image? getImageDimensions(String path) {
//   final File file = File(path);
//   final img.Image? image = img.decodeImage(file.readAsBytesSync());

//   if (image != null) {
//     print('Width: ${image.width}, Height: ${image.height}');
//   } else {
//     print('Unable to decode image.');
//   }
//   return image;
// }

class VideoMsg extends StatefulWidget {
  const VideoMsg({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;

  @override
  State<VideoMsg> createState() => _VideoMsgState();
}

class _VideoMsgState extends State<VideoMsg> {
  VideoPlayerController? videoPlayerController;
  String? thumbnailPath;

  @override
  void initState() {
    super.initState();
    generateThumbnail();
  }

  @override
  void dispose() {
    videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> generateThumbnail() async {
    final chatMsg = widget.widget;
    final path = chatMsg.filePath ?? '';

    try {
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: kTempDirectory.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 1000, // specify the height of the thumbnail
        quality: 100,
      );

      setState(() {
        thumbnailPath = thumbPath;
      });
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatMsg = widget.widget;
    final chat = Provider.of<ChatHiveBox>(context).getChat(chatMsg.chatID)!;

    return VideoImageFile(
      onPress: () {
        if (!Provider.of<Selection>(context, listen: false).selectionMode) {
          Navigator.push(
            context,
            FadePageRoute(
              builder: ((context) => ImageSliderPage(
                    initialIndex: chatMsg.index!,
                    chat: chat,
                  )),
            ),
          );
        }
      },
      widget: widget.widget,
      widgetFile: Stack(
        alignment: Alignment.center,
        children: [
          thumbnailPath != null
              ? Hero(
                  tag: 'chatImage ${widget.widget.index}',
                  child: Image.file(
                    File(thumbnailPath!),
                    fit: BoxFit.cover,
                    width: screenSize.width.toDouble() * 0.75,
                    height: 350,
                  ),
                )
              : Container(
                  color: Colors.black12,
                ),
          const CircleAvatar(
            radius: 33,
            backgroundColor: Colors.black38,
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 50,
            ),
          ),
        ],
      ),
    );
  }
}
// Upload & Download widgets

class UploadableImage extends StatelessWidget {
  const UploadableImage({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;
  @override
  Widget build(BuildContext context) {
    final path = widget.filePath!;
    return VideoImageFile(
      widget: widget,
      widgetFile: Stack(
        alignment: Alignment.center,
        children: [
          Image.file(
            File(path),
            fit: BoxFit.cover,
            width: screenSize.width.toDouble() * 0.75,
            height: 350,
          ),
          UploadButtonMedia(
            widget: widget,
          ),
        ],
      ),
      onPress: () {},
    );
  }
}

class UploadableVideo extends StatefulWidget {
  const UploadableVideo({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;

  @override
  State<UploadableVideo> createState() => _UploadableVideoState();
}

class _UploadableVideoState extends State<UploadableVideo> {
  String? thumbnailPath;

  @override
  void initState() {
    super.initState();
    generateThumbnail();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> generateThumbnail() async {
    final chatMsg = widget.widget;
    final path = chatMsg.filePath ?? '';

    try {
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: kTempDirectory.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 1000, // specify a higher height for better quality
        quality: 100, // set to maximum quality
      );

      setState(() {
        thumbnailPath = thumbPath;
      });
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return VideoImageFile(
      widget: widget.widget,
      widgetFile: Stack(
        alignment: Alignment.center,
        children: [
          thumbnailPath != null
              ? Image.file(
                  File(thumbnailPath!),
                  fit: BoxFit.cover,
                  width: screenSize.width.toDouble() * 0.75,
                  height: 350,
                )
              : Container(),
          const CircleAvatar(
            radius: 33.0,
            backgroundColor: Colors.black38,
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 50.0,
            ),
          ),
          Positioned(
            bottom: 10.0,
            left: 10.0,
            child: UploadButtonMedia(
              widget: widget.widget,
            ),
          ),
        ],
      ),
      onPress: () {
        // Add your onPress functionality here
      },
    );
  }
}

class UploadableFile extends StatelessWidget {
  const UploadableFile({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;
  @override
  Widget build(BuildContext context) {
    final path = widget.filePath!;
    final fileSize = widget.size!;
    final fileName = path.split('/').last;

    final name =
        fileName.length <= 45 ? fileName : '${fileName.substring(0, 45)}...';

    final fileExtension = fileName.split('.').last;

    return GestureDetector(
      onTap: () {
        // openFile(path);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: widget.isMe ? Colors.grey[700] : Colors.blue[400],
        ),
        padding: const EdgeInsets.all(5.0),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            fileExtension.toUpperCase() != 'PDF'
                ? Container(
                    decoration: BoxDecoration(color: Colors.blueGrey[800]),
                    alignment: Alignment.center,
                    height: 45.0,
                    width: 35.0,
                    child: Text(
                      fileExtension.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : SvgPicture.asset(
                    'assets/svg/pdf.svg',
                    width: 40.0,
                  ),
            const SizedBox(width: 10.0),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(
                      name,
                      softWrap: true,
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ),
                  Text(
                    formatFileSize(fileSize),
                    style: const TextStyle(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: UploadButtonFile(
                widget: widget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadableAudio extends StatelessWidget {
  const UploadableAudio({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;
  @override
  Widget build(BuildContext context) {
    final fileSize = widget.size!;

    print('1234567890');

    return Padding(
      padding: const EdgeInsets.only(left: 3.0, top: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey,
            child: UploadButtonFile(
              widget: widget,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 7.0,
                      right: 4.0,
                      bottom: 10.0,
                      left: 5.0,
                    ),
                    child: Opacity(
                      opacity: 1,
                      child: SliderTheme(
                        data: SliderThemeData(
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbColor: Colors.green,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 0,
                          ),
                          valueIndicatorColor: Colors.lightGreenAccent,
                          activeTrackColor: Colors.lightBlueAccent,
                          trackShape: const RectangularSliderTrackShape(),
                          // trackShape: SliderTrackShape.,
                          // overlayColor: Colors.white,
                          // tickMarkShape: SliderTickMarkShape.noTickMark,
                          trackHeight: 3.0,
                        ),
                        child: Slider(
                          value: 0,
                          onChanged: (double value) {},
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      formatFileSize(fileSize),
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 15.0),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadableFile extends StatelessWidget {
  const DownloadableFile({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;
  @override
  Widget build(BuildContext context) {
    final path = widget.filePath!;
    final fileSize = widget.size!;
    final fileName = path.split('/').last;

    final name =
        fileName.length <= 45 ? fileName : '${fileName.substring(0, 45)}...';

    final fileExtension = fileName.split('.').last;

    return GestureDetector(
      onTap: () {
        // openFile(path);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: widget.isMe ? Colors.grey[700] : Colors.blue[400],
        ),
        padding: const EdgeInsets.all(5.0),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            fileExtension.toUpperCase() != 'PDF'
                ? Container(
                    decoration: BoxDecoration(color: Colors.blueGrey[800]),
                    alignment: Alignment.center,
                    height: 45.0,
                    width: 35.0,
                    child: Text(
                      fileExtension.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : SvgPicture.asset(
                    'assets/svg/pdf.svg',
                    width: 40.0,
                  ),
            const SizedBox(width: 10.0),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(
                      name,
                      softWrap: true,
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ),
                  Text(
                    formatFileSize(fileSize),
                    style: const TextStyle(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            DownloadButtonFile(
              widget: widget,
            ),
          ],
        ),
      ),
    );
  }
}

class DownloadableAudio extends StatelessWidget {
  const DownloadableAudio({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;
  @override
  Widget build(BuildContext context) {
    final fileSize = widget.size!;

    return Padding(
      padding: const EdgeInsets.only(left: 3.0, top: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey,
            child: DownloadButtonFile(
              widget: widget,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 7.0,
                      right: 4.0,
                      bottom: 10.0,
                      left: 5.0,
                    ),
                    child: Opacity(
                      opacity: 1,
                      child: SliderTheme(
                        data: SliderThemeData(
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbColor: Colors.green,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 0,
                          ),
                          valueIndicatorColor: Colors.lightGreenAccent,
                          activeTrackColor: Colors.lightBlueAccent,
                          trackShape: const RectangularSliderTrackShape(),
                          // trackShape: SliderTrackShape.,
                          // overlayColor: Colors.white,
                          // tickMarkShape: SliderTickMarkShape.noTickMark,
                          trackHeight: 3.0,
                        ),
                        child: Slider(
                          value: 0,
                          onChanged: (double value) {},
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      formatFileSize(fileSize),
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 15.0),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadableImage extends StatelessWidget {
  const DownloadableImage({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;
  @override
  Widget build(BuildContext context) {
    final path = getBluredPath(widget.filePath!);

    return VideoImageFile(
      widget: widget,
      widgetFile: Stack(
        alignment: Alignment.center,
        children: [
          Image.file(
            File(path),
            fit: BoxFit.cover,
            width: screenSize.width.toDouble() * 0.75,
            height: 350,
          ),
          DownloadButtonMedia(
            widget: widget,
          ),
        ],
      ),
      onPress: () {},
    );
  }
}

class DownloadableVideo extends StatelessWidget {
  const DownloadableVideo({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;

  @override
  Widget build(BuildContext context) {
    final path = getBluredPath(widget.filePath!);
    return VideoImageFile(
      widget: widget,
      widgetFile: Stack(
        alignment: Alignment.center,
        children: [
          Image.file(
            File(path),
            fit: BoxFit.cover,
            width: screenSize.width.toDouble() * 0.75,
            height: 350,
          ),
          const CircleAvatar(
            radius: 33.0,
            backgroundColor: Colors.black38,
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 50.0,
            ),
          ),
          Positioned(
            bottom: 10.0,
            left: 10.0,
            child: DownloadButtonMedia(
              widget: widget,
            ),
          ),
        ],
      ),
      onPress: () {},
    );
  }
}

// Upload & Download buttons

class DownloadButtonFile extends StatelessWidget {
  const DownloadButtonFile({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;

  @override
  Widget build(BuildContext context) {
    final path = widget.filePath!;

    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);
    final downloadItem = downloadProvider.getDownloadItem(path);

    return InkWell(onTap: () {
      downloadProvider.pauseResumeDownload(downloadItem);
    }, child: Consumer<DownloadProvider>(
      builder: (context, provider, child) {
        final downloadItem = provider.getDownloadItem(path);
        final isDownloading =
            (downloadItem.status == DownloadStatus.downloading);
        final progress = downloadItem.progress;
        return Padding(
          padding: const EdgeInsets.all(5.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  border: Border.all(color: Colors.grey),
                ),
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: isDownloading
                      ? progress == 0
                          ? null
                          : progress
                      : 0,
                  color: Colors.green,
                  strokeWidth: 3.0,
                ),
              ),
              Icon(
                isDownloading ? Icons.close : Icons.download_rounded,
                color: Colors.white,
                size: 25.0,
              )
            ],
          ),
        );
      },
    ));
  }
}

class DownloadButtonMedia extends StatelessWidget {
  const DownloadButtonMedia({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;

  @override
  Widget build(BuildContext context) {
    final path = widget.filePath!;

    final downloadProvider =
        Provider.of<DownloadProvider>(context, listen: false);
    final downloadItem = downloadProvider.getDownloadItem(path);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          downloadProvider.pauseResumeDownload(downloadItem);
        },
        child: Container(
          padding: const EdgeInsets.all(1.3),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Consumer<DownloadProvider>(
            builder: (context, provider, child) {
              final downloadItem = provider.getDownloadItem(path);
              final isDownloading =
                  (downloadItem.status == DownloadStatus.downloading);

              final file = downloadItem.file;
              String size;
              if (file == null) {
                print('is null');
                size = formatFileSize(widget.size!);
              } else {
                if (downloadItem.receivedBytes > 0) {
                  print('is not null and not empty');
                  size = formatFileSize(downloadItem.receivedBytes);
                } else {
                  print('is not null');
                  size = formatFileSize(widget.size!);
                }
              }

              // final size = formatFileSize(widget.size!);

              print(downloadItem.file);
              final progress = downloadItem.progress;
              return !isDownloading
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.download_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(
                            width: 12.0,
                          ),
                          Text(
                            size,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 48,
                          width: 48,
                          child: CircularProgressIndicator(
                            value: isDownloading
                                ? progress == 0
                                    ? null
                                    : progress
                                : 0,
                            strokeWidth: 3.0,
                            color: Colors.green,
                          ),
                        ),
                        const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 25.0,
                        ),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}

class UploadButtonFile extends StatelessWidget {
  const UploadButtonFile({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;

  @override
  Widget build(BuildContext context) {
    final path = widget.filePath!;

    final uploadProvider =
        Provider.of<FileUploadProvider>(context, listen: false);
    final uploadItem = uploadProvider.getUploadItem(path);

    return InkWell(
      onTap: () {
        uploadProvider.toggleUpload(uploadItem);
      },
      child: UploadFileListener(
        widget: widget,
      ),
    );
  }
}

class UploadFileListener extends StatelessWidget {
  const UploadFileListener({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;

  @override
  Widget build(BuildContext context) {
    final path = widget.filePath!;

    final uploadProvider = Provider.of<FileUploadProvider>(context);
    final uploadItem = uploadProvider.getUploadItem(path);
    final isUploading = uploadItem.uploadStatus == 'Uploading';

    final progress = uploadItem.uploadProgress;

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              border: Border.all(color: Colors.grey),
            ),
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: isUploading
                  ? progress == 0
                      ? null
                      : progress
                  : 0,
              color: Colors.green,
              strokeWidth: 3.0,
            ),
          ),
          Icon(
            isUploading ? Icons.close : Icons.upload_rounded,
            color: Colors.white,
            size: 25.0,
          ),
        ],
      ),
    );
  }
}

class UploadButtonMedia extends StatelessWidget {
  const UploadButtonMedia({
    super.key,
    required this.widget,
  });

  final ChatMessage widget;

  @override
  Widget build(BuildContext context) {
    final path = widget.filePath!;

    final uploadProvider =
        Provider.of<FileUploadProvider>(context, listen: false);
    final uploadItem = uploadProvider.getUploadItem(path);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          uploadProvider.toggleUpload(uploadItem);
        },
        child: Container(
          padding: const EdgeInsets.all(1.3),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Consumer<FileUploadProvider>(
            builder: (context, provider, child) {
              final uploadItem = provider.getUploadItem(path);
              final isUploading = uploadItem.uploadStatus == 'Uploading';
              final length =
                  uploadItem.file.lengthSync() - uploadItem.initOffset;
              final size = formatFileSize(length);
              final progress = uploadItem.uploadProgress;

              print('path: $path');
              print('isUploading: $isUploading');
              print('UploadItem: ${uploadItem.initOffset}');

              return !isUploading
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.upload_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(
                            width: 12.0,
                          ),
                          Text(
                            size,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 48.0,
                          width: 48.0,
                          child: CircularProgressIndicator(
                            value: isUploading
                                ? progress == 0
                                    ? null
                                    : progress
                                : 0,
                            strokeWidth: 5.0,
                            color: Colors.green,
                          ),
                        ),
                        const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 25.0,
                        ),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}

class VideoImageFile extends StatelessWidget {
  const VideoImageFile({
    super.key,
    required this.widget,
    required this.widgetFile,
    required this.onPress,
  });

  final ChatMessage widget;
  final Widget widgetFile;
  final Function() onPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 2.0),
            constraints: BoxConstraints(
              maxHeight: 400,
            ),
            child: GestureDetector(
              onTap: onPress,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: widgetFile,
              ),
            ),
          ),
          TextContent(message: widget.message)
        ],
      ),
    );
  }
}

class TextContent extends StatelessWidget {
  const TextContent({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return message != ''
        ? Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 6.0),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16.0,
              ),
            ),
          )
        : const SizedBox();
  }
}
