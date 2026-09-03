import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import 'dart:math';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = true;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _userProfile != null;

  AuthProvider() {
    _auth.authStateChanges().listen((user) async {
      _user = user;
      try {
        if (user != null) {
          await _fetchUserProfile(user.uid);
        } else {
          _userProfile = null;
        }
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
        _userProfile = null;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> fetchProfileAgain() async {
    if (_user != null) {
      await _fetchUserProfile(_user!.uid);
      notifyListeners();
    }
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = UserProfile.fromMap(doc.data()!, doc.id);
      } else {
        _userProfile = null;
      }
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
      _userProfile = null;
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<bool> signInWithSmsCode(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _signInWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    final userCred = await _auth.signInWithCredential(credential);
    // If it's a new user, they need to create a profile (handled separately)
    await _fetchUserProfile(userCred.user!.uid);
    notifyListeners();
  }

  Future<void> createUserProfile(UserRole role) async {
    if (_user == null) return;
    
    _userProfile = UserProfile(
      uid: _user!.uid,
      phoneNumber: _user!.phoneNumber ?? '',
      role: role,
      walletBalance: role == UserRole.senior ? 500.0 : 0.0, // Give seniors some starting money for testing
    );
    
    await _firestore.collection('users').doc(_user!.uid).set(_userProfile!.toMap());
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Linking logic
  Future<String> generateLinkingCode() async {
    if (_userProfile == null || _userProfile!.role != UserRole.senior) return '';
    
    final code = (100000 + Random().nextInt(900000)).toString(); // 6 digit code
    await _firestore.collection('users').doc(_user!.uid).update({
      'linkingCode': code,
    });
    
    _userProfile = UserProfile(
      uid: _userProfile!.uid,
      phoneNumber: _userProfile!.phoneNumber,
      role: _userProfile!.role,
      walletBalance: _userProfile!.walletBalance,
      linkedGuardianId: _userProfile!.linkedGuardianId,
      linkingCode: code,
    );
    notifyListeners();
    return code;
  }

  Future<void> skipLinkingForDemo() async {
    if (_user == null || _userProfile == null) return;
    await _firestore.collection('users').doc(_user!.uid).update({
      'linkedGuardianId': 'demo_guardian_1',
    });
    await _fetchUserProfile(_user!.uid);
    notifyListeners();
  }

  Future<bool> linkWithCode(String code) async {
    if (_userProfile == null || _userProfile!.role != UserRole.guardian) return false;
    
    // Find the senior with this code
    final snapshot = await _firestore
        .collection('users')
        .where('linkingCode', isEqualTo: code)
        .limit(1)
        .get();
        
    if (snapshot.docs.isEmpty) return false;
    
    final seniorDoc = snapshot.docs.first;
    
    // Link them together
    await _firestore.collection('users').doc(seniorDoc.id).update({
      'linkedGuardianId': _user!.uid,
      'linkingCode': null, // Clear it after use
    });
    
    return true;
  }
}
