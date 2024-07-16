import 'package:audioplayers/audioplayers.dart';
import 'package:blue_chat_v1/constants.dart';
import 'package:flutter/material.dart';
import 'package:blue_chat_v1/screens/camera_screen.dart';
import 'package:blue_chat_v1/components/modal_send_files.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_sound/flutter_sound.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:blue_chat_v1/constants.dart';
import 'package:blue_chat_v1/classes/message.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:provider/provider.dart';
// import 'package:vibration/vibration.dart';

class BottomTextField extends StatefulWidget {
  BottomTextField({
    super.key,
    required this.emojiShowing,
    required this.textEditingController,
    required this.focusNode,
    required this.toggleEmojiPicker,
    required this.draft,
    required this.changeDraft,
    required this.addMessage,
    required this.addFileMessage,
    required this.updatePage,
  });

  final bool emojiShowing;
  final String draft;
  final TextEditingController textEditingController;
  final FocusNode focusNode;
  final Function changeDraft;
  final Function toggleEmojiPicker;
  final Function addMessage;
  final Function addFileMessage;
  final Function updatePage;

  @override
  State<BottomTextField> createState() => _BottomTextFieldState();
}

class _BottomTextFieldState extends State<BottomTextField>
    with TickerProviderStateMixin {

  AudioPlayer audioStart = AudioPlayer();
  AudioPlayer audioCancel = AudioPlayer();
  AudioPlayer audioStop = AudioPlayer();
  String draft = '';
  String url = '';
  Timer? decibelTimer;
  int timeElapsed = 0;
  double decibels = 0;
  double x = 0;
  double pi = 3.14159;
  double dx = 0;
  double dy = 0;
  bool vM = false;
  bool hM = false;
  bool _isRecording = false;
  bool _isCanceling = false;
  bool _isLockedRecording = false;
  // bool _isLockedCanceling = false;
  bool _isPaused = false;
  bool _micAccess = false;
  AnimationController? _animationController;
  AnimationController? _animationController1;
  AnimationController? _animationController2;
  AnimationController? _animationController3; //micButton Controller
  AnimationController? _animationController4; //micButton Controller
  Animation? _repeatedAnimation;
  Animation? _rotationAnimation;
  Animation? _positionAnimationY;
  Animation? _positionAnimationX;
  Animation? _micButtonAnimation;
  StreamSubscription<RecordingDisposition>? recorderProgressSubscription;
  final Duration duration = const Duration(milliseconds: 500);
  final recorder = FlutterSoundRecorder();
  List<double> decibelValues = [];

  Future<bool> getMic() async {
    PermissionStatus status = await Permission.microphone.status;
    if (status.isGranted) {
      _micAccess = true;
    } else {
      // Permission is not granted, request it
      PermissionStatus requestStatus = await Permission.microphone.request();
      if (requestStatus.isGranted) {
        _micAccess = true;
      } else {
        _micAccess = false;
      }
    }
    return _micAccess;
  }

  Future<bool> getStorage() async {
    PermissionStatus status = await Permission.storage.status;
    if (status.isGranted) {
      return true;
    } else {
      PermissionStatus requestStatus = await Permission.storage.request();
      print(requestStatus);
      if (requestStatus.isGranted) {
        return true;
      } else {
        return false;
      }
    }
  }

  void startRecording() async {
    if (await getMic() && await getStorage()) {
      decibelValues.length = 0;
      await recorder.openRecorder();
      await recorder.setSubscriptionDuration(const Duration(milliseconds: 100));

      recorderProgressSubscription = recorder.onProgress!.listen((event) {
        setState(() {
          decibels = event.decibels!;
          timeElapsed = event.duration.inSeconds;
        });
      });

      decibelTimer =
          Timer.periodic(const Duration(milliseconds: 100), decibelListener);

      String fileName =
          'AUD_${DateTime.now().toString().replaceAll('-', '_').replaceAll(':', '_')}.aac';
      await recorder.startRecorder(toFile: fileName);
    }
  }

  void pauseRecording() async {
    recorderProgressSubscription?.pause();
    decibelTimer?.cancel();
    await recorder.pauseRecorder();
    setState(() {});
  }

  void resumeRecording() async {
    await recorder.resumeRecorder();
    decibelTimer =
        Timer.periodic(const Duration(milliseconds: 100), decibelListener);
    setState(() {});
  }

  void decibelListener(Timer timer) {
    setState(() {
      decibelValues.add(decibels);
    });
  }

  void toogleRecording() async {
    if (recorder.isRecording) {
      pauseRecording();
    } else if (recorder.isPaused) {
      resumeRecording();
    } else {
      print('Hmmmmm');
    }
  }

  void cancelRecording() async {
    recorderProgressSubscription?.cancel();
    await recorder.closeRecorder();
    decibelValues.length = 0;
    decibelTimer?.cancel();
  }

  void stopRecording() async {
    _animationController!.removeListener(update);
    _animationController1!.removeListener(update);
    _animationController2!.removeListener(update);
    _animationController3!.removeListener(update);
    _animationController4!.removeListener(update);
    recorderProgressSubscription?.cancel();
    List<double> deciblePasse = [];
    final newUrl = await recorder.stopRecorder();

    final double interval = decibelValues.length / 45;

    if (interval >= 1) {
      for (int i = 0; i < 45; i++) {
        deciblePasse.add(decibelValues[(interval * i).ceil()]);
      }
    } else {
      deciblePasse.length = 0;
    }

    widget.addFileMessage(MessageType.audio, newUrl!, deciblePasse);

    url = newUrl;
    print('Saved audio files successfully at $newUrl');
    await recorder.closeRecorder();

    decibelValues.length = 0;
    decibelTimer!.cancel();
  }

  String getFormattedTime(int secondsElapsed) {
    int minutes = secondsElapsed ~/ 60;
    int seconds = secondsElapsed % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    initAnimations();

    audioStart.setReleaseMode(ReleaseMode.stop);
    audioCancel.setReleaseMode(ReleaseMode.stop);
    audioStop.setReleaseMode(ReleaseMode.stop);

    audioStart.setSourceAsset('audio/start.mp3');
    audioCancel.setSourceAsset('audio/cancel.mp3');
    audioStop.setSourceAsset('audio/stop.mp3');

    super.initState();
  }

  void initAnimations() {
    _animationController = AnimationController(
        vsync: this, duration: duration); //Infinite repeated animation
    _animationController1 = AnimationController(
        vsync: this, duration: duration); //Once repeated animation
    _animationController2 = AnimationController(
        vsync: this, duration: duration); //Single animation 0.5 secs
    _animationController3 = AnimationController(
        vsync: this,
        duration: duration,
        reverseDuration: Duration(milliseconds: 100)); //Single animation
    _animationController4 = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1)); //Single animation 1.0 secs

    const double rotationBegin = 0; //(0) rads or 0 deg
    const double rotationEnd = 2 * 3.14159; // 2pi rads or 360 deg

    final Tween<double> rotationTween =
        Tween(begin: rotationBegin, end: rotationEnd);
    final Tween<double> xPositionTween = Tween(begin: 50, end: 0);

    _repeatedAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    );

    _positionAnimationY = CurvedAnimation(
      parent: _animationController1!,
      curve: Curves.easeOutCubic,
    );

    _positionAnimationX = xPositionTween.animate(CurvedAnimation(
      parent: _animationController4!,
      curve: Curves.linear,
    ));

    _rotationAnimation = rotationTween.animate(
      CurvedAnimation(
        parent: _animationController2!,
        curve: Curves.linear,
      ),
    );

    _micButtonAnimation = CurvedAnimation(
        parent: _animationController3!,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeOutBack);

    _animationController!.addListener(update);
    _animationController1!.addListener(update);
    _animationController2!.addListener(update);
    _animationController3!.addListener(update);
    _animationController4!.addListener(update);
    // _animationController!.forward();
    // _animationController1!.forward();
    // _animationController2!.forward();

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController!.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController!.forward();
      }
    });

    _animationController1!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController1!.reverse();
      }
    });

    _animationController2!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationController2!.reset();
        });
      }
    });

    _animationController4!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationController4!.reset();
          _isCanceling = false;
        });
      }
    });
  }

  void update() {
    setState(() {});
  }

  void disposeAnimations() {
    _animationController!.removeListener(update);
    _animationController1!.removeListener(update);
    _animationController2!.removeListener(update);
    _animationController3!.removeListener(update);
    _animationController4!.removeListener(update);
    _animationController!.dispose();
    _animationController1!.dispose();
    _animationController2!.dispose();
    _animationController3!.dispose();
    _animationController4!.dispose();
  }

  @override
  void dispose() {
    disposeAnimations();
    if (_isRecording) recorder.closeRecorder();
    if (decibelTimer != null) decibelTimer?.cancel();
    recorderProgressSubscription?.cancel();
    audioStart.dispose();
    audioCancel.dispose();
    audioStop.dispose();
    decibelValues.length = 0;
    super.dispose();
  }

  void micLongPressUpdateHandler(newDx, newDy) {
    setState(() {
      if (!_isLockedRecording) {
        //Horizontal movement handleing (X-axis)
        if ((newDx.abs() > newDy.abs() &&
                newDx.abs() > 10 &&
                newDx < 0 &&
                !vM) ||
            (hM)) {
          hM = newDx < 0;

          dx = newDx < -70 ? -70 : newDx;

          if (dx.abs() == 70) {
            _isCanceling = true;
            cancelingAnimationHandler();
          }
          //vERTICAL movement handleing (Y-axis)
        } else if ((newDx.abs() < newDy.abs() &&
                newDy.abs() > 10 &&
                newDy < 0 &&
                !hM) ||
            (vM)) {
          vM = newDy < 0;

          dy = newDy < -100 ? -100 : newDy;

          if (dy.abs() == 100) {
            lockRecordingStartHandler();
          }
        }
      }
    });
  }

  Future<void> micLongPressStartHandler() async {
    if (_isRecording) {
      return;
    }
    await audioStart.resume();
    await HapticFeedback.vibrate();

    startRecording();
    _animationController!.forward();
    _animationController3!.forward();
    _isRecording = true;
    setState(() {});
  }

  Future<void> micLongPressEndHandler() async {
    await HapticFeedback.vibrate();

    //if we are recording in longPress
    if (!_isLockedRecording) {
      if (timeElapsed > 0 && !_isCanceling) {
        await audioStop.resume();
        setState(() {
          stopRecording();
        });
      } else {
        audioCancel.resume();
        setState(() {
          cancelRecording();
        });
      }
    }

    setState(() {
      _animationController!.reset();
      _animationController3!.reverse();
      hM = false;
      vM = false;
      _isRecording = false;
      dx = 0;
      dy = 0;
    });
  }

  void cancelingAnimationHandler() {
    _animationController!.removeListener(update);
    _animationController1!.removeListener(update);
    _animationController2!.removeListener(update);
    _animationController3!.removeListener(update);
    _animationController4!.removeListener(update);
    audioCancel.resume();
    _animationController!.reset();
    _animationController3!.reverse();
    _animationController4!.forward(); //X position of mic of deletion
    _animationController2!.forward(); //rotation of mic of deletion\
    _animationController1!.forward(); //Y position of mic of deletion
    setState(() {
      decibelValues.length = 0;
      decibelTimer!.cancel();
      cancelRecording();
      vM = false;
      hM = false;
      _isRecording = false;
      dx = 0;
      dy = 0;
    });
  }

  void lockRecordingStartHandler() {
    setState(() {
      _animationController3!.reverse();
      vM = true;
      hM = false;
      dy = -100;
      dx = 0;
      Timer(const Duration(seconds: 1), () {
        vM = false;
        dy = 0;
        dx = 0;
      });
      _isLockedRecording = true;
    });
  }

  void toggleRecorder() async {
    setState(() {
      toogleRecording();
      !_isPaused
          ? _animationController!.stop()
          : _animationController!.forward();
      _isPaused = !_isPaused;
    });
  }

  Future<void> lockRecordingEndHandler({required bool delete}) async {
    await HapticFeedback.vibrate();

    setState(() {
      if (!delete && timeElapsed > 0) {
        stopRecording();
      } else {
        cancelRecording();
      }

      _animationController!.reset();
      _isLockedRecording = false;
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    draft = widget.draft;
    final double micPosY = (-_positionAnimationY!.value * 100);
    final double micPosX = (_positionAnimationX!.value);
    final double micScale = _positionAnimationY!.value;
    final double micButtonScale = _micButtonAnimation!.value + 1;
    final double micRotation = _rotationAnimation!.value;
    final double width = MediaQuery.of(context).size.width;
    final double redOpacity = _repeatedAnimation!.value;

    double opacity = 1 + dx / 35;
    if (opacity > 1) {
      opacity = 1;
    } else if (opacity < 0) {
      opacity = 0;
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: width,
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.only(
                  bottom: 2,
                  left: 2,
                ),
                width: !_isRecording ? width - 60 : (width - 60) + dx,
                child: Card(
                  margin: const EdgeInsets.all(2.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ShowRepliedMessage(),
                      !_isRecording
                          ? TextFormField(
                              controller: widget.textEditingController,
                              focusNode: widget.focusNode,
                              textAlignVertical: TextAlignVertical.center,
                              keyboardType: TextInputType.multiline,
                              maxLines: 5,
                              minLines: 1,
                              onTap: () {
                                if (widget.emojiShowing) {
                                  widget.toggleEmojiPicker();
                                }
                              },
                              onChanged: (value) {
                                setState(() {
                                  draft = value;
                                });
                                widget.changeDraft(value);
                              },
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Type a message',
                                hintStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: !_isCanceling
                                    ? IconButton(
                                        icon: Icon(
                                          widget.emojiShowing
                                              ? Icons.keyboard
                                              : Icons.emoji_emotions_outlined,
                                        ),
                                        onPressed: () {
                                          widget.toggleEmojiPicker();
                                        },
                                      )
                                    : Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Transform.translate(
                                            offset: Offset(micPosX, micPosY),
                                            child: Transform.scale(
                                              scale: micScale,
                                              child: Transform.rotate(
                                                angle: micRotation,
                                                child: const Icon(
                                                  Icons.mic,
                                                  color: Colors.red,
                                                  size: 30.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SvgPicture.asset(
                                            'assets/svg/open_trash.svg',
                                            width: 20.0,
                                            colorFilter: const ColorFilter.mode(
                                              Colors.grey,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ],
                                      ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.attach_file),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          backgroundColor: Colors.transparent,
                                          context: context,
                                          builder: (builder) =>
                                              ModalContainerSendFiles(
                                            updatePage: widget.updatePage,
                                          ),
                                        ).then((value) {
                                          widget.updatePage();
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.camera_alt_rounded),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          CameraScreen.id,
                                        ).then((value) {
                                          widget.updatePage();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                contentPadding: const EdgeInsets.all(5),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(9.0),
                              child: Row(
                                children: [
                                  Opacity(
                                    opacity: redOpacity,
                                    child: const Icon(
                                      Icons.mic,
                                      color: Colors.red,
                                      size: 30.0,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 20.0,
                                  ),
                                  Text(
                                    getFormattedTime(timeElapsed),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: BlendedText(
                                        text: '< Slide to cancle  ..',
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 2,
                    right: 2,
                    left: 2,
                  ),
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: SizedBox(
                      height: _isRecording ? 150 : 50.0,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          _isRecording
                              ? Opacity(
                                  opacity: opacity < 0 ? 0 : opacity,
                                  child: Transform.translate(
                                    offset: Offset(0, !hM ? 0 : dx.abs() * 3),
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Container(
                                        height: 150.0 + dy,
                                        width: 50.0,
                                        decoration: BoxDecoration(
                                            boxShadow: List.filled(
                                                1,
                                                const BoxShadow(
                                                    blurRadius: 1.0,
                                                    spreadRadius: 0.0,
                                                    blurStyle:
                                                        BlurStyle.inner)),
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(25.0)),
                                        child: Transform.translate(
                                          offset: const Offset(15, 15),
                                          child: Stack(
                                            children: [
                                              Transform.translate(
                                                offset: const Offset(-6, -10),
                                                child: SizedBox(
                                                  width: 35.0,
                                                  child: ClipRect(
                                                    child: Align(
                                                      alignment:
                                                          Alignment.topCenter,
                                                      heightFactor: 0.5,
                                                      widthFactor: 0.5,
                                                      child: SvgPicture.asset(
                                                        'assets/svg/hook.svg',
                                                        width: 45.0,
                                                        colorFilter:
                                                            const ColorFilter
                                                                    .mode(
                                                                Colors.grey,
                                                                BlendMode
                                                                    .srcIn),
                                                        // semanticsLabel: 'A red up arrow'
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Transform.translate(
                                                offset: Offset(
                                                    0,
                                                    !vM
                                                        ? (_repeatedAnimation!
                                                                    .value *
                                                                8) +
                                                            4
                                                        : (8 *
                                                                (1 +
                                                                    (dy /
                                                                        100)) +
                                                            4)),
                                                child: Container(
                                                  height: 16.0,
                                                  width: 20.0,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3.0),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                          Transform.translate(
                            offset: Offset(dx, 0),
                            child: Transform.scale(
                              scale:
                                  !vM ? micButtonScale : 2 * (1 + (dy / 100)),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.blue,
                                child: draft != ''
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          widget.addMessage();
                                          draft = '';
                                          setState(() {});
                                        },
                                      )
                                    : GestureDetector(
                                        onLongPressStart:
                                            (LongPressStartDetails details) {
                                          micLongPressStartHandler();
                                        },
                                        onLongPressMoveUpdate:
                                            (LongPressMoveUpdateDetails
                                                details) {
                                          final newDx =
                                              details.offsetFromOrigin.dx;
                                          final newDy =
                                              details.offsetFromOrigin.dy;
                                          micLongPressUpdateHandler(
                                              newDx, newDy);
                                        },
                                        onLongPressEnd: (details) {
                                          micLongPressEndHandler();
                                        },
                                        onPanStart: (details) {
                                          micLongPressStartHandler();
                                        },
                                        onPanUpdate:
                                            (DragUpdateDetails details) {
                                          final newDx =
                                              details.localPosition.dx - 25;
                                          final newDy =
                                              details.localPosition.dy - 25;
                                          micLongPressUpdateHandler(
                                              newDx, newDy);
                                        },
                                        onPanEnd: (details) {
                                          micLongPressEndHandler();
                                        },
                                        child: IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.mic,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _isLockedRecording
            ? Container(
                width: width,
                decoration: BoxDecoration(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SlideUpAnimationContainer(
                    //   child: ShowRepliedMessage(),
                    // ),
                    ShowRepliedMessage(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            getFormattedTime(timeElapsed),
                            style: const TextStyle(
                                fontSize: 22, color: Colors.grey),
                          ),
                          const SizedBox(width: 15.0),
                          Expanded(
                            child: SizedBox(
                              height: 40.0,
                              child: ListView(
                                physics: NeverScrollableScrollPhysics(),
                                reverse: true,
                                scrollDirection: Axis.horizontal,
                                children: [
                                  Row(
                                    children: decibelValues
                                        .map((double decibelValue) {
                                      // double value ;
                                      // if(decibelValue<15){
                                      //   value = 15;
                                      // }else if(decibelValue>55){
                                      //   value = 55;
                                      // }else{
                                      //   value = decibelValue;
                                      // }
                                      // final double height = ((value.abs()-15)*(3/4))+5;

                                      return Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 0.5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                          ),
                                          width: 3.0,
                                          height: ((decibelValue.abs()) / 6) *
                                              5 // Scale the decibel value to the height range of 0-100 pixels
                                          // height: height,
                                          );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 35.0,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              lockRecordingEndHandler(delete: true);
                            },
                          ),
                          IconButton(
                            icon: Opacity(
                              opacity: !_isPaused ? redOpacity : 1,
                              child: Icon(
                                !_isPaused
                                    ? Icons.pause_circle_outline_rounded
                                    : Icons.play_arrow_rounded,
                                size: 35.0,
                                color: Colors.red,
                              ),
                            ),
                            onPressed: () {
                              toggleRecorder();
                            },
                          ),
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue,
                            child: IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                // widget.addMessage();
                                lockRecordingEndHandler(delete: false);
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}

class ShowRepliedMessage extends StatefulWidget {
  ShowRepliedMessage({
    super.key,
  });

  @override
  State<ShowRepliedMessage> createState() => _ShowRepliedMessageState();
}

class _ShowRepliedMessageState extends State<ShowRepliedMessage> {
  bool _isVisible = false;

  String adjustMessageString(String input) {
    if (input.length > 38) {
      input = input.substring(0, 38) + '...';
    }
    final firstNewlineIndex = input.indexOf('\n');
    if (firstNewlineIndex != -1) {
      final secondNewlineIndex = input.indexOf('\n', firstNewlineIndex + 1);
      if (secondNewlineIndex != -1) {
        final result = input
            .replaceFirst('\n', '(+\$*%+)', secondNewlineIndex)
            .split('(+\$*%+)')
            .first;
        return '$result...';
      }
    }
    return input;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final rMessage = Provider.of<RepliedMessage>(context).message;

    final icon = rMessage != null ? iconFromMessageType(rMessage.type) : null;

    _isVisible = !Provider.of<RepliedMessage>(context).isEmpty;
    // print(Provider.of<RepliedMessage>(context).isEmpty);
    // print('Replied: ${Provider.of<RepliedMessage>(context).isEmpty}');

    String msg =
        _isVisible ? Provider.of<RepliedMessage>(context).message!.message : '';

    msg = adjustMessageString(msg);

    msg.runes.map((int rune) {
      String currentChar = String.fromCharCode(rune);
      print(currentChar);
      if (currentChar == '\n') return currentChar;
    });

    return _isVisible
        ? Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.only(
                bottom: 10.0,
                left: 8.0,
              ),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isVisible
                              ? Provider.of<RepliedMessage>(context)
                                  .message!
                                  .sender
                              : 'Sender',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            Provider.of<RepliedMessage>(context, listen: false)
                                .clear();
                            _isVisible = !_isVisible;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 8.0),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (icon != null) Icon(icon),
                      Text(
                        _isVisible ? msg : 'Here is the message I replied to',
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        : const SizedBox();
  }
}

class BlendedText extends StatefulWidget {
  final String text;

  final bool pause;

  BlendedText({required this.text, this.pause = false});

  @override
  _BlendedTextState createState() => _BlendedTextState();
}

class _BlendedTextState extends State<BlendedText>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  double pi = 3.14159;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller!);
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !widget.pause
        ? Stack(
            children: [
              // Create a gradient that matches the color of the text
              AnimatedBuilder(
                animation: _animation!,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 10, 10, 10).withOpacity(0),
                          Colors.white.withOpacity(1),
                          Colors.white.withOpacity(1),
                          const Color.fromARGB(255, 8, 8, 8).withOpacity(0),
                        ],
                        stops: [
                          0,
                          _animation!.value - 0.05,
                          _animation!.value + 0.05,
                          1,
                        ],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.srcIn,
                    child: child,
                  );
                },
                // Create the text widget that will be blended with the gradient
                // child: Container(
                //   foregroundDecoration: BoxDecoration(
                //     backgroundBlendMode:
                //   ),
                // )
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 18,
                    foreground: Paint()..shader = null,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          )
        : Text(
            widget.text,
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
            ),
          );
  }
}

class SlideUpAnimationContainer extends StatefulWidget {
  final Widget child;

  SlideUpAnimationContainer({required this.child});

  @override
  _SlideUpAnimationContainerState createState() =>
      _SlideUpAnimationContainerState();
}

class _SlideUpAnimationContainerState extends State<SlideUpAnimationContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500), // Adjust the duration as needed
    );

    _animation = Tween<Offset>(
      begin: Offset(0, 1), // Slide in from bottom
      end: Offset.zero, // No offset, fully visible
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }

  // Function to trigger the slide-up animation
  void show() {
    _controller.forward();
  }
}
