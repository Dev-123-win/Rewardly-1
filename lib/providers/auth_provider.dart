import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user.dart' as app_models;
import 'user_provider.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserProvider _userProvider;

  AuthProvider(this._userProvider);

  User? get firebaseUser => _auth.currentUser;

  Future<String?> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    }
    return null;
  }

  // Email/Password Sign Up
  Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String referralCode,
  ) async {
    final deviceId = await _getDeviceId();
    final prefs = await SharedPreferences.getInstance();

    // Check device limit
    if (deviceId != null) {
      final existingUserId = prefs.getString('device_$deviceId');
      if (existingUserId != null) {
        throw Exception('Only one account can be created per device.');
      }
    }

    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user != null) {
      // Create local user
      final newUser = app_models.User(
        uid: user.uid,
        email: email,
        displayName: email.split('@')[0],
        photoURL: null,
        referralCode: _generateReferralCode(user.uid),
        referredBy: referralCode.isNotEmpty ? referralCode : null,
        coins: referralCode.isNotEmpty ? 200 : 0, // Referee bonus
        totalEarned: referralCode.isNotEmpty ? 200 : 0,
        totalWithdrawn: 0,
        activeDays: [],
        lastActiveDate: DateTime.now(),
        dailyStats: {},
      );

      // Save user data
      await _userProvider.saveNewUser(newUser);

      // Save device ID association
      if (deviceId != null) {
        await prefs.setString('device_$deviceId', user.uid);
      }

      // Handle referral if code was used
      if (referralCode.isNotEmpty) {
        // Save referral relationship locally
        final referrals = prefs.getStringList('referrals_${user.uid}') ?? [];
        referrals.add(
          jsonEncode({
            'refereeId': user.uid,
            'referralCode': referralCode,
            'refereeActiveDays': 0,
            'referrerRewarded': false,
            'refereeRewarded': true,
            'createdAt': DateTime.now().toIso8601String(),
            'completedAt': null,
          }),
        );
        await prefs.setStringList('referrals_${user.uid}', referrals);
      }
    }
    notifyListeners();
  }

  // Email/Password Sign In
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (firebaseUser != null) {
      await _userProvider.loadCurrentUser();
    }
    notifyListeners();
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    bool isNewUser = false;

    if (googleAuth != null) {
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final deviceId = await _getDeviceId();
        final prefs = await SharedPreferences.getInstance();

        // Check device limit
        if (deviceId != null) {
          final existingUserId = prefs.getString('device_$deviceId');
          if (existingUserId != null && existingUserId != user.uid) {
            throw Exception('Only one account can be created per device.');
          }
        }

        // Check if user exists in local storage
        final existingUserData = prefs.getString('user_${user.uid}');
        if (existingUserData == null) {
          isNewUser = true;
          // Create new user
          final newUser = app_models.User(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            referralCode: _generateReferralCode(user.uid),
            coins: 0,
            totalEarned: 0,
            totalWithdrawn: 0,
            activeDays: [],
            lastActiveDate: DateTime.now(),
            dailyStats: {},
          );

          // Save user data
          await _userProvider.saveNewUser(newUser);

          // Save device ID association
          if (deviceId != null) {
            await prefs.setString('device_$deviceId', user.uid);
          }
        } else {
          await _userProvider.loadCurrentUser();
        }
      }
    }
    notifyListeners();
    return isNewUser;
  }

  // Apply referral code
  Future<void> applyReferralCode(String referralCode) async {
    if (referralCode.isEmpty) return;
    final user = firebaseUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();

    // Get all users from local storage to find referrer
    final allUserKeys = prefs.getKeys().where((key) => key.startsWith('user_'));

    String? referrerId;
    app_models.User? referrer;

    for (final key in allUserKeys) {
      final userData = json.decode(prefs.getString(key) ?? '{}');
      if (userData['referralCode'] == referralCode) {
        referrer = app_models.User.fromJson(userData);
        referrerId = referrer.uid;
        break;
      }
    }

    if (referrerId == null || referrer == null) {
      throw Exception("Invalid referral code.");
    }

    if (referrerId == user.uid) {
      throw Exception("Cannot use your own referral code.");
    }

    // Update current user with referral bonus
    final currentAppUser = _userProvider.currentUser;
    if (currentAppUser != null) {
      final updatedUser = currentAppUser.copyWith(
        referredBy: referralCode,
        coins: currentAppUser.coins + 200, // Referee bonus
        totalEarned: currentAppUser.totalEarned + 200,
      );
      await _userProvider.saveNewUser(updatedUser);

      // Save referral relationship
      final referrals = prefs.getStringList('referrals_${user.uid}') ?? [];
      referrals.add(
        jsonEncode({
          'referrerId': referrerId,
          'refereeId': user.uid,
          'refereeActiveDays': 0,
          'referrerRewarded': false,
          'refereeRewarded': true,
          'createdAt': DateTime.now().toIso8601String(),
          'completedAt': null,
        }),
      );
      await prefs.setStringList('referrals_${user.uid}', referrals);
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
