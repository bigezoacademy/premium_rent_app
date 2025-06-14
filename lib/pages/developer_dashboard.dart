import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_service.dart';
import '../main.dart';

class DeveloperDashboard extends StatefulWidget {
  final VoidCallback? onLogout;
  const DeveloperDashboard({Key? key, this.onLogout}) : super(key: key);

  @override
  _DeveloperDashboardState createState() => _DeveloperDashboardState();
}

class _DeveloperDashboardState extends State<DeveloperDashboard> {
  bool isLoading = false;
  String? error;

  // Property Manager fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('G-Realm Studio Admin Dashboard'),
        backgroundColor: Color.fromARGB(255, 66, 170, 25),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
              if (widget.onLogout != null) {
                widget.onLogout!();
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Property Manager',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            if (isLoading) CircularProgressIndicator(),
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: isLoading ? null : _addManager,
              child: Text('Add Property Manager'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 66, 170, 25)),
            ),
            SizedBox(height: 32),
            Text('All Property Managers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(child: _buildManagersList()),
          ],
        ),
      ),
    );
  }

  Future<void> _addManager() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    // Validate fields
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      setState(() {
        isLoading = false;
        error = 'All fields are required.';
      });
      return;
    }
    try {
      // Create manager in Firestore (let them sign in with Google)
      final userRef = await FirebaseFirestore.instance.collection('users').add({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': 'Property Manager',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Auto-create credentials for the new property manager
      await FirebaseFirestore.instance
          .collection('credentials')
          .doc(userRef.id)
          .set({
        'userUid': userRef.id,
        'userEmail': emailController.text.trim(),
        'role': 'Property Manager',
        'createdAt': FieldValue.serverTimestamp(),
        'pesapal': {
          'userId': userRef.id,
          'email': emailController.text.trim(),
          'notification_id': '',
          'Consumer_key': '',
          'Consumer_secret': '',
          'callback_url': 'https://www.grealm.org/success',
        },
        'egosms': {
          'userId': userRef.id,
          'username': emailController.text.trim(),
          'password': '',
        }
      }, SetOptions(merge: true));
      nameController.clear();
      emailController.clear();
      phoneController.clear();
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildManagersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Property Manager')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading managers'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('No property managers found.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return ListTile(
              title: Text(doc['name'] ?? ''),
              subtitle: Text(doc['email'] ?? ''),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteManager(doc.id),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteManager(String docId) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).delete();
  }
}
