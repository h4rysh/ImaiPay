import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

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

  Stream<UserProfile?> streamProfile(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data()!, doc.id);
    });
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
    await _fetchUserProfile(userCred.user!.uid);
    notifyListeners();
  }

  Future<void> createUserProfile(UserRole role) async {
    if (_user == null) return;
    
    final data = {
      'phoneNumber': _user!.phoneNumber ?? '',
      'role': role == UserRole.guardian ? 'guardian' : 'senior',
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    await _firestore.collection('users').doc(_user!.uid).set(data);
    await _fetchUserProfile(_user!.uid);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
