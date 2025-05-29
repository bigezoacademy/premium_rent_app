import 'package:flutter/material.dart';
import 'package:emet/receiptNumberHelper.dart'; // Import ReceiptNumberHelper
import 'package:emet/pages/PaymentForm.dart';
import 'package:path_provider/path_provider.dart';
import '../database_helper.dart';
import 'AppLayout.dart';
import 'ClientForm.dart' as ClientFormPage;
import 'package:share_plus/share_plus.dart';

class MyDatabase extends StatefulWidget {
  @override
  _DatabaseState createState() => _DatabaseState();
}

class _DatabaseState extends State<MyDatabase> {
  late String selectedMonth;
  late String apartment;
  late int receiptNomba = 0; // Initialize receipt number
  late String phone; // Declare the phone variable

  List<String> contactNames = []; // Declare the contactNames list

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  bool showList = false;

  @override
  void initState() {
    super.initState();
    ReceiptNumberHelper.instance.database;
    selectedMonth = months[0];
    apartment = '';
    updateContactList();
  }

  Future<void> updateContactList() async {
    List<Map<String, dynamic>> clients =
        await DatabaseHelper.instance.getClients();
    setState(() {
      contactNames =
          clients.map((client) => (client['name'] ?? '') as String).toList();
    });

    // Print all names to the console
    print('All Names in Database:');
    for (String name in contactNames) {
      print(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      body: Padding(
        padding: EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.lan),
                  SizedBox(width: 8),
                  Text(
                    'DATABASE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  DropdownButton<String>(
                    hint: Text('Select Month'),
                    value: selectedMonth,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMonth = newValue!;
                      });
                    },
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    items: months.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showList = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 3, 115, 171),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: Text(
                      'ALL CONTACTS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showList)
              Expanded(
                child: contactNames.isEmpty
                    ? Row(
                        children: [
                          Row(
                            children: [
                              Row(children: [
                                Text(
                                  'No data currently.',
                                  style: TextStyle(
                                      fontSize: 25,
                                      color: Color.fromARGB(255, 174, 0, 0)),
                                ),
                              ]),
                            ],
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: contactNames.length,
                        itemBuilder: (context, index) {
                          return _buildContactListItem(
                              index + 1, contactNames[index]);
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactListItem(int itemNumber, String contactName) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 250, 248, 205),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(width: 10),
              Text(
                '$itemNumber. $contactName',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.green),
                onPressed: () {
                  _navigateToEditScreen(contactName);
                },
              ),
              IconButton(
                icon: Icon(Icons.print,
                    color: const Color.fromARGB(255, 53, 53, 53)),
                onPressed: () {
                  createPaymentsTable();
                  _navigateToPaymentForm(contactName);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentListItem(Map<String, dynamic> payment) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 250, 248, 205),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.green),
              SizedBox(width: 5),
              Text(
                'Payment Date: ${payment['paymentDate']}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.blue),
              SizedBox(width: 5),
              Text(
                'Amount: ${payment['amount']}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          // Add other payment details as needed
        ],
      ),
    );
  }

  void _navigateToEditScreen(String contactName) {
    DatabaseHelper.instance.getClientByName(contactName).then((clientDetails) {
      if (clientDetails != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ClientFormPage.ClientForm(clientDetails: clientDetails),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Client details not found.'),
          ),
        );
      }
    });
  }

  void _navigateToPaymentForm(String contactName) async {
    try {
      Map<String, dynamic> clientDetails =
          await DatabaseHelper.instance.getClientByName(contactName);

      if (clientDetails.isNotEmpty) {
        phone = clientDetails['phone'];
        String month = selectedMonth;
        apartment = clientDetails['apartment'];
        try {
          // Removed the assignment of the result
          await ReceiptNumberHelper.instance.updateReceiptNumber();
        } catch (e) {
          print("Error updating receipt number in db: $e");
        }

        String year = DateTime.now().year.toString();

        List<Map<String, dynamic>> payments = await DatabaseHelper.instance
            .getPaymentsForMonth(clientDetails['id'], year);

        Map<String, dynamic> paymentDetails = {
          'clientId': clientDetails['id'],
          'name': clientDetails['name'],
          'apartment': clientDetails['apartment'],
          'selectedMonth': selectedMonth,
          'phone': phone,
        };

        if (payments.isNotEmpty) {
          paymentDetails.addAll(payments.first);
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentForm(paymentDetails: paymentDetails),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Client details not found.'),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to PaymentForm: $e');
      // Handle the exception or display an error message if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to PaymentForm. $e'),
        ),
      );
    }
  }

  Future<bool> createPaymentsTable() async {
    try {
      await DatabaseHelper.instance.createPaymentsTable();
      return true;
    } catch (e) {
      print('Error creating table: $e');
      return false;
    }
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
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
