import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import '../main.dart';

class TenantDashboard extends StatelessWidget {
  final VoidCallback? onLogout;
  final String? userId;
  final String? userEmail;
  const TenantDashboard({Key? key, this.onLogout, this.userId, this.userEmail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = userId ?? currentUser?.uid;
    final email = userEmail ?? currentUser?.email;
    if (uid == null && email == null) {
      return Scaffold(
        body: Center(child: Text('No user found. Please log in again.')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Tenant Dashboard'),
        backgroundColor: Color(0xFF8AC611),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
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
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _dashboardHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8AC611))),
        SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }

  Widget _dashboardCard(BuildContext context,
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: Icon(Icons.arrow_forward_ios, color: color),
        onTap: onTap,
      ),
    );
  }
}
