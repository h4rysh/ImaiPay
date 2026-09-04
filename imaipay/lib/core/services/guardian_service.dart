import 'package:cloud_functions/cloud_functions.dart';

class GuardianService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

  Future<void> approveTransfer(String transactionId) async {
    try {
      final callable = _functions.httpsCallable('approveTransfer');
      await callable.call({'transactionId': transactionId});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> denyTransfer(String transactionId) async {
    try {
      final callable = _functions.httpsCallable('denyTransfer');
      await callable.call({'transactionId': transactionId});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> modifyTrustedContacts({
    required String seniorId,
    required String phone,
    required bool add,
  }) async {
    try {
      final callable = _functions.httpsCallable('modifyTrustedContacts');
      await callable.call({
        'seniorId': seniorId,
        'phone': phone,
        'action': add ? 'add' : 'remove',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateEscrowDelay({
    required String seniorId,
    required int minutes,
  }) async {
    try {
      final callable = _functions.httpsCallable('updateEscrowDelay');
      await callable.call({
        'seniorId': seniorId,
        'minutes': minutes,
      });
    } catch (e) {
      rethrow;
    }
  }
}
