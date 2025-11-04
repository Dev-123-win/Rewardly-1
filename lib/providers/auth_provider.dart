import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  // Email/Password Sign Up
  Future<void> signUpWithEmailAndPassword(
      String email, String password, String referralCode) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user != null) {
      // Create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName ?? user.email!.split('@')[0],
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'referralCode': _generateReferralCode(user.uid),
        'referredBy': referralCode.isNotEmpty ? referralCode : null,
        'coinBalance': referralCode.isNotEmpty ? 200 : 0, // Referee bonus
        'totalEarned': referralCode.isNotEmpty ? 200 : 0,
        'totalWithdrawn': 0,
        'activeDays': [],
        'lastActiveDate': '',
        'dailyStats': {},
        'withdrawalInfo': {},
      });

      // If a referral code was used, update referrer's balance (will be credited after 3 active days)
      if (referralCode.isNotEmpty) {
        // For now, we'll just create a referral record. The actual coin credit will be handled by a separate logic
        // based on active days, as per the plan.
        await _firestore.collection('referrals').add({
          'referrerId': '', // This needs to be looked up based on referralCode
          'refereeId': user.uid,
          'refereeActiveDays': 0,
          'referrerRewarded': false,
          'refereeRewarded': true, // Referee gets coins immediately
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': null,
        });
        // TODO: Find referrerId based on referralCode and update referral document
      }
    }
    notifyListeners();
  }

  // Email/Password Sign In
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    bool isNewUser = false;

    if (googleAuth != null) {
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if user already exists in Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          isNewUser = true;
          // New user, create document
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'referralCode': _generateReferralCode(user.uid),
            'referredBy':
                null, // Google Sign-In doesn't have referral code input initially
            'coinBalance': 0,
            'totalEarned': 0,
            'totalWithdrawn': 0,
            'activeDays': [],
            'lastActiveDate': '',
            'dailyStats': {},
            'withdrawalInfo': {},
          });
        }
      }
    }
    notifyListeners();
    return isNewUser;
  }

  // Apply referral code
  Future<void> applyReferralCode(String referralCode) async {
    if (referralCode.isEmpty) return;
    final user = currentUser;
    if (user == null) return;

    // This is a simplified approach. A robust implementation would use a UserProvider
    // to handle this logic, but for the scope of this file, we'll do it here.
    final userRef = _firestore.collection('users').doc(user.uid);

    // Find the referrer
    final querySnapshot = await _firestore
        .collection('users')
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final referrerDoc = querySnapshot.docs.first;
      if (referrerDoc.id != user.uid) {
        // Update the current user's document
        await userRef.update({
          'referredBy': referralCode,
          'coinBalance': FieldValue.increment(200), // Referee bonus
          'totalEarned': FieldValue.increment(200),
        });

        // Create a referral record
        await _firestore.collection('referrals').add({
          'referrerId': referrerDoc.id,
          'refereeId': user.uid,
          'refereeActiveDays': 0,
          'referrerRewarded': false,
          'refereeRewarded': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut(); // Also sign out from Google
    notifyListeners();
  }

  String _generateReferralCode(String uid) {
    // Simple referral code generation from UID, can be improved
    return uid.substring(0, 6).toUpperCase();
  }
}
