import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { senior, guardian }

class UserProfile {
  final String uid;
  final String phoneNumber;
  final UserRole role;
  final double walletBalance;
  final String? linkedGuardianId;
  final String? linkingCode;

  UserProfile({
    required this.uid,
    required this.phoneNumber,
    required this.role,
    this.walletBalance = 0.0,
    this.linkedGuardianId,
    this.linkingCode,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String documentId) {
    return UserProfile(
      uid: documentId,
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] == 'guardian' ? UserRole.guardian : UserRole.senior,
      walletBalance: (data['walletBalance'] ?? 0.0).toDouble(),
      linkedGuardianId: data['linkedGuardianId'],
      linkingCode: data['linkingCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'role': role == UserRole.guardian ? 'guardian' : 'senior',
      'walletBalance': walletBalance,
      'linkedGuardianId': linkedGuardianId,
      'linkingCode': linkingCode,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
