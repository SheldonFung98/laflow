import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:laflow/background.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final Uri _url = Uri.parse('https://github.com/SheldonFung98/laflow/releases/download/v1.0.0/laflow.apk');

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaFlow Download Page',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Background(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Add image assets here
                Column(
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset('assets/icon/icon.jpeg',
                            width: 200, height: 200)),
                    Text('LaFlow',
                        style: TextStyle(fontSize: 30, color: Colors.white)),
                  ],
                ),
                // addd bottun
                ElevatedButton(
                  onPressed: () {
                    launchUrl(_url);
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
                  child: Text('Download'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
