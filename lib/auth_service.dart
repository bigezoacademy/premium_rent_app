import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String role,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'role': role,
          ...profileData,
        });
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithGoogle({bool checkOnly = false}) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      if (user != null) {
        final isDeveloper = user.email == 'grealmkids@gmail.com';
        // Query Firestore for any user with this email
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          // User exists in Firestore by email, update UID doc with all fields and remove duplicates
          final doc = query.docs.first;
          final data = doc.data();
          final userRef = _firestore.collection('users').doc(user.uid);
          // Merge all fields, including displayName, photoURL, createdAt, etc.
          final mergedData = {
            ...data,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'email': user.email,
            'role': data['role'] ?? 'Property Manager',
            'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          };
          await userRef.set(mergedData, SetOptions(merge: true));
          // Remove any other docs with the same email but different UID
          for (final d in query.docs) {
            if (d.id != user.uid) {
              await _firestore.collection('users').doc(d.id).delete();
            }
          }
          if (isDeveloper && mergedData['role'] != 'Developer') {
            await userRef.update({'role': 'Developer'});
          }
          return user;
        } else {
          // User does not exist in Firestore, do NOT create a new user
          // Return null so UI can show dialog with contact info and public property listing option
          await _auth.signOut();
          return null;
        }
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> get userChanges => _auth.userChanges();

  String? currentUserId() => _auth.currentUser?.uid;

  Future<void> ensureAdminUserExists() async {
    final adminEmail = 'grealmkids@gmail.com';
    final userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: adminEmail)
        .limit(1)
        .get();
    if (userQuery.docs.isEmpty) {
      await _firestore.collection('users').add({
        'email': adminEmail,
        'name': 'G-Realm Studio',
        'role': 'Developer',
        'phone': '+256773913902',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
