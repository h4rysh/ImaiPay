import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { senior, guardian }

class UserProfile {
  final String uid;
  final String phoneNumber;
  final UserRole role;
  final double walletBalance;
  final String? linkedGuardianId;
  final List<String> linkedSeniorIds;
  final String? linkingCode;
  final int escrowDelayMinutes;
  final List<String> trustedContacts;

  UserProfile({
    required this.uid,
    required this.phoneNumber,
    required this.role,
    this.walletBalance = 0.0,
    this.linkedGuardianId,
    this.linkedSeniorIds = const [],
    this.linkingCode,
    this.escrowDelayMinutes = 5,
    this.trustedContacts = const [],
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String documentId) {
    return UserProfile(
      uid: documentId,
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] == 'guardian' ? UserRole.guardian : UserRole.senior,
      walletBalance: (data['walletBalance'] ?? 0.0).toDouble(),
      linkedGuardianId: data['linkedGuardianId'],
      linkedSeniorIds: List<String>.from(data['linkedSeniorIds'] ?? []),
      linkingCode: data['linkingCode'],
      escrowDelayMinutes: data['escrowDelayMinutes'] ?? 5,
      trustedContacts: List<String>.from(data['trustedContacts'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'role': role == UserRole.guardian ? 'guardian' : 'senior',
      'walletBalance': walletBalance,
      'linkedGuardianId': linkedGuardianId,
      'linkedSeniorIds': linkedSeniorIds,
      'linkingCode': linkingCode,
      'escrowDelayMinutes': escrowDelayMinutes,
      'trustedContacts': trustedContacts,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
