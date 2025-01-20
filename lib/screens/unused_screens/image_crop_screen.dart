import 'dart:io';
import 'dart:typed_data';

import 'package:blue_chat_v1/utils.dart';
import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';

class MyCropper extends StatefulWidget {
  final File image;

  const MyCropper({Key? key, required this.image}) : super(key: key);

  @override
  State<MyCropper> createState() => _MyCropperState();
}

class _MyCropperState extends State<MyCropper> {
  final controller = CropController(
    aspectRatio: null,
    defaultCrop: const Rect.fromLTWH(0, 0, 1, 1),
  );

  final List<double?> _aspectRatios = [
    null,
    1.0,
  ];
  int _currentAspectRatioIndex = 0;

  void _toggleAspectRatio() {
    setState(() {
      _currentAspectRatioIndex =
          (_currentAspectRatioIndex + 1) % _aspectRatios.length;
      controller.aspectRatio = _aspectRatios[_currentAspectRatioIndex];
      controller.crop = const Rect.fromLTWH(0, 0, 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 26, 26, 27),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 27,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Container(
          // height: MediaQuery.of(context).,
          // height: MediaQuery.of(context).size.height*0.75,

          color: Colors.black,
          child: Center(
            child: CropImage(
              controller: controller,
              image: Image.file((widget.image)),
              paddingSize: 25.0,
              minimumImageSize: 20.0,
              alwaysMove: true,
              alwaysShowThirdLines: true,
            ),
          ),
        ),
        bottomNavigationBar: _buildButtons(),
      );

  Widget _buildButtons() => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: darkBG,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.aspect_ratio,
                size: 27,
              ),
              color: Colors.white,
              onPressed: _toggleAspectRatio,
            ),
            IconButton(
              icon: const Icon(
                Icons.rotate_90_degrees_cw_outlined,
                size: 27,
                color: Colors.white,
              ),
              onPressed: _rotateRight,
            ),
            IconButton(
              icon: const Icon(
                Icons.check,
                size: 27,
                color: Colors.white,
              ),
              onPressed: _finished,
            ),
          ],
        ),
      );

  Future<void> _rotateRight() async => controller.rotateRight();

  String _generateUniqueFileName() {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'Cropped_$timestamp.png';
  }

  Future<void> _finished() async {
    final croppedImage = await controller.croppedBitmap();

    final byteData =
        await croppedImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/${_generateUniqueFileName()}';

      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(pngBytes);

      Navigator.pop(context, tempFile);
    } else {
      print('An error occured some where');
    }

    // if (mounted) {
    //   await showDialog<bool>(
    //     context: context,
    //     builder: (context) {
    //       return SimpleDialog(
    //         contentPadding: const EdgeInsets.all(6.0),
    //         titlePadding: const EdgeInsets.all(8.0),
    //         title: const Text('Cropped image'),
    //         children: [
    //           Text('relative: ${controller.crop}'),
    //           Text('pixels: ${controller.cropSize}'),
    //           const SizedBox(height: 5),
    //           image,
    //           TextButton(
    //             onPressed: () => Navigator.pop(context, true),
    //             child: const Text('OK'),
    //           ),
    //         ],
    //       );
    //     },
    //   );
    // }
  }
}
