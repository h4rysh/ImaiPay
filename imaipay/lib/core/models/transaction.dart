import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionStatus {
  CREATED,
  RISK_EVALUATED,
  ESCROWED,
  REVIEW_REQUIRED,
  APPROVED,
  DENIED,
  CANCELLED,
  SETTLED,
  FAILED,
}

enum RiskLevel { LOW, MEDIUM, HIGH, CRITICAL }

class TransactionModel {
  final String id;
  final String requestId;
  final String senderId;
  final String recipientName;
  final String recipientPhone;
  final int amountPaise;
  final String currency;
  final TransactionStatus status;
  final RiskLevel? riskLevel;
  final List<String> riskReasons;
  final String? guardianId;
  final DateTime? escrowExpiresAt;
  final int holdDurationMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? deniedBy;
  final DateTime? deniedAt;
  final DateTime? cancelledAt;
  final DateTime? settledAt;
  final DateTime? refundedAt;

  TransactionModel({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.recipientName,
    required this.recipientPhone,
    required this.amountPaise,
    required this.currency,
    required this.status,
    this.riskLevel,
    required this.riskReasons,
    this.guardianId,
    this.escrowExpiresAt,
    required this.holdDurationMinutes,
    this.createdAt,
    this.updatedAt,
    this.approvedBy,
    this.approvedAt,
    this.deniedBy,
    this.deniedAt,
    this.cancelledAt,
    this.settledAt,
    this.refundedAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    TransactionStatus parsedStatus = TransactionStatus.CREATED;
    try {
      parsedStatus = TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.CREATED,
      );
    } catch (_) {}

    RiskLevel? parsedRisk;
    if (data['riskLevel'] != null) {
      try {
        parsedRisk = RiskLevel.values.firstWhere((e) => e.name == data['riskLevel']);
      } catch (_) {}
    }

    return TransactionModel(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      senderId: data['senderId'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientPhone: data['recipientPhone'] ?? '',
      amountPaise: data['amountPaise'] ?? 0,
      currency: data['currency'] ?? 'INR',
      status: parsedStatus,
      riskLevel: parsedRisk,
      riskReasons: List<String>.from(data['riskReasons'] ?? []),
      guardianId: data['guardianId'],
      escrowExpiresAt: (data['escrowExpiresAt'] as Timestamp?)?.toDate(),
      holdDurationMinutes: data['holdDurationMinutes'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      approvedBy: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      deniedBy: data['deniedBy'],
      deniedAt: (data['deniedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      settledAt: (data['settledAt'] as Timestamp?)?.toDate(),
      refundedAt: (data['refundedAt'] as Timestamp?)?.toDate(),
    );
  }
}
