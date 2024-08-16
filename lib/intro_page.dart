import 'dart:async';

import 'page_router.dart';
import 'package:flutter/material.dart';


class IntroPage extends StatefulWidget {
  final String title;
  final Widget mainPage;
  const IntroPage({Key? key, required this.title, required this.mainPage})
      : super(key: key);

  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  late Timer _timer;
  static const int freezeTime = 2;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: freezeTime),
      (timer) async {
        goToMainPage();
      },
    );
  }

  void goToMainPage() {
    _timer.cancel();
    Navigator.push(
      context,
      PageRouter(builder: (context) => widget.mainPage, duration: 1200,),
    );

  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 95, 126, 144),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Hero(tag: "mainIcon", child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset("assets/icon/icon.jpeg"))),
          ),
          Hero(
            tag: "appBarTitle",
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.black, decoration: TextDecoration.none,),
            ),
          )
        ],
      ),
    );
  }
}
