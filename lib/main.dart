import 'package:emet/pages/ClientForm.dart';
import 'package:emet/pages/home.dart';

import 'pages/Dashboard.dart';
import 'package:flutter/material.dart';
import 'pages/SendSms.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}
