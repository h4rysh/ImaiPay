import 'package:cloud_functions/cloud_functions.dart';

class PairingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

  Future<Map<String, dynamic>> createPairingSession() async {
    try {
      final callable = _functions.httpsCallable('createPairingSession');
      final result = await callable.call();
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> linkAccounts(String code) async {
    try {
      final callable = _functions.httpsCallable('linkAccounts');
      await callable.call({'code': code});
    } catch (e) {
      print('Pairing link error: $e');
      rethrow;
    }
  }

  Future<void> unlinkFromGuardian() async {
    try {
      final httpsCallable = _functions.httpsCallable('unlinkFromGuardian');
      await httpsCallable.call();
    } catch (e, stack) {
      print('=== UNLINK ERROR DETAILS ===');
      print('Error type: ${e.runtimeType}');
      print('Error: $e');
      print('Stack: $stack');
      print('===========================');
      rethrow;
    }
  }
}
