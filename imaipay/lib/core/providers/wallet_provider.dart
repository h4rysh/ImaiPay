import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();
  
  Stream<Wallet?> streamWallet(String uid) {
    return _walletService.streamWallet(uid);
  }

  Future<void> addDemoFunds(int amountPaise) async {
    await _walletService.addDemoFunds(amountPaise);
  }
}
