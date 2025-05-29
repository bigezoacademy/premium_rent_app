import 'package:emet/pages/AppLayout.dart';
import 'package:flutter/material.dart';
import 'package:emet/database_helper.dart';

class Analytics extends StatefulWidget {
  @override
  _AnalyticsState createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  int totalClients = 0;

  @override
  void initState() {
    super.initState();
    updateTotalClients();
  }

  Future<void> updateTotalClients() async {
    List<Map<String, dynamic>> clients =
        await DatabaseHelper.instance.getClients();
    setState(() {
      totalClients = clients.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
        body: Center(
      child: Padding(
        padding: EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.analytics),
                  SizedBox(width: 30.0),
                  Text(
                    'ANALYTICS',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Total Clients:',
                style: TextStyle(
                  color: Color.fromARGB(255, 195, 54, 54),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                totalClients.toString(),
                style: TextStyle(
                  backgroundColor: Color.fromARGB(255, 255, 241, 148),
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
