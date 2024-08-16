import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';


class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  DocumentScanner? _documentScanner;
  DocumentScanningResult? _result;

  @override
  void dispose() {
    _documentScanner?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [

        Container(
          child: Center(
            child: Column(
              children: [
                if (_result?.images.isNotEmpty == true) ...[
                  // Padding(
                  //   padding: const EdgeInsets.only(
                  //       top: 16, bottom: 8, right: 8, left: 8),
                  //   child: Align(
                  //       alignment: Alignment.centerLeft,
                  //       child: Text('Images [0]:')),
                  // ),
                  SizedBox(
                      height: 400,
                      child: Image.file(File(_result!.images.first))),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 200),
                  child: ElevatedButton(
                    onPressed: () {
                      startScan(DocumentFormat.jpeg);
                      // Action to perform on button press
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color.fromARGB(200, 65, 105, 225), // Background color
                      foregroundColor: Colors.white, // Text color
                      padding:
                          EdgeInsets.symmetric(horizontal: 100, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Text('Start'),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
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
      setState(() {});
    } catch (e) {
      print('Error: $e');
    }
  }
}
