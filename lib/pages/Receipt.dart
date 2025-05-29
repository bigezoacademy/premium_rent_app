import 'package:premium_rent_app/database_helper.dart';
import 'package:premium_rent_app/pages/AppLayout.dart';
import 'package:flutter/material.dart';
import '../receiptNumberHelper.dart';

class Receipt extends StatefulWidget {
  @override
  _ReceiptState createState() => _ReceiptState();
}

class _ReceiptState extends State {
  String message = '';
  int currentReceiptNumber = 0;
  TextEditingController _receiptNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      bool tableCreated = await createReceiptNumberTable();
      if (!tableCreated) {
        _showDialog('---', 'Table already exists');
        return;
      }
      _showDialog('Success', 'Table created successfully');
      await _loadCurrentReceiptNumber();
    } catch (e) {
      _showDialog('Error', 'Failed to initialize database: $e');
    }
  }

  Future<void> _loadCurrentReceiptNumber() async {
    int receiptNumber = await ReceiptNumberHelper.instance.getReceiptNumber();
    setState(() {
      currentReceiptNumber = receiptNumber;
      _receiptNumberController.text = currentReceiptNumber.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Set Receipt Number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _receiptNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter a Receipt Number',
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _resetReceiptNumber();
                },
                child: Text('Make current number'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> createReceiptNumberTable() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await DatabaseHelper.instance
          .createDbReceipt(); // Call the method from DatabaseHelper with the database instance
      return true;
    } catch (e) {
      print('Error creating table: $e');
      return false;
    }
  }

  void _showCurrentReceiptNumber() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Current Receipt Number'),
          content: Text('Receipt Number: $currentReceiptNumber'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAllTables() async {
    try {
      List<String> tables = await ReceiptNumberHelper.instance.getAllTables();
      _showDialog('All Tables', 'Tables: ${tables.join(", ")}');
    } catch (e) {
      _showDialog('Error', 'Failed to retrieve tables: $e');
    }
  }

  void _resetReceiptNumber() async {
    try {
      int newReceiptNumber = int.parse(_receiptNumberController.text);
      await ReceiptNumberHelper.instance.resetReceiptNumber(newReceiptNumber);
      await _loadCurrentReceiptNumber();
      _showDialog('Receipt Number Updated',
          'New Receipt Number: $currentReceiptNumber');
    } catch (e) {
      _showDialog('Error', 'Failed to update receipt number: $e');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
