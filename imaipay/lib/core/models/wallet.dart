import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String uid;
  final int availableBalancePaise;
  final int heldBalancePaise;
  final int totalBalancePaise;
  final String currency;
  final DateTime? updatedAt;
  final int version;

  Wallet({
    required this.uid,
    required this.availableBalancePaise,
    required this.heldBalancePaise,
    required this.totalBalancePaise,
    required this.currency,
    this.updatedAt,
    required this.version,
  });

  factory Wallet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Wallet(
      uid: doc.id,
      availableBalancePaise: data['availableBalancePaise'] ?? 0,
      heldBalancePaise: data['heldBalancePaise'] ?? 0,
      totalBalancePaise: data['totalBalancePaise'] ?? 0,
      currency: data['currency'] ?? 'INR',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      version: data['version'] ?? 1,
    );
  }
}
