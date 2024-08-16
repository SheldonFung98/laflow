import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraProvider with ChangeNotifier {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  XFile? imageFile;

  CameraController? get cameraController => _cameraController;

  get onTakePictureButtonPressed => null;

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras![0], // Select the first camera (usually the back camera)
      ResolutionPreset.high,
    );
    await _cameraController!.initialize();
    notifyListeners();
  }

  void disposeCamera() {
    _cameraController?.dispose();
  }
}