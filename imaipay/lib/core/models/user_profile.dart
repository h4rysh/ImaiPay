import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { senior, guardian }

class UserProfile {
  final String uid;
  final String phoneNumber;
  final UserRole role;
  final String? linkedGuardianId;
  final List<String> linkedSeniorIds;
  final int escrowDelayMinutes;
  final List<String> trustedContacts;

  UserProfile({
    required this.uid,
    required this.phoneNumber,
    required this.role,
    this.linkedGuardianId,
    this.linkedSeniorIds = const [],
    this.escrowDelayMinutes = 5,
    this.trustedContacts = const [],
  });

  factory UserProfile.fromMap(Map<String, dynamic> data, String documentId) {
    return UserProfile(
      uid: documentId,
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] == 'guardian' ? UserRole.guardian : UserRole.senior,
      linkedGuardianId: data['linkedGuardianId'],
      linkedSeniorIds: List<String>.from(data['linkedSeniorIds'] ?? []),
      escrowDelayMinutes: data['escrowDelayMinutes'] ?? 5,
      trustedContacts: List<String>.from(data['trustedContacts'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'role': role == UserRole.guardian ? 'guardian' : 'senior',
      'linkedGuardianId': linkedGuardianId,
      'linkedSeniorIds': linkedSeniorIds,
      'escrowDelayMinutes': escrowDelayMinutes,
      'trustedContacts': trustedContacts,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
