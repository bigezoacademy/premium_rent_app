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

  Future<User?> signInWithGoogle() async {
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
          // User exists in Firestore by email, update UID doc if needed
          final doc = query.docs.first;
          final data = doc.data();
          // If the Firestore doc is not at the current UID, copy to UID doc if needed
          final userRef = _firestore.collection('users').doc(user.uid);
          final userDoc = await userRef.get();
          if (!userDoc.exists) {
            await userRef.set(data);
          } else {
            // Optionally, update fields if needed (e.g., displayName, photoURL)
            await userRef.update({
              'displayName': user.displayName,
              'photoURL': user.photoURL,
            });
          }
          // Always enforce correct role for developer
          if (isDeveloper && data['role'] != 'Developer') {
            await userRef.update({'role': 'Developer'});
          }
        } else {
          // No user with this email exists in Firestore, create new user
          // Only allow Developer or Property Manager to be created here
          String role = isDeveloper ? 'Developer' : 'Property Manager';
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'role': role,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          });
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
}
