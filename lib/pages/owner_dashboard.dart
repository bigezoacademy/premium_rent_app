import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_service.dart';
import '../main.dart';

class OwnerDashboard extends StatelessWidget {
  final VoidCallback? onLogout;
  const OwnerDashboard({Key? key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Owner Dashboard'),
        backgroundColor: Color.fromARGB(255, 66, 170, 25),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
              if (onLogout != null) {
                onLogout!();
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AuthHomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('properties').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading properties'));
          }
          final properties = snapshot.data?.docs ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final doc = properties[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(doc['name'] ?? 'Unnamed',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text(doc['location'] ?? ''),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: const Color(0xFFC65611)),
                  onTap: () {}, // TODO: Implement property details navigation
                ),
              );
            },
          );
        },
      ),
    );
  }
}
