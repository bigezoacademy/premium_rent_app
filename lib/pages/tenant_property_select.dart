import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tenant_dashboard.dart';

class TenantPropertySelectScreen extends StatelessWidget {
  final String userId;
  final String userEmail;
  const TenantPropertySelectScreen(
      {Key? key, required this.userId, required this.userEmail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Property'),
        backgroundColor: Color(0xFF3b6939),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError ||
              !userSnapshot.hasData ||
              !userSnapshot.data!.exists) {
            return Center(child: Text('Error loading user data'));
          }
          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final List<dynamic> assignedPropertyIds =
              userData?['properties'] ?? [];
          if (assignedPropertyIds.isEmpty) {
            return Center(child: Text('No properties assigned to you yet.'));
          }
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('properties')
                .where(FieldPath.documentId, whereIn: assignedPropertyIds)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading properties'));
              }
              final properties = snapshot.data?.docs ?? [];
              if (properties.isEmpty) {
                return Center(child: Text('No assigned properties found.'));
              }
              return ListView.builder(
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final doc = properties[index];
                  return ListTile(
                    title: Text(doc['name'] ?? 'Unnamed'),
                    subtitle: Text(doc['location'] ?? ''),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TenantDashboard(
                            userId: userId,
                            userEmail: userEmail,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
