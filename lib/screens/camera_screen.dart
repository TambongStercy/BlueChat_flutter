import 'dart:async';
// import 'package:blue_chat_v1/screens/image_preview_screen.dart';
// import 'package:blue_chat_v1/screens/video_preview_screen.dart';
import 'package:blue_chat_v1/screens/preview_screen.dart';
import 'package:blue_chat_v1/screens/album_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  static final String id = 'camera_screen';
  final List<CameraDescription> cameras;

  CameraScreen({required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool isTakingPicture = false;
  List<CameraDescription>? cameras;
  CameraController? _controller;
  FlashMode mode = FlashMode.off;
  IconData flashIcon = Icons.flash_off_rounded;
  bool? cameraAccess;
  int direction = 1;
  Timer? timer;
  int secondsElapsed = 0;
  bool _isRecording = false;
  double initialPosition = 0;

  void getCameras() async {
    PermissionStatus status = await Permission.camera.status;
    if (status.isGranted) {
      cameras = await availableCameras();
      cameraAccess = true;
    } else {
      // Permission is not granted, request it
      PermissionStatus requestStatus = await Permission.camera.request();
      if (requestStatus.isGranted) {
        cameras = await availableCameras();
        cameraAccess = true;
      } else {
        cameraAccess = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getCameras();
    initiateControler();
  }

  void initiateControler() {
    direction = direction == 0 ? 1 : 0;
    _controller =
        CameraController(widget.cameras[direction], ResolutionPreset.medium);
    _controller?.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {});
      print('controller initiallized');
    }).catchError((e) {
      print(e);
    });
  }

  Future<void> takeAPicture() async {
    _controller!.takePicture().then((XFile? file) {
      if (mounted && file != null) {
        print('Picture Saved to ${file.path}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (builder) => PreviewScreen(
              mediaPaths: [file.path],
              popsAfter: 2,
            ),
          ),
        );
      }
    }).catchError(
      (e) {
        print(e);
      },
    );
  }

  Future<String> getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${DateTime.now()}.mp4';
    return filePath;
  }

  Future<void> startVideoRecording() async {
    if (!_controller!.value.isRecordingVideo) {
      // final filePath = await getFilePath();
      try {
        await _controller!.startVideoRecording();
        startTimer();
        setState(() => _isRecording = true);
      } catch (e) {
        print(e);
      }
    }
  }
  
  void _checkZoomLevels() async {
    var minZoomLevel = await _controller!.getMinZoomLevel();
    var maxZoomLevel = await _controller!.getMaxZoomLevel();
    print('Minimum zoom level: $minZoomLevel');
    print('Maximum zoom level: $maxZoomLevel');
  }

  Future<void> setZoom(double zoomLevel) async {
    double minZoom = await _controller!.getMinZoomLevel();
    double maxZoom = await _controller!.getMaxZoomLevel();;

    if (zoomLevel > maxZoom || zoomLevel < minZoom) {
      return;
    }

    await _controller!.setZoomLevel(zoomLevel);
  }

  Future<void> stopVideoRecording() async {
    if (_controller!.value.isRecordingVideo) {
      try {
        final file = await _controller!.stopVideoRecording();
        stopTimer();
        setState(() => _isRecording = false);
        print(file.path);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PreviewScreen(
                mediaPaths: [file.path],
                popsAfter: 2,
              ),
            ),
          );
        }
      } catch (e) {
        print(e);
      }
    }
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        secondsElapsed++;
      });
    });
  }

  void stopTimer() {
    timer!.cancel();
    setState(() {
      secondsElapsed = 0;
    });
  }

  String getFormattedTime() {
    int minutes = secondsElapsed ~/ 60;
    int seconds = secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void toggleFlashMode() {
    setState(() {
      if (mode == FlashMode.off) {
        mode = FlashMode.always;
        flashIcon = Icons.flash_on_rounded;
      } else if (mode == FlashMode.always) {
        mode = FlashMode.auto;
        flashIcon = Icons.flash_auto_rounded;
      } else {
        mode = FlashMode.off;
        flashIcon = Icons.flash_off_rounded;
      }
      _controller!.setFlashMode(mode);
    });
  }

  void _handleFocusTap(TapDownDetails details) async {
    final Size screenSize = MediaQuery.of(context).size;
    final double relX = details.localPosition.dx / screenSize.width;
    final double relY = details.localPosition.dy / screenSize.height;

    final Offset rel = Offset(relX, relY);

    try {
      await _controller!.setExposurePoint(rel);
      await _controller!.setFocusPoint(rel);
    } catch (e) {
      print('Error setting focus/exposure point: $e');
    }
  }

  void _handleZoomPinch(ScaleUpdateDetails details) {
    // setState(() {
    // });
    
      setZoom(details.scale.clamp(1.0, 10));
    // _cameraController.setZoomLevel(_zoomLevel);
  }

  @override
  void dispose() {
    _controller?.dispose();

    if (timer != null) timer!.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Color.fromARGB(255, 2, 10, 14),
        body: SafeArea(
          minimum: EdgeInsets.only(top: 50.0),
          child: Stack(
            children: [
              GestureDetector(
                onTapDown: (details) {
                  _handleFocusTap(details);
                },
                onScaleUpdate: (details) {
                  _handleZoomPinch(details);
                },
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * (3.5 / 5),
                  child: CameraPreview(_controller!),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: _isRecording
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          color: Colors.red,
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 2.0, horizontal: 7.0),
                        child: Text(
                          getFormattedTime(),
                          style: const TextStyle(
                              fontSize: 18.0, color: Colors.white),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black38
                                ),
                              // padding: const EdgeInsets.all(5.0),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 25.0,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black38),
                              // padding: const EdgeInsets.all(5.0),
                              child: IconButton(
                                onPressed: () {
                                  //toggle flashMode
                                  toggleFlashMode();
                                },
                                icon: Icon(
                                  flashIcon,
                                  color: Colors.white,
                                  size: 25.0,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                      top: (_isRecording ? 12.5 : 50.0),
                      bottom: (_isRecording ? 12.5 : 50.0)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(0),
                        onPressed: () {
                          Navigator.pushNamed(context, AlbumPageView.id);
                        },
                        icon: const Icon(
                          Icons.filter,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3.0,
                          ),
                        ),
                        padding: EdgeInsets.all(_isRecording ? 20.0 : 5.0),
                        child: GestureDetector(
                            onTap: () {
                              !isTakingPicture?
                              takeAPicture():
                              print('Is already taking a picture');
                            },
                            onLongPress: () {
                              startVideoRecording();
                            },
                            onLongPressUp: () {
                              stopVideoRecording();
                            },
                            onLongPressStart: (details) {
                              setState(() {
                                initialPosition =
                                    details.globalPosition.distance;
                              });
                            },
                            onLongPressMoveUpdate:
                                (LongPressMoveUpdateDetails details) {
                              double currentPosition =
                                  details.globalPosition.distance;
                              double zoomLevel =
                                  currentPosition <= initialPosition
                                      ? initialPosition - currentPosition
                                      : 1.0;
                              zoomLevel = (zoomLevel / 500) * 10;
                  
                              setZoom(zoomLevel);
                            },
                            child: Icon(
                              Icons.circle,
                              color: _isRecording ? Colors.red : Colors.white,
                              size: 50.0,
                            )),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(0),
                        onPressed: () {
                          initiateControler();
                        },
                        icon: const Icon(
                          Icons.flip_camera_android,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
