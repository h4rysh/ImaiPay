import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class WalletProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserProfile?> streamProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> addFunds(String uid, double amount) async {
    await _firestore.collection('users').doc(uid).update({
      'walletBalance': FieldValue.increment(amount),
    });
  }
}
