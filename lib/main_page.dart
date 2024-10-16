import 'dart:io';

import 'package:flutter/material.dart';
import 'background.dart';
import 'fab_circle_menu.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'dart:typed_data';
import 'camera_page.dart';
import 'package:provider/provider.dart';
import 'camera_provider.dart';

import 'image_processing.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  DocumentScanner? _documentScanner;
  DocumentScanningResult? _result;

  String _resultText = '';
  String _logText = '';
  String _imagePath = '';
  List<double> avgValues = [];
  Uint8List? lateral_flow;
  bool _openSetting = false;

  ImageProcessing imageProcessing = ImageProcessing();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
  }

  void init() async {
    final data =
        await DefaultAssetBundle.of(context).load('assets/test_imgs/ag10.png');
    final bytes = data.buffer.asUint8List();
    await imageProcessing.loadMat(cv.imdecode(bytes, cv.IMREAD_COLOR));
    // await imageProcessing.alignSample();
    if (await imageProcessing.process()) {
      var text =
          'Bar Value: [${imageProcessing.barValue![0].toStringAsFixed(2)} ';
      text += '${imageProcessing.barValue![1].toStringAsFixed(2)} ';
      text += '${imageProcessing.barValue![2].toStringAsFixed(2)} ';
      text += '${imageProcessing.barValue![3].toStringAsFixed(2)} ]';
      setState(() {
        log(text);
        _resultText = imageProcessing.result!.toStringAsFixed(2) + "%";
      });
    } else {
      log('Failed to process image.');
    }
  }

  void log(String message) {
    setState(() {
      _logText = '$message\n$_logText';
    });
  }

  @override
  void dispose() {
    _documentScanner?.close();
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    final cameraProvider = Provider.of<CameraProvider>(context);

    // if (cameraProvider.imageFile != null) {
    //   imageProcessing.loadXFile(cameraProvider.imageFile!);
    // }
    return Scaffold(
        backgroundColor: Colors.black,
        body: Background(
          child: Padding(
            padding: EdgeInsets.only(top: statusBarHeight),
            child: Stack(
              children: [
                Column(
                  children: [
                    Card(
                      clipBehavior: Clip.hardEdge,
                      color: Color.fromARGB(120, 255, 255, 255),
                      child: Column(
                        children: [
                          ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(
                                    0.8), // Adjust the opacity value as needed
                                BlendMode.dstATop,
                              ),
                              child: imageProcessing.image == null
                                  ? Image.asset('assets/test_imgs/1.jpg')
                                  : Image.memory(imageProcessing
                                      .convertToBytes(imageProcessing.image))),
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                        child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: imageProcessing.warped_img == null
                                          ? const Text("N/A")
                                          : Image.memory(
                                              imageProcessing.convertToBytes(
                                                  imageProcessing.warped_img)),
                                    ))),
                              ),
                              Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                        child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: imageProcessing.inspectionArea ==
                                              null
                                          ? const Text("N/A")
                                          : Image.memory(imageProcessing
                                              .convertToBytes(imageProcessing
                                                  .inspectionArea)),
                                    ))),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Transparent console card
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: Card(
                          color: Color.fromARGB(195, 255, 255, 255),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SingleChildScrollView(
                              child: Text(
                                _logText,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: Card(
                          color: Color.fromARGB(195, 255, 255, 255),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                "Results: " + _resultText,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  transform: Matrix4.translationValues(
                    0.0, // Y-axis translation
                    _openSetting ? 200.0 : screenHeight, // X-axis translation
                    0.0, // Z-axis translation
                  ),
                  child: Card(
                    color: Color.fromARGB(255, 255, 255, 255),
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      width: double.infinity,
                      height: screenHeight,
                      child: Column(
                        children: [Text("Settings")],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        floatingActionButton: FabCircularMenu(
            ringWidthLimitFactor: 0.3,
            ringDiameterLimitFactor: 0.8,
            fabColor: Color.fromARGB(200, 172, 182, 184), // End color
            ringColor: Color.fromARGB(200, 172, 182, 184),
            fabOpenIcon:
                Hero(tag: "camera_icon", child: Icon(Icons.camera_alt)),
            onPressedWhenClose: () async {
              log('Start scanning...');
              // startScan(DocumentFormat.jpeg);

              await cameraProvider.initializeCamera();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CameraPage(),
                ),
              );

              if (cameraProvider.imageFile == null) {
                return;
              }
              await imageProcessing.loadXFile(cameraProvider.imageFile!);
              // await imageProcessing.alignSample();
              if (await imageProcessing.process()) {
                var text =
                    'Bar Value: [${imageProcessing.barValue![0].toStringAsFixed(2)} ';
                text += '${imageProcessing.barValue![1].toStringAsFixed(2)} ';
                text += '${imageProcessing.barValue![2].toStringAsFixed(2)} ';
                text += '${imageProcessing.barValue![3].toStringAsFixed(2)} ]';
                log(text);
                setState(() {
                  _resultText =
                      imageProcessing.result!.toStringAsFixed(2) + "%";
                });
              } else {
                log('Failed to process image.');
                setState(() {
                  _resultText = "N/A";
                });
              }
            },
            children: <Widget>[
              IconButton(
                  icon: const Icon(Icons.camera),
                  onPressed: () {
                    log('Start scanning...');
                    startScan(DocumentFormat.jpeg);
                  }),
              IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    setState(() {
                      _openSetting = !_openSetting;
                    });
                  }),
              IconButton(
                  icon: Hero(
                      tag: "select_test", child: const Icon(Icons.burst_mode)),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SamplePage(),
                      ),
                    );

                    if (result != null) {
                      final data =
                          await DefaultAssetBundle.of(context).load(result);
                      final bytes = data.buffer.asUint8List();
                      await imageProcessing
                          .loadMat(cv.imdecode(bytes, cv.IMREAD_COLOR));
                      // await imageProcessing.alignSample();
                      if (await imageProcessing.process()) {
                        var text =
                            'Bar Value: [${imageProcessing.barValue![0].toStringAsFixed(2)} ';
                        text +=
                            '${imageProcessing.barValue![1].toStringAsFixed(2)} ';
                        text +=
                            '${imageProcessing.barValue![2].toStringAsFixed(2)} ';
                        text +=
                            '${imageProcessing.barValue![3].toStringAsFixed(2)} ]';
                        log(text);
                        setState(() {
                          _resultText =
                              imageProcessing.result!.toStringAsFixed(2) + "%";
                        });
                      } else {
                        log('Failed to process image.');
                      }
                    }
                  })
            ]));
  }

  void startScan(DocumentFormat format) async {
    try {
      _result = null;
      setState(() {});
      _documentScanner?.close();
      _documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormat: format,
          mode: ScannerMode.full,
          isGalleryImport: true,
          pageLimit: 1,
        ),
      );
      _result = await _documentScanner?.scanDocument();

      log('Extracted lateral flow test image.\n');
      setState(() {
        _imagePath = _result!.images[0];
      });
      cv.Mat image = cv.imread(_imagePath);

      try {
        // analyzeImg(image);
      } catch (e) {
        log('Error: $e.\n');
      }
    } catch (e) {
      log('Error: $e.\n');
    }
  }

  void analyzeImg(cv.Mat image) async {
    // rotate image if height > width
    if (image.rows > image.cols) {
      image = cv.transpose(image);
    }
    lateral_flow = cv.imencode(".png", image).$2;
    // Convert the image to grayscale
    cv.Mat gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);

    // Get the height and width of the grayscale image
    int h = gray.rows;
    int w = gray.cols;
    int midH = h ~/ 2;
    int windowSizeH = h ~/ 10;
    int windowSizeW = w ~/ 10;

    // Crop the center area of the image
    cv.Rect roi = cv.Rect(
        windowSizeW, midH - windowSizeH, w - 2 * windowSizeW, 2 * windowSizeH);
    cv.Mat centerArea = gray.region(roi);

    // Apply Gaussian Blur to the cropped area
    cv.Mat blurred = cv.gaussianBlur(centerArea, (5, 5), 0);

    // Apply Canny edge detection
    cv.Mat edges = cv.canny(blurred, 0, 10);

    // Perform Hough Line Transformation
    cv.Mat lines = cv.HoughLinesP(edges, 1, 3.1415926 / 180, 10,
        minLineLength: 50, maxLineGap: 1);

    // Draw lines on the original cropped image
    cv.Mat outputImage = centerArea.clone();
    cv.Mat blank =
        cv.Mat.ones(outputImage.rows, outputImage.cols, cv.MatType.CV_8UC1);

    print(lines);

    if (lines.rows == 8) {
      for (int i = 0; i < lines.rows; i++) {
        cv.Point pt1 = cv.Point(lines.at<int>(i, 0), lines.at<int>(i, 1));
        cv.Point pt2 = cv.Point(lines.at<int>(i, 2), lines.at<int>(i, 3));
        cv.line(outputImage, pt1, pt2, cv.Scalar(0, 255, 0));
        cv.line(blank, pt1, pt2, cv.Scalar(0, 255, 0));
      }

      // Reshape lines and calculate average values
      List<int> blocksP = [];
      for (int i = 0; i < lines.rows; i++) {
        blocksP.add(lines.at<int>(i, 0));
      }
      blocksP.sort();

      avgValues = [];
      for (int i = 0; i < 4; i++) {
        int start = blocksP[2 * i].toInt();
        int end = blocksP[2 * i + 1].toInt();
        cv.Mat subMat = centerArea.colRange(start, end);

        double avgValue = 255 - subMat.mean().val1;
        avgValues.add(avgValue);
      }

      setState(() {
        _logText += avgValues.toString() + '\n';
      });
    }
  }
}

class SamplePage extends StatelessWidget {
  final List<String> imagePaths = [
    'assets/test_imgs/ag10.png',
    'assets/test_imgs/ag20.png',
    'assets/test_imgs/ag50.png',
    'assets/test_imgs/ag90.png',
    'assets/test_imgs/ag100.png',
    'assets/test_imgs/ag10_1.jpg',
    'assets/test_imgs/ag20_1.jpg',
    'assets/test_imgs/ag50_1.jpg',
    'assets/test_imgs/ag90_1.jpg',
    'assets/test_imgs/ag100_1.jpg',
  ];
  @override
  Widget build(BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: statusBarHeight),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            child: const Hero(
              tag: 'select_test',
              child: Icon(
                Icons.burst_mode,
                size: 30.0,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Number of columns
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, imagePaths[index]);
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(imagePaths[index]),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            child: IconButton(
              icon: const Icon(
                Icons.cancel,
                size: 50.0,
              ),
              onPressed: () {
                Navigator.pop(context, null);
              },
            ),
          ),
        ]),
      ),
    );
  }
}
