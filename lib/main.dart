import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_service.dart';
import 'pages/manager_dashboard.dart';
import 'pages/tenant_property_select.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/owner_dashboard.dart';
import 'pages/developer_dashboard.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: firebaseWebOptions['apiKey']!,
          authDomain: firebaseWebOptions['authDomain']!,
          projectId: firebaseWebOptions['projectId']!,
          storageBucket: firebaseWebOptions['storageBucket']!,
          messagingSenderId: firebaseWebOptions['messagingSenderId']!,
          appId: firebaseWebOptions['appId']!,
          measurementId: firebaseWebOptions['measurementId']!,
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    await AuthService().ensureAdminUserExists();
    // If you have any other async setup, keep it here
  } catch (e, st) {
    print('Startup error:');
    print(e);
    print(st);
  }
  runApp(MyApp());
}

Future<void> ensureCollectionsExist() async {
  final firestore = FirebaseFirestore.instance;
  // Create a dummy doc in each collection if it doesn't exist, then delete it (to ensure collection exists)
  final collections = ['properties', 'billing', 'credentials', 'tenants'];
  for (final col in collections) {
    final ref = firestore.collection(col).doc('__init__');
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({'init': true});
      await ref.delete();
    }
  }
}

Future<void> ensureCollectionsAndLinksForUser(
    String userId, String userEmail, String userName, String role) async {
  final firestore = FirebaseFirestore.instance;
  // Ensure collections exist
  final collections = ['properties', 'billing', 'credentials', 'tenants'];
  for (final col in collections) {
    final ref = firestore.collection(col).doc('__init__');
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({'init': true});
      await ref.delete();
    }
  }
  // Auto-link user to billing and credentials collections only (no starter property/tenant)
  if (role == 'Property Manager' || role == 'Tenant') {
    final billingQuery = await firestore
        .collection('billing')
        .where('userEmail', isEqualTo: userEmail)
        .limit(1)
        .get();
    if (billingQuery.docs.isEmpty) {
      await firestore.collection('billing').add({
        'userEmail': userEmail,
        'userUid': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'role': role,
      });
    }
    final credentialsQuery = await firestore
        .collection('credentials')
        .where('userEmail', isEqualTo: userEmail)
        .limit(1)
        .get();
    if (credentialsQuery.docs.isEmpty) {
      await firestore.collection('credentials').add({
        'userEmail': userEmail,
        'userUid': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'role': role,
      });
    }
  }
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
        fontFamily: 'Trebuchet MS',
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'Trebuchet MS',
            ),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            fontFamily: 'Trebuchet MS',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: TextStyle(fontFamily: 'Trebuchet MS'),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: TextStyle(fontFamily: 'Trebuchet MS'),
          ),
        ),
      ),
      home: AuthHomeScreen(),
    );
  }
}

class AuthHomeScreen extends StatefulWidget {
  @override
  State<AuthHomeScreen> createState() => _AuthHomeScreenState();
}

class _AuthHomeScreenState extends State<AuthHomeScreen> {
  bool isLoading = false;
  String? errorMessage;

  Future<void> _handleGoogleAuth() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = userDoc.data() ?? {};
        final role = data['role'] ?? 'Tenant';
        final name = data['name'] ?? '';
        final email = data['email'] ?? user.email ?? '';
        // Auto-link user to collections (no starter property/tenant)
        await ensureCollectionsAndLinksForUser(user.uid, email, name, role);
        // Check if user.email == 'grealmkids@gmail.com', if so, route to DeveloperDashboard
        if (email == 'grealmkids@gmail.com') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DeveloperDashboard()),
          );
        } else if (role == 'Property Manager') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ManagerDashboard(userName: name, userEmail: email)),
          );
        } else if (role == 'Property Owner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OwnerDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => TenantPropertySelectScreen(
                    userId: user.uid, userEmail: email)),
          );
        }
      } else {
        setState(() {
          errorMessage = 'Authentication failed. Please try again.';
        });
      }
    } catch (e) {
      // Detect redirect_uri_mismatch and show a friendly message
      String msg = e.toString();
      if (msg.contains('redirect_uri_mismatch') ||
          msg.contains('invalid request')) {
        errorMessage =
            'Google sign-in failed due to a configuration error (redirect_uri_mismatch).\nPlease contact support or check your Google API Console settings.';
      } else {
        setState(() {
          errorMessage = e.toString();
        });
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    await AuthService().signOut();
    setState(() {
      errorMessage = null;
      isLoading = false;
    });
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AuthHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 32),
              // App icon above Google button
              Image.asset(
                'assets/icon.png',
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 18),
              if (errorMessage != null) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[400]),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          errorMessage!,
                          style:
                              TextStyle(color: Colors.red[800], fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.asset(
                        'assets/googlein.png',
                        height: 40,
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                onPressed: isLoading ? null : _handleGoogleAuth,
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
