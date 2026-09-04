import 'package:flutter_test/flutter_test.dart';
import 'package:imaipay/core/models/wallet.dart';

void main() {
  group('Wallet Model Tests', () {
    test('totalBalancePaise is computed correctly', () {
      final wallet = Wallet(
        uid: 'test_uid',
        availableBalancePaise: 5000,
        heldBalancePaise: 2500,
        currency: 'INR',
        version: 1,
      );

      expect(wallet.totalBalancePaise, 7500);
      expect(wallet.uid, 'test_uid');
      expect(wallet.currency, 'INR');
    });

    test('Zero balances are handled correctly', () {
      final wallet = Wallet(
        uid: 'test_uid',
        availableBalancePaise: 0,
        heldBalancePaise: 0,
        currency: 'INR',
        version: 1,
      );

      expect(wallet.totalBalancePaise, 0);
    });
  });
}
