import 'package:flutter/material.dart';

class PlatformWebView extends StatelessWidget {
  final String url;
  const PlatformWebView({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('WebView is not supported on this platform.'),
    );
  }
}
