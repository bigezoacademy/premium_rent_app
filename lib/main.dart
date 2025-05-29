import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'pages/tenant_dashboard.dart';
import 'pages/manager_dashboard.dart';
import 'pages/owner_dashboard.dart';
import 'pages/developer_dashboard.dart';

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8AC611),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  elevation: 0,
                ),
                child: Text('Sign Up'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFC65611),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  elevation: 0,
                ),
                child: Text('Login'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
              SizedBox(height: 32),
              Text('Access Dashboards Directly (No Login Required)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFC65611))),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8AC611),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                      elevation: 0,
                    ),
                    child: Text('Tenant'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TenantDashboard()));
                    },
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFC65611),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                      elevation: 0,
                    ),
                    child: Text('Manager'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ManagerDashboard()));
                    },
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                      elevation: 0,
                    ),
                    child: Text('Owner'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => OwnerDashboard()));
                    },
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Color(0xFF1A237E), // Deep blue for G-Realm Studio
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                      elevation: 0,
                    ),
                    child: Text('G-Realm Studio'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DeveloperDashboard()));
                    },
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'You can access all dashboards above without authentication for now. Once Firebase Auth is configured, these can be restricted.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
