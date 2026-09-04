import 'package:cloud_functions/cloud_functions.dart';
import '../models/transaction.dart';

class TransferService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

  Future<Map<String, dynamic>> createTransfer({
    required String requestId,
    required String recipientName,
    required String recipientPhone,
    required int amountPaise,
  }) async {
    try {
      final callable = _functions.httpsCallable('createTransfer');
      final result = await callable.call({
        'requestId': requestId,
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'amountPaise': amountPaise,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelTransfer(String transactionId) async {
    try {
      final callable = _functions.httpsCallable('cancelTransfer');
      await callable.call({'transactionId': transactionId});
    } catch (e) {
      rethrow;
    }
  }
}
