import 'dart:io';

import 'package:flutter/material.dart';

//Only enter here if ppFile exists
class ProfilePicture extends StatefulWidget {
  const ProfilePicture({
    super.key,
    required this.path,
    required this.chatName,
    required this.tag,
  });

  final String path;
  final String chatName;
  final String tag;

  @override
  State<ProfilePicture> createState() => _ProfilePictureState();
}

class _ProfilePictureState extends State<ProfilePicture> {
  double opacity = 1.0;
  double dy = 0.0;
  double dx = 0.0;

  @override
  Widget build(BuildContext context) {
    final String name =
        widget.chatName == '' ? 'Profile Picture' : widget.chatName;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Color.fromARGB(255, 14, 15, 17).withOpacity(opacity),
      ),
      backgroundColor: Colors.black.withOpacity(opacity),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          dy += details.delta.dy;
          final double ratio = (dy / MediaQuery.of(context).size.height);
          if ((dy < -25 || dy > 25)) {
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
        child: Transform.translate(
          offset: Offset(0.0, dy - 25),
          child: Container(
            color: Colors.black.withOpacity(0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ImageViewer(
                  path: widget.path,
                  tag: widget.tag,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImageViewer extends StatefulWidget {
  final String path;
  final String tag;

  const ImageViewer({
    super.key,
    required this.path,
    required this.tag,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  final _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  String get path => widget.path;
  String get tag => widget.tag;

  @override
  Widget build(BuildContext context) {
    final ppFile = File(path);

    final ppWidget = ppFile.existsSync()
        ? Image.file(
            ppFile,
            scale: 0.02,
          )
        : Image.asset(
              'assets/images/user1.png',
              scale: 0.02,
            );
        

    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTapDetails = d,
      onDoubleTap: _handleDoubleTap,
      child: Center(
        child: InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: EdgeInsets.all(20.0),
          minScale: 0.1,
          maxScale: 4.0,
          onInteractionEnd: (_) {
            // Ensure the scale value stays within the provided range
            if (_transformationController.value.getMaxScaleOnAxis() > 4.0) {
              _transformationController.value = Matrix4.identity()..scale(4.0);
            }
          },
          child: Hero(
            tag: tag,
            child: ppWidget,
          ),
        ),
      ),
    );
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      // For a 3x zoom
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(3.0);
      // Fox a 2x zoom
      // ..translate(-position.dx, -position.dy)
      // ..scale(2.0);
    }
  }
}
