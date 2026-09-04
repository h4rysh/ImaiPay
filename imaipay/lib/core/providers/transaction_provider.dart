import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';

class TransactionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TransactionModel>> streamTransactionsForSenior(String seniorId) {
    if (seniorId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('transactions')
        .where('senderId', isEqualTo: seniorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TransactionModel>> streamTransactionsForGuardian(String guardianId) {
    if (guardianId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('transactions')
        .where('guardianId', isEqualTo: guardianId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }
}
