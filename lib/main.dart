import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'pages/manager_dashboard.dart';
import 'pages/owner_dashboard.dart';
import 'pages/developer_dashboard.dart';
import 'firebase_options.dart';
import 'pages/tenant_dashboard.dart';
import 'pages/tenant_entry.dart';
import 'package:url_launcher/url_launcher.dart';

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
  // No-op: Firestore collections are created automatically when you add a document.
}

Future<void> ensureCollectionsAndLinksForUser(
    String userId, String userEmail, String userName, String role) async {
  final firestore = FirebaseFirestore.instance;
  // Removed collection creation logic for '__init__'.
  // Auto-link user to billing and credentials collections only (no starter property/tenant)
  if (role == 'Property Manager' || role == 'Tenant') {
    try {
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
    } catch (e, st) {
      print('[Firestore Init] Error adding billing doc for user: '
          '\u001b[31m$userEmail\u001b[0m');
      print(e);
      print(st);
    }
    try {
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
    } catch (e, st) {
      print('[Firestore Init] Error adding credentials doc for user: '
          '\u001b[31m$userEmail\u001b[0m');
      print(e);
      print(st);
    }
  }
}

Future<void> patchOldManagerCredentials() async {
  final credentialsRef = FirebaseFirestore.instance.collection('credentials');
  final snapshot = await credentialsRef.get();

  for (final doc in snapshot.docs) {
    final data = doc.data();
    if (data['role'] == 'Property Manager') {
      final userId = data['userUid'] ?? doc.id;
      final email = data['userEmail'] ?? '';
      final pesapal = data['pesapal'] ?? {};
      final egosms = data['egosms'] ?? {};

      await credentialsRef.doc(doc.id).set({
        'userUid': userId,
        'userEmail': email,
        'role': 'Property Manager',
        'pesapal': {
          'userId': pesapal['userId'] ?? userId,
          'email': pesapal['email'] ?? email,
          'notification_id': pesapal['notification_id'] ?? '',
          'Consumer_key': pesapal['Consumer_key'] ?? '',
          'Consumer_secret': pesapal['Consumer_secret'] ?? '',
        },
        'egosms': {
          'userId': egosms['userId'] ?? userId,
          'username': egosms['username'] ?? email,
          'password': egosms['password'] ?? '',
        }
      }, SetOptions(merge: true));
    }
  }
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Premium Rent App',
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 21, 136, 54),
        colorScheme:
            ColorScheme.fromSwatch().copyWith(secondary: Color(0xFFC65611)),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'Poppins',
            ),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      ),
      home: _showSplash ? SplashScreen() : AuthHomeScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo.png', // Change to your preferred asset
          width: 180,
          fit: BoxFit.contain,
        ),
      ),
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
        if (!userDoc.exists) {
          // New user: show landing page with options
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NewUserLandingPage(),
            ),
          );
          return;
        }
        final data = userDoc.data() ?? {};
        final role = (data['role'] ?? 'Tenant').toString();
        print('[DEBUG] Logged in user role: ' + role.toString());
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
        } else if (role.toLowerCase() == 'property manager') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ManagerDashboard(userName: name, userEmail: email)),
          );
        } else if (role.toLowerCase() == 'property owner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OwnerDashboard()),
          );
        } else if (role.toLowerCase() == 'tenant') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => TenantDashboard(userEmail: email)),
          );
        } else {
          // Fallback: treat as new user
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NewUserLandingPage(),
            ),
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

  // Add a back button to the AuthHomeScreen (if not already at root)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 32),
              // App icon above Google button
              Image.asset(
                'assets/bigezo.png',
                width: 220, // Increased width
                height: 220, // Increased height
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
                onPressed: isLoading ? null : _handleGoogleAuth,
                child: isLoading
                    ? SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.asset(
                        'assets/googlein.png',
                        height: 100,
                        width: 250,
                        fit: BoxFit.contain,
                      ),
              ),
              SizedBox(height: 24),
              // Add the public welcome card below the sign-in button
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      // Property Manager info above the contact button
                      Text(
                        'Want to become a property manager?',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: Icon(Icons.business, color: Colors.white),
                        label: Text('Contact G-Realm Studio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 21, 136, 54),
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Contact G-Realm Studio'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('WhatsApp: +256773913902'),
                                  SizedBox(height: 8),
                                  Text('Email: admin@grealm.org'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  child: Text('Close'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                TextButton(
                                  child: Text('Chat on WhatsApp'),
                                  onPressed: () async {
                                    String phone = '0773913902';
                                    if (phone.startsWith('0')) {
                                      phone = '+256' + phone.substring(1);
                                    }
                                    final phoneUri = Uri.parse(
                                        'https://wa.me/${phone.replaceAll('+', '')}');
                                    await launchUrl(phoneUri,
                                        mode: LaunchMode.externalApplication);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      // Tenant info above the property listing button
                      Text(
                        'Looking to rent? Browse our available properties!',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: Icon(Icons.home, color: Colors.white),
                        label: Text('View Property Listings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF002366), // Dark grey
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PropertyPublicListing()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
