import 'package:blue_chat_v1/classes/chat.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';

class ImageSliderPage extends StatefulWidget {
  final int initialIndex;

  final Chat chat;

  ImageSliderPage({required this.initialIndex, required this.chat});

  @override
  _ImageSliderPageState createState() => _ImageSliderPageState();
}

class _ImageSliderPageState extends State<ImageSliderPage> {
  // VideoPlayerController? videoPlayerController;

  int _currentIndex = 0;

  PageController? _pageController;

  final List<VideoPlayerController> _videoPlayerControllers = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    initVideoPlayers();
  }

  void initVideoPlayers() {
    final medias = widget.chat.getMediaMessages();

    for (final media in medias) {
      final String path = media.filePath!;
      if (media.type == MessageType.video) {
        final videoPlayerController = VideoPlayerController.file(File(path))
          ..addListener(update)
          ..initialize();

        videoPlayerController.addListener(() {
          if (!videoPlayerController.value.isPlaying &&
              videoPlayerController.value.isInitialized) {
            videoPlayerController.pause();
          }
        });

        _videoPlayerControllers.add(videoPlayerController);
      }
    }
  }

  void freeControllers() {
    for (VideoPlayerController videoPlayerController
        in _videoPlayerControllers) {
      videoPlayerController.removeListener(update);
      videoPlayerController.dispose();
    }
  }

  @override
  void dispose() {
    freeControllers();
    super.dispose();
  }

  void update() {
    if (mounted) setState(() {});
  }

  double opacity = 1.0;
  double dy = 0.0;
  double dx = 0.0;
  bool _pagingEnabled = true;

  @override
  Widget build(BuildContext context) {
    final mediaMsgs = widget.chat.getMediaMessages();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 22, 26, 31),
        title: mediaMsgs[_currentIndex].isMe
            ? Text('You')
            : Text(Provider.of<CurrentChat>(context).openedChat!.name),
      ),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: Container(
                color: Colors.black,
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (details) {
                if (details.pointerCount > 1) {
                  _pagingEnabled = false;
                }
              },
              onScaleEnd: (d) {
                _pagingEnabled = true;
              },
              onVerticalDragUpdate: (details) {
                dy += details.delta.dy;
                final double ratio = (dy / MediaQuery.of(context).size.height);
                if ((dy < -25 || dy > 25) && _pagingEnabled) {
                  print('not scaling');

                  opacity = ratio > 0 ? 1.0 - 3 * (ratio) : 1.0 + 3 * (ratio);
                  opacity = opacity > 1.0 ? 1.0 : opacity;
                  opacity = opacity < 0.0 ? 0.0 : opacity;
                  setState(() {});
                }
              },
              onVerticalDragEnd: (details) {
                if (opacity < 0.2) {
                  // freeControllers();
                  Navigator.pop(context);
                } else {
                  setState(() {
                    opacity = 1.0;
                    dy = 0.0;
                  });
                }
              },
              child: Opacity(
                opacity: 1.0,
                child: Transform.translate(
                  offset: Offset(0.0, _pagingEnabled ? dy - 25 : 0.0),
                  child: PageView.builder(
                    physics: (_pagingEnabled)
                        ? const PageScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemCount: mediaMsgs.length,
                    controller: _pageController,
                    onPageChanged: (newIndex) {
                      setState(() {
                        _currentIndex = newIndex;
                        for (VideoPlayerController videoPlayerController
                            in _videoPlayerControllers) {
                          videoPlayerController.pause();
                        }
                      });
                    },
                    itemBuilder: (context, index) {
                      final medias = widget.chat.getMediaMessages();
                      final media = medias[index];
                      final String path = media.filePath!;
                      if (media.type == MessageType.video) {
                        final videos = medias
                            .where((media) => media.type == MessageType.video)
                            .toList();

                        int vIndex = videos
                            .indexWhere((video) => video.filePath == path);

                        final controller = _videoPlayerControllers[vIndex];

                        return Column(
                          children: [
                            Expanded(
                              child: (widget.initialIndex == index)
                                  ? Hero(
                                      tag: 'chatImage ${media.id}',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: MyVideoPlayer(
                                          controller: controller,
                                          withProgressBar: false,
                                        ),
                                      ),
                                    )
                                  : Material(
                                      color: Colors.transparent,
                                      child: MyVideoPlayer(
                                        controller: controller,
                                        withProgressBar: true,
                                      ),
                                    ),
                            ),
                          ],
                        );
                      } else if (media.type == MessageType.image) {
                        return Column(
                          children: [
                            Expanded(
                              child: (widget.initialIndex == index)
                                  ? Hero(
                                      tag: 'chatImage ${media.id}',
                                      child: PhotoView(
                                        backgroundDecoration:
                                            const BoxDecoration(
                                          color: Colors.transparent,
                                        ),
                                        gestureDetectorBehavior:
                                            HitTestBehavior.opaque,
                                        imageProvider: FileImage(File(path)),
                                      ),
                                    )
                                  : PhotoView(
                                      backgroundDecoration: const BoxDecoration(
                                        color: Colors.transparent,
                                      ),
                                      gestureDetectorBehavior:
                                          HitTestBehavior.opaque,
                                      imageProvider: FileImage(File(path)),
                                    ),
                            ),
                            Opacity(
                              opacity: opacity,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                decoration:
                                    const BoxDecoration(color: Colors.black54),
                                child: Text(
                                  media.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.0,
                                  ),
                                ),
                              ),
                            )
                          ],
                        );
                      } else {
                        return const Placeholder();
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyVideoPlayer extends StatefulWidget {
  const MyVideoPlayer({
    super.key,
    required this.controller,
    required this.withProgressBar,
  });

  final VideoPlayerController controller;

  final bool withProgressBar;

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  // late VideoPlayerController controller;
  void listener() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void initState() {
    controller.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(listener);
    super.dispose();
  }

  VideoPlayerController get controller => widget.controller;
  bool get isPlaying => widget.controller.value.isPlaying;
  bool get needsProgress => widget.withProgressBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: MediaQuery.of(context).size.height,
      // width: MediaQuery.of(context).size.width,
      child: controller.value.isInitialized
          ? Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(
                            controller,
                          ),
                        ),
                      ),
                      InkWell(
                        child: CircleAvatar(
                          radius: 33,
                          backgroundColor: Colors.black38,
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                        onTap: () {
                          isPlaying ? controller.pause() : controller.play();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20.0,
                ),
                if(needsProgress)
                SizedBox(
                  height: 25,
                  child: MyVideoProgressIndicator(
                    controller,
                  ),
                )
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            ),
    );
  }
}

class MyVideoProgressIndicator extends StatefulWidget {
  const MyVideoProgressIndicator(
    this.controller, {
    super.key,
    this.colors = const VideoProgressColors(),
    this.padding = const EdgeInsets.only(top: 5.0),
  });

  /// The [VideoPlayerController] that actually associates a video with this
  /// widget.
  final VideoPlayerController controller;

  final VideoProgressColors colors;

  final EdgeInsets padding;

  @override
  State<MyVideoProgressIndicator> createState() =>
      _MyVideoProgressIndicatorState();
}

class _MyVideoProgressIndicatorState extends State<MyVideoProgressIndicator> {
  _MyVideoProgressIndicatorState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
  }

  late VoidCallback listener;

  VideoPlayerController get controller => widget.controller;

  VideoProgressColors get colors => widget.colors;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (controller.value.isInitialized) {
      final int duration = controller.value.duration.inMilliseconds;
      final int position = controller.value.position.inMilliseconds;

      int maxBuffering = 0;
      for (final DurationRange range in controller.value.buffered) {
        final int end = range.end.inMilliseconds;
        if (end > maxBuffering) {
          maxBuffering = end;
        }
      }

      return Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                getFormattedTime(controller.value.isPlaying
                    ? controller.value.position.inSeconds
                    : 0),
                style: const TextStyle(color: Colors.grey, fontSize: 15.0),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 7.0,
                  right: 4.0,
                  bottom: 10.0,
                  left: (5.0),
                ),
                child: Opacity(
                  opacity: 1,
                  child: SliderTheme(
                    data: SliderThemeData(
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbColor: Colors.blue,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      valueIndicatorColor: Colors.lightGreenAccent,
                      activeTrackColor: Colors.blue,
                      trackShape: const RoundedRectSliderTrackShape(),
                      trackHeight: 5.0,
                    ),
                    child: Slider(
                      min: 0,
                      max: duration.toDouble() / 1000,
                      value: position.toDouble() / 1000,
                      onChanged: (value) async {
                        final position =
                            Duration(milliseconds: (value * 1000).toInt());
                        await controller.seekTo(position);
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                getFormattedTime(controller.value.duration.inSeconds),
                style: const TextStyle(color: Colors.grey, fontSize: 15.0),
              ),
            )
          ],
        ),
      );
    } else {
      return LinearProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(colors.playedColor),
        backgroundColor: colors.backgroundColor,
      );
    }
  }
}
