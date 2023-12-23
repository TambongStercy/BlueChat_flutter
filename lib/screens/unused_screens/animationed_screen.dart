import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
// import 'dart:async';

class AnimatedScreen extends StatefulWidget {
  const AnimatedScreen({super.key});

  static final String id = 'animated_screen';
  @override
  State<AnimatedScreen> createState() => _AnimatedScreenState();
}

class _AnimatedScreenState extends State<AnimatedScreen>
    with TickerProviderStateMixin {
  double x = 0;
  double dx = 0;
  double dy = 0;
  bool vM = false;
  bool hM = false;
  AnimationController? _animationController;
  AnimationController? _animationController1;
  AnimationController? _animationController2;
  AnimationController? _animationController3; //micButton Controller
  Animation? _repeatedAnimation;
  Animation? _rotationAnimation;
  Animation? _positionAnimation;
  Animation? _micButtonAnimation;
  final Duration duration = const Duration(milliseconds: 500);

  final audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration audioDuration = Duration.zero;
  Duration audioPosition = Duration.zero;

  void initAudioPlayer() async {
    audioPlayer.setReleaseMode(ReleaseMode.stop);
    audioPlayer.setSourceAsset('audio/note4.wav');

    // Duration ?duration = await audioPlayer.getDuration();
    // int numIntervals = 40;
    // double intervalDuration = duration!.inMilliseconds / numIntervals;

    // for (int i = 0; i < numIntervals; i++) {
    //   double startTime = i * intervalDuration / 1000.0;
    //   double endTime = (i + 1) * intervalDuration / 1000.0;

    //   double decibels = await audioPlayer.getAverageVolume(
    //     url: audioUrl,
    //     startTime: startTime,
    //     endTime: endTime,
    //   );
    //   decibelValues.add(decibels);
    // }

    audioPlayer.onPlayerStateChanged.listen((state) {
      setState((){
        isPlaying = state == PlayerState.playing;
      });
    });
    audioPlayer.onDurationChanged.listen((newDuration) {
      setState((){
        audioDuration = newDuration;
      });
    });
    audioPlayer.onPositionChanged.listen((newPosition) {
      setState((){
        audioPosition = newPosition;
      });
    });
  }

  @override
  void initState() {
    initAnimations();
    initAudioPlayer();
    super.initState();
  }
 
  void initAnimations() {
    _animationController = AnimationController(
        vsync: this, duration: duration); //Infinite repeated animation
    _animationController1 = AnimationController(
        vsync: this, duration: duration); //Once repeated animation
    _animationController2 =
        AnimationController(vsync: this, duration: duration); //Single animation
    _animationController3 =
        AnimationController(vsync: this, duration: duration); //Single animation

    _repeatedAnimation =
        CurvedAnimation(parent: _animationController!, curve: Curves.easeOut);

    const double rotationBegin = 1.570795; //(pi/2) rads or 90 deg
    const double rotationEnd = 2 * 3.14159; // 2pi rads or 360 deg

    final Tween<double> rotationTween =
        Tween(begin: rotationBegin, end: rotationEnd);

    _positionAnimation = CurvedAnimation(
      parent: _animationController1!,
      curve: Curves.easeOutCubic,
    );

    _micButtonAnimation = CurvedAnimation(
        parent: _animationController3!,
        curve: Curves.elasticOut,
        reverseCurve: Curves.bounceIn);

    _rotationAnimation = rotationTween.animate(
      CurvedAnimation(
        parent: _animationController2!,
        curve: Curves.linear,
      ),
    );

    _animationController!.addListener(() {
      setState(() {});
    });
    _animationController1!.addListener(() {
      setState(() {});
    });
    _animationController2!.addListener(() {
      setState(() {});
    });
    _animationController3!.addListener(() {
      setState(() {});
    });

    _animationController!.forward();
    _animationController1!.forward();
    _animationController2!.forward();

    _animationController1!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController1!.reverse();
      }
    });

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController!.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController!.forward();
      }
    });
  }

  void disposeAnimations() {
    _animationController!.dispose();
    _animationController1!.dispose();
    _animationController2!.dispose();
    _animationController3!.dispose();
  }

  @override
  void dispose() {
    disposeAnimations();
    audioPlayer.dispose();
    super.dispose();
  }

  void micLongPressUpdateHandler(newDx, newDy) {
    setState(() {
      if ((newDx.abs() > newDy.abs() && newDx.abs() > 10 && newDx < 0 && !hM) ||
          (vM)) {
        vM = newDx < 0;
        dx = newDx;
      } else if ((newDx.abs() < newDy.abs() &&
              newDy.abs() > 10 &&
              newDy < 0 &&
              !vM) ||
          (hM)) {
        hM = newDy < 0;
        dy = newDy;
      }
    });
  }

  void micLongPressStartHandler() {
    setState(() {
      _animationController3!.forward();
    });
  }

  void micLongPressEndHandler() {
    setState(() {
      _animationController3!.reverse();
      vM = false;
      hM = false;
      dx = 0;
      dy = 0;
    });
  }

  String getFormattedTime(int secondsElapsed) {
    int minutes = secondsElapsed ~/ 60;
    int seconds = secondsElapsed % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final double micPos = (-_positionAnimation!.value * 100);
    final double micScale = _positionAnimation!.value;
    final double micButtonScale = _micButtonAnimation!.value + 1;
    final double micRotation = _rotationAnimation!.value;
    List<double> decibelValues = [10, 12, 15, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 60, 62, 64, 66, 68, 70, 72, 74, 76, 78, 80, 82, 84, 86, 88, 90, 92, 94, 96, 98, 100];

    return Scaffold(
      appBar: AppBar(
        title: Text('Animation'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: decibelValues.map((double decibelValue) {
              return Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(5.0)
                ),
                // height: 30.0,
                width: 3.0,
                height: (decibelValue - 5) / 2, // Scale the decibel value to the height range of 5-20 pixels
              );
            }).toList(),
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 25.0,
                child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      if(isPlaying){
                        await audioPlayer.pause();
                      }else{
                        await audioPlayer.resume();
                      }
                    },
                  ),
              ),
              Row(
                children: [
                  Opacity(
                    opacity: 1,
                    child: Slider(
                      min: 0,
                      max: audioDuration.inMilliseconds.toDouble()/1000,
                      value: audioPosition.inMilliseconds.toDouble()/1000,
                      onChanged: (value) async {

                        final position = Duration(seconds: value.toInt());
                        await audioPlayer.seek(position);
                        
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(getFormattedTime(audioPosition.inSeconds)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(-8.0, -10),
                      child: Container(
                        width: 45.0,
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: 0.5,
                            widthFactor: 0.5,
                            child: SvgPicture.asset(
                              'assets/svg/hook.svg',
                              width: 45.0,
                              colorFilter: const ColorFilter.mode(
                                  Colors.lightBlueAccent, BlendMode.srcIn),
                              // semanticsLabel: 'A red up arrow'
                            ),
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, _repeatedAnimation!.value * 8),
                      child: Container(
                        height: 20.0,
                        width: 25.0,
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent,
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: Offset(dx, dy),
                child: GestureDetector(
                  onLongPressStart: (LongPressStartDetails details) {
                    micLongPressStartHandler();
                  },
                  onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
                    final newDx = details.offsetFromOrigin.dx;
                    final newDy = details.offsetFromOrigin.dy;
                    micLongPressUpdateHandler(newDx, newDy);
                  },
                  onLongPressEnd: (details) {
                    micLongPressEndHandler();
                  },
                  child: Transform.scale(
                    scale: micButtonScale,
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xFF128C7E),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.mic,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 40.0,
              ),
              Transform.translate(
                offset: Offset(0, micPos),
                child: Transform.scale(
                  scale: micScale,
                  child: Transform.rotate(
                    angle: micRotation,
                    child: Icon(
                      Icons.mic,
                      color: Colors.red,
                      size: 30.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 40.0,
              ),
              Opacity(
                opacity: _repeatedAnimation!.value,
                child: Icon(
                  Icons.mic,
                  color: Colors.red,
                  size: 30.0,
                ),
              ),
              const SizedBox(
                width: 40.0,
              ),
              DraggableContainer(),
            ],
          )
        ],
      ),
    );
  }
}

class DraggableContainer extends StatefulWidget {
  @override
  _DraggableContainerState createState() => _DraggableContainerState();
}

class _DraggableContainerState extends State<DraggableContainer> {
  bool _dragging = false;
  double _left = 0.0;
  double _top = 0.0;
  bool hM = false;
  bool vM = false;
  // Offset ?_dragOffset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(_left, _top),
      child: GestureDetector(
        onLongPressStart: (LongPressStartDetails details) {
          setState(() {
            _dragging = true;
          });
        },
        onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
          final newDx = details.offsetFromOrigin.dx;
          final newDy = details.offsetFromOrigin.dy;
          setState(() {
            if ((newDx.abs() > newDy.abs() &&
                    newDx.abs() > 10 &&
                    newDx < 0 &&
                    !hM) ||
                (vM)) {
              vM = newDx < 0;
              _left = newDx;
            } else if ((newDx.abs() < newDy.abs() &&
                    newDy.abs() > 10 &&
                    newDy < 0 &&
                    !vM) ||
                (hM)) {
              hM = newDy < 0;
              _top = newDy;
            }
          });
        },
        onLongPressEnd: (details) {
          setState(() {
            vM = false;
            hM = false;
            _dragging = false;
            _left = 0;
            _top = 0;
          });
        },
        child: Container(
          width: 100,
          height: 100,
          color: Colors.blue,
          child: Text('$hM $vM $_dragging'),
          // margin: EdgeInsets.only(left: _left, top: _top),
        ),
      ),
    );
  }
}
