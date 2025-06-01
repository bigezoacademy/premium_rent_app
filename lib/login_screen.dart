import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'google_signin_button.dart'; // Import the GoogleSignInButton
import 'pages/manager_dashboard.dart'; // Import the ManagerDashboard
import 'pages/owner_dashboard.dart'; // Import the OwnerDashboard
import 'pages/tenant_property_select.dart'; // Import the TenantPropertySelectScreen
import 'pages/developer_dashboard.dart'; // Import the DeveloperDashboard
import 'pages/public_property_listing.dart'; // Import the PublicPropertyListingPage

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Enter password' : null,
              ),
              SizedBox(height: 20),
              if (isLoading) CircularProgressIndicator(),
              if (error.isNotEmpty)
                Text(error, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: isLoading ? null : _login,
                child: Text('Login'),
              ),
              SizedBox(height: 12),
              GoogleSignInButton(
                isLoading: isLoading,
                onPressed: isLoading ? null : _signInWithGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        error = '';
      });
      try {
        final user = await AuthService().signInWithEmail(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        if (user != null) {
          // Fetch user role and info from Firestore
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final data = doc.data() ?? {};
          final role = data['role'] ?? 'Tenant';
          final name = data['name'] ?? '';
          final email = data['email'] ?? user.email ?? '';
          // Show detected role
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Detected role: ' + role),
              duration: Duration(seconds: 2),
            ),
          );
          if (email == 'grealmkids@gmail.com') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DeveloperDashboard()),
            );
            return;
          }
          Widget dashboard;
          if (role == 'Property Manager') {
            dashboard = ManagerDashboard(userName: name, userEmail: email);
          } else if (role == 'Property Owner') {
            dashboard = OwnerDashboard();
          } else {
            // Route tenant to property selection screen
            dashboard =
                TenantPropertySelectScreen(userId: user.uid, userEmail: email);
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => dashboard),
          );
        } else {
          // User does not exist, show dialog with options
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Account Not Found'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To create a new property manager account, contact:'),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.message, color: Colors.green),
                      SizedBox(width: 8),
                      Text('+256773913902',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('propertyapp@grealm.org',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 8),
                  Text('Or start renting a property:'),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.home),
                    label: Text('View Properties'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PublicPropertyListingPage()),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Close'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
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
  }

  void _signInWithGoogle() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      final user = await AuthService().signInWithGoogle(checkOnly: true);
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = userDoc.data() ?? {};
        final role = data['role'] ?? 'Tenant';
        final name = data['name'] ?? '';
        final email = data['email'] ?? user.email ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detected role: ' + role),
            duration: Duration(seconds: 2),
          ),
        );
        Widget dashboard;
        if (email == 'grealmkids@gmail.com') {
          dashboard = DeveloperDashboard();
        } else if (role == 'Property Manager') {
          dashboard = ManagerDashboard(userName: name, userEmail: email);
        } else if (role == 'Property Owner') {
          dashboard = OwnerDashboard();
        } else {
          dashboard =
              TenantPropertySelectScreen(userId: user.uid, userEmail: email);
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => dashboard),
        );
      } else {
        // User does not exist, show dialog with options
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Account Not Found'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('To create a new property manager account, contact:'),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.message, color: Colors.green),
                    SizedBox(width: 8),
                    Text('+256773913902',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('propertyapp@grealm.org',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 24),
                Divider(),
                SizedBox(height: 8),
                Text('Or start renting a property:'),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.home),
                  label: Text('View Properties'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PublicPropertyListingPage()),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
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
}
