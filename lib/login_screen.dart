import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuthException
import 'auth_service.dart';
import 'google_signin_button.dart'; // Import the GoogleSignInButton
import 'pages/manager_dashboard.dart'; // Import the ManagerDashboard
import 'pages/owner_dashboard.dart'; // Import the OwnerDashboard
import 'pages/tenant_dashboard.dart'; // Import the TenantDashboard
import 'pages/developer_dashboard.dart'; // Import the DeveloperDashboard
import 'pages/public_property_listing.dart'; // Import the PublicPropertyListingPage
import 'pages/tenant_entry.dart'; // Ensure NewUserLandingPage is imported

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
              SizedBox(height: 30),
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
          if (!doc.exists) {
            // User does not exist, create with role 'null'
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'email': user.email,
              'role': 'null',
              'createdAt': FieldValue.serverTimestamp(),
            });
            print(
                '[LOGIN] Created new user with role null, redirecting to NewUserLandingPage');
            setState(() {
              error = '';
              isLoading = false;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NewUserLandingPage(),
              ),
            );
            return;
          }
          final data = doc.data() ?? {};
          final role = (data['role'] ?? '').toString();
          final name = data['name'] ?? '';
          final email = data['email'] ?? user.email ?? '';
          print('[LOGIN] User role: ' + role);
          Widget dashboard;
          if (email == 'grealmkids@gmail.com') {
            dashboard = DeveloperDashboard();
          } else if (role.toLowerCase() == 'property manager') {
            dashboard = ManagerDashboard(userName: name, userEmail: email);
          } else if (role.toLowerCase() == 'property owner') {
            dashboard = OwnerDashboard();
          } else if (role.toLowerCase() == 'tenant') {
            dashboard = TenantDashboard(userId: user.uid, userEmail: email);
          } else if (role.trim().isEmpty ||
              role == 'null' ||
              role == 'undefined') {
            print(
                '[LOGIN] User has undefined/null/empty role, redirecting to NewUserLandingPage');
            setState(() {
              error = '';
              isLoading = false;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NewUserLandingPage(),
              ),
            );
            return;
          } else {
            print(
                '[LOGIN] Fallback: unknown role, redirecting to NewUserLandingPage');
            setState(() {
              error = '';
              isLoading = false;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NewUserLandingPage(),
              ),
            );
            return;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => dashboard),
          );
        } else {
          print('[LOGIN] Authentication failed: user is null');
          setState(() {
            error = 'Authentication failed. Please try again.';
            isLoading = false;
          });
        }
      } on FirebaseAuthException catch (e) {
        print(
            '[LOGIN] FirebaseAuthException: code=[31m${e.code}[0m, message=${e.message}');
        if (e.code == 'user-not-found') {
          try {
            final user = await AuthService().signUpWithEmail(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
              role: 'null',
              profileData: {},
            );
            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({
                'email': user.email,
                'role': 'null',
                'createdAt': FieldValue.serverTimestamp(),
              });
              print(
                  '[LOGIN] Created Firebase Auth and Firestore user doc for new user: ' +
                      user.uid);
            }
            setState(() {
              error = '';
              isLoading = false;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NewUserLandingPage(),
              ),
            );
          } catch (signupError) {
            print('[LOGIN] Failed to create Firebase Auth/Firestore user: ' +
                signupError.toString());
            setState(() {
              error = 'Failed to create account: ' + signupError.toString();
              isLoading = false;
            });
          }
        } else {
          setState(() {
            error = e.message ?? e.toString();
            isLoading = false;
          });
        }
      } catch (e) {
        print('[LOGIN] Exception (non-FirebaseAuth): ' +
            e.toString() +
            ' type=' +
            e.runtimeType.toString());
        setState(() {
          error = e.toString();
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
        if (!userDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NewUserLandingPage(),
            ),
          );
          setState(() {
            isLoading = false;
          });
          return;
        }
        final data = userDoc.data() ?? {};
        final role = (data['role'] ?? 'Tenant').toString();
        final name = data['name'] ?? '';
        final email = data['email'] ?? user.email ?? '';
        Widget dashboard;
        if (email == 'grealmkids@gmail.com') {
          dashboard = DeveloperDashboard();
        } else if (role.toLowerCase() == 'property manager') {
          dashboard = ManagerDashboard(userName: name, userEmail: email);
        } else if (role.toLowerCase() == 'property owner') {
          dashboard = OwnerDashboard();
        } else if (role.toLowerCase() == 'tenant') {
          dashboard = TenantDashboard(userId: user.uid, userEmail: email);
        } else {
          _showNewUserOptions(context);
          setState(() {
            isLoading = false;
          });
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => dashboard),
        );
      } else {
        _showNewUserOptions(context);
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

  void _showNewUserOptions(BuildContext context) {
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
}
