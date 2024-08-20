import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'camera_provider.dart';

/// CameraApp is the Main Application.
class CameraPage extends StatefulWidget {
  /// Default Constructor
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double screenWidth = MediaQuery.of(context).size.width;
    final cameraProvider = Provider.of<CameraProvider>(context);

    double camViewWeight =
        screenWidth * cameraProvider.cameraController!.value.aspectRatio;

    if (cameraProvider.cameraController == null ||
        !cameraProvider.cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        body: Column(
          children: [
            SizedBox(
              width: screenWidth,
              height: camViewWeight,
              child: Stack(children: [
                CameraPreview(cameraProvider.cameraController!),
                ClipPath(
                  clipper: CenterCropClipper(),
                  child: Container(
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                Container(
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.only(top: statusBarHeight+20),
                  child: const Text(
                    "Place the test sample in the frame",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ]),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // go back
                      Navigator.pop(context);
                    },
                    child:
                        Hero(tag: "cancel", child: Icon(Icons.cancel_outlined)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await takePicture(cameraProvider).then((XFile? file) {
                        print(
                            "#############################################################");
                        print(file?.path);
                        cameraProvider.imageFile = file;
                      });
                      Navigator.pop(context);
                    },
                    child:
                        Hero(tag: "camera_icon", child: Icon(Icons.camera_alt)),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  void onTakePictureButtonPressed(CameraProvider camProvider) async {
    takePicture(camProvider).then((XFile? file) {
      print("#############################################################");
      print(file?.path);
      camProvider.imageFile = file;
    });
  }

  Future<XFile?> takePicture(CameraProvider camProvider) async {
    if (camProvider.cameraController == null ||
        !camProvider.cameraController!.value.isInitialized) {
      return null;
    }

    if (camProvider.cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      final XFile file = await camProvider.cameraController!.takePicture();
      return file;
    } on CameraException catch (e) {
      return null;
    }
  }
}

class CenterCropClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double windowWidth = size.width * 0.5;
    double windowHeight = size.height * 0.6;
    double left = (size.width - windowWidth) / 2;
    double top = (size.height - windowHeight) / 2;

    Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTWH(left, top, windowWidth, windowHeight))
      ..fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
