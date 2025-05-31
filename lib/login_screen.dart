import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'google_signin_button.dart'; // Import the GoogleSignInButton
import 'pages/manager_dashboard.dart'; // Import the ManagerDashboard
import 'pages/owner_dashboard.dart'; // Import the OwnerDashboard
import 'pages/tenant_property_select.dart'; // Import the TenantPropertySelectScreen
import 'pages/developer_dashboard.dart'; // Import the DeveloperDashboard

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
      await AuthService().signInWithGoogle();
      Navigator.pop(context);
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
