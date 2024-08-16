import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'background.dart';
import 'fab_circle_menu.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

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

    return Scaffold(
        backgroundColor: Colors.black,
        body: Background(
          child: Padding(
            padding: EdgeInsets.only(top: statusBarHeight),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: Card(
                    clipBehavior: Clip.hardEdge,
                    color: const Color.fromARGB(200, 0, 0, 0),
                    child: Stack(
                      children: [
                        ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(
                                  0.5), // Adjust the opacity value as needed
                              BlendMode.dstATop,
                            ),
                            child: _imagePath.isEmpty ? Image.asset('assets/test_imgs/1.jpg') : Image.file(File(_imagePath))),
                        Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                child: Image.asset('assets/test_imgs/crop.png'))),
                        ),
                      ],
                    ),
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
                        child: Text(
                          _logText,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10.0,
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
          ),
        ),
        floatingActionButton: FabCircularMenu(
            ringWidthLimitFactor: 0.3,
            ringDiameterLimitFactor: 0.8,
            fabColor: Color.fromARGB(200, 172, 182, 184), // End color
            ringColor: Color.fromARGB(200, 172, 182, 184),
            fabOpenIcon: Icon(Icons.camera_alt),
            onPressedWhenClose: () {
              startScan(DocumentFormat.jpeg);
              // setState(() {
              //   _logText += 'Scanning...\n';
              // });
            },
            children: <Widget>[
              IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () {
                    print('Home');
                  }),
              IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    print('Favorite');
                  }),
              IconButton(
                  icon: Hero(tag: "select_test", child: Icon(Icons.burst_mode)),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SamplePage(),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        _logText += 'Selected image: $result\n';
                      });
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
      print('result: $_result');
      setState(() {
        _imagePath = _result!.images[0];
      });
    } catch (e) {
      print('Error: $e');
    }
  }
}

class SamplePage extends StatelessWidget {
  final List<String> imagePaths = List.generate(
    17, // Number of images
    (index) => 'assets/test_imgs/${index + 1}.jpg',
  );
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
