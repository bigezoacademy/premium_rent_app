import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'google_signin_button.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = 'Tenant';
  bool isLoading = false;
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
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
                validator: (value) => value!.length < 6 ? 'Min 6 chars' : null,
              ),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: ['Tenant', 'Property Manager', 'Property Owner']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => selectedRole = val!),
                decoration: InputDecoration(labelText: 'Role'),
              ),
              SizedBox(height: 20),
              if (isLoading) CircularProgressIndicator(),
              if (error.isNotEmpty)
                Text(error, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: isLoading ? null : _signUp,
                child: Text('Sign Up'),
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

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
        error = '';
      });
      try {
        await AuthService().signUpWithEmail(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          role: selectedRole,
          profileData: {},
        );
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
