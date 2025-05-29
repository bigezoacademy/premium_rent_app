import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBtP-9epyGRNMnAv49qQ2SjeRqbKW8Pzvk",
        authDomain: "premium-rent-app.firebaseapp.com",
        projectId: "premium-rent-app",
        storageBucket: "premium-rent-app.firebasestorage.app",
        messagingSenderId: "191699518937",
        appId: "1:191699518937:web:099d0a08271e45f4d805c8",
        measurementId: "G-YGP85GDL9L",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Premium Rent App',
      theme: ThemeData(
        primaryColor: Color(0xFF8AC611),
        colorScheme:
            ColorScheme.fromSwatch().copyWith(secondary: Color(0xFFC65611)),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: AuthHomeScreen(),
    );
  }
}

class AuthHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome to Premium Rent App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Sign Up'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
            ),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
