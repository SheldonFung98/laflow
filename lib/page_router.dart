import 'package:flutter/material.dart';

class PageRouter extends MaterialPageRoute {
  final int duration;
  @override
  Duration get transitionDuration => Duration(milliseconds: duration);
  PageRouter({required this.duration, required WidgetBuilder builder}) : super(builder: builder);
}