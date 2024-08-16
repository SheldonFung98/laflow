import 'package:flutter/material.dart';
import 'main_page.dart';
import 'package:provider/provider.dart';
import 'intro_page.dart';
import 'camera_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraProvider()),
      ],
      child: LaFlowAPP(),
    ),
  );
}

class LaFlowAPP extends StatelessWidget {
  const LaFlowAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaFlow',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const IntroPage(
        title: 'LaFlow',
        mainPage: MainPage(),
      ),
    );
  }
}
