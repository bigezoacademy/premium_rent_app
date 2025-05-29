import 'package:flutter/material.dart';
import 'AppLayout.dart';

class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      body: Center(
          child: Column(children: [
        SizedBox(height: 100),
        Column(children: <Widget>[
          Image(
            image: AssetImage("assets/bigezow.png"),
            width: 250,
          ),
        ]),
        SizedBox(height: 20),
        Text('Elevating Property Experiences',
            style: TextStyle(color: Colors.black, fontSize: 20.0)),
      ])),
    );
  }
}
