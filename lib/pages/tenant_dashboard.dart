import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
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
        appBar: AppBar(
          leading: BackButton(),
          title: Text('Tenant Dashboard'),
        ),
        body: Center(child: Text('No user found. Please log in again.')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(),
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
                // Print the error to the browser console for debugging
                print('[TenantDashboard] Error loading properties:');
                print(snapshot.error);
                if (snapshot.stackTrace != null) print(snapshot.stackTrace);
                // Show the UI with disabled dropdown and enabled Add Property button
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Manage a Property',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8AC611))),
                    SizedBox(height: 24),
                    DropdownButton<String>(
                      value: null,
                      hint: Text('Choose Property'),
                      items: [],
                      onChanged: null, // Disabled
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFC65611),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        elevation: 0,
                      ),
                      child: Text('Add New Property'),
                      onPressed: () {
                        // TODO: Implement add property dialog or navigation
                      },
                    ),
                    SizedBox(height: 16),
                    Center(
                        child: Text('Error loading properties',
                            style: TextStyle(color: Colors.red))),
                  ],
                );
              }
              final properties = snapshot.data?.docs ?? [];
              if (properties.isEmpty) {
                return Center(child: Text('No assigned properties found.'));
              }
              return ListView.builder(
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final doc = properties[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: ListTile(
                      title: Text(doc['name'] ?? 'Unnamed'),
                      subtitle: Text(doc['location'] ?? ''),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TenantPropertyDetailPage(
                              propertyDoc: doc,
                              tenantEmail: email,
                            ),
                          ),
                        );
                      },
                    ),
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

class TenantPropertyDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot propertyDoc;
  final String? tenantEmail;
  const TenantPropertyDetailPage(
      {Key? key, required this.propertyDoc, this.tenantEmail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = propertyDoc.data() as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text(data['name'] ?? 'Property Details'),
        backgroundColor: Color(0xFF8AC611),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${data['location'] ?? ''}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Category: ${data['category'] ?? ''}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Manager: ${data['managerName'] ?? ''}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Manager Email: ${data['managerEmail'] ?? ''}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Manager Phone: ${data['managerPhone'] ?? ''}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 24),
            Divider(),
            Text('Tenant Dashboard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.payment),
                  label: Text('Pay Rent'),
                  onPressed: () {
                    // TODO: Implement rent payment logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Rent payment coming soon!')),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.email),
                  label: Text('Contact Manager'),
                  onPressed: () {
                    // TODO: Implement email launch
                    final emailUri = Uri(
                      scheme: 'mailto',
                      path: data['managerEmail'] ?? '',
                      query:
                          'subject=Tenant Inquiry&body=Hello, I am your tenant.',
                    );
                    launchUrl(emailUri);
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.description),
                  label: Text('View Lease'),
                  onPressed: () {
                    // TODO: Implement lease viewing
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lease viewing coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
