import 'package:premium_rent_app/pages/Analytics.dart';
import 'package:premium_rent_app/pages/ClientForm.dart';
import 'package:premium_rent_app/pages/NewClientForm.dart';
import 'package:premium_rent_app/pages/PaymentForm.dart';
import 'package:premium_rent_app/pages/Dashboard.dart';
import 'package:premium_rent_app/pages/Properties.dart';
import 'package:premium_rent_app/pages/home.dart';
import 'package:premium_rent_app/pages/MyDatabase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'Receipt.dart';

class AppLayout extends StatelessWidget {
  final Widget body;

  AppLayout({required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EMET Property Management',
          style: TextStyle(
            color: const Color.fromARGB(255, 255, 255, 255),
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white, // Change the color of the menu icon here
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Home()));
            },
            icon: Icon(Icons.logout),
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ],
        backgroundColor: Color.fromARGB(255, 29, 29, 1),
        elevation: 20,
      ),
      drawer: AppDrawer(),
      body: body,
    );
  }
}

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 6, 130, 31),
              ),
              child: Column(children: <Widget>[
                Image(
                  image: AssetImage("assets/bigezow.png"),
                  width: 100,
                ),
              ])),
          ListTile(
            leading: Icon(Icons.person_add_alt),
            title: Text('New Contact', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => NewClientForm()));
            },
          ),
          ListTile(
            leading: Icon(Icons.print),
            title: Text('Database', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => MyDatabase()));
            },
          ),
          ListTile(
            leading: Icon(Icons.trending_up),
            title: Text('Analytics', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Analytics()));
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt),
            title:
                Text('Receipt Number', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Receipt()));
            },
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Properties', style: TextStyle(color: Colors.black)),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Properties()));
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout', style: TextStyle(color: Colors.black)),
            onTap: () {
              // Handle Logout click
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Home()));
            },
          ),
        ],
      ),
    );
  }
}
