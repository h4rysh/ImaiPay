import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/wallet.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

  Stream<Wallet?> streamWallet(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _firestore.collection('wallets').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Wallet.fromFirestore(doc);
    });
  }

  Future<void> addDemoFunds(int amountPaise) async {
    try {
      final callable = _functions.httpsCallable('addDemoFunds');
      await callable.call({'amountPaise': amountPaise});
    } catch (e) {
      rethrow;
    }
  }
}
