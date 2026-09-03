import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/models/user_profile.dart';
import '../../payment_flow.dart';

class SeniorDashboard extends StatelessWidget {
  const SeniorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    final uid = authProvider.user?.uid ?? '';
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'ImaiPay',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32, // Massive typography
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<UserProfile?>(
        stream: uid.isNotEmpty
            ? walletProvider.streamProfile(uid)
            : const Stream.empty(),
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data;
          final balance = profile?.walletBalance ?? 0.0;
          final formattedBalance = currencyFormatter.format(balance);
          final escrowDelayMinutes = profile?.escrowDelayMinutes ?? 5;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              Text(
                'Welcome,',
                style: TextStyle(
                  fontSize: 24, // Massive typography
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile?.phoneNumber.isNotEmpty == true
                    ? profile!.phoneNumber
                    : 'Senior Account',
                style: const TextStyle(
                  fontSize: 36, // Massive typography
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 30),

              // Big Balance Card ("My Money")
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF818CF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32), // More padding for massive feel
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 32, // Massive icon
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'MY MONEY',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 20, // Massive typography
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      formattedBalance,
                      style: const TextStyle(
                        fontSize: 56, // Massive typography
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (uid.isNotEmpty) {
                          await walletProvider.addFunds(uid, 100.0);
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 24),
                      label: const Text(
                        'Add Funds',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4338CA),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Big "Send Money" Button
              SizedBox(
                width: double.infinity,
                height: 100, // Massive height
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentFlowScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 48), // Massive icon
                  label: const Text(
                    'SEND MONEY',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold), // Massive font
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black26,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Escrow Undo Section
              const Text(
                'Recent Transfers',
                style: TextStyle(
                  fontSize: 28, // Massive font
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),

              if (uid.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('senderId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, txSnapshot) {
                    if (txSnapshot.connectionState == ConnectionState.waiting &&
                        !txSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (txSnapshot.hasError) {
                      return Text('Error: ${txSnapshot.error}', style: const TextStyle(fontSize: 20, color: Colors.red));
                    }

                    final docs = txSnapshot.data?.docs.toList() ?? [];

                    docs.sort((a, b) {
                      final aTs = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      final bTs = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      if (aTs == null && bTs == null) return 0;
                      if (aTs == null) return -1;
                      if (bTs == null) return 1;
                      return bTs.compareTo(aTs);
                    });

                    if (docs.isEmpty) {
                      return const Text(
                        'No transactions yet.',
                        style: TextStyle(fontSize: 24, color: Colors.grey),
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final txData = doc.data() as Map<String, dynamic>;
                        final amount = (txData['amount'] is num)
                            ? (txData['amount'] as num).toDouble()
                            : 0.0;
                        final receiverName = txData['receiverName']?.toString() ?? 'Recipient';
                        final status = txData['status']?.toString() ?? 'unknown';
                        final createdAt = (txData['createdAt'] as Timestamp?)?.toDate();
                        
                        final isPending = status == 'pending' || status == 'escrow' || status == 'in_escrow' || status == 'pending_guardian';
                        
                        // Check if within escrow delay
                        bool isWithinDelay = false;
                        if (isPending && createdAt != null) {
                          final diff = DateTime.now().difference(createdAt).inMinutes;
                          if (diff < escrowDelayMinutes) {
                            isWithinDelay = true;
                          }
                        }

                        // If pending and within delay, show the big Escrow Undo card
                        if (isPending && isWithinDelay) {
                          return _buildEscrowUndoCard(
                            context: context,
                            uid: uid,
                            docId: doc.id,
                            receiverName: receiverName,
                            amount: amount,
                          );
                        }

                        // Otherwise show normal history card
                        final dateStr = createdAt != null
                            ? DateFormat('MMM d, yyyy • h:mm a').format(createdAt)
                            : 'Just now';

                        return _buildNormalTransactionCard(
                          receiverName: receiverName,
                          amount: amount,
                          status: status,
                          dateStr: dateStr,
                          currencyFormatter: currencyFormatter,
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEscrowUndoCard({
    required BuildContext context,
    required String uid,
    required String docId,
    required String receiverName,
    required double amount,
  }) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Light red bg
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.red),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Transfer to $receiverName is on hold',
                  style: const TextStyle(
                    fontSize: 24, // Massive font
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Amount: ${currencyFormatter.format(amount)}',
            style: const TextStyle(
              fontSize: 28, // Massive font
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 80, // Massive button
            child: ElevatedButton.icon(
              onPressed: () => _cancelAndRefund(context, uid, docId, amount),
              icon: const Icon(Icons.cancel_rounded, size: 36),
              label: const Text(
                'CANCEL TRANSFER',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalTransactionCard({
    required String receiverName,
    required double amount,
    required String status,
    required String dateStr,
    required NumberFormat currencyFormatter,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person, size: 32, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiverName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: $status',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          Text(
            '-${currencyFormatter.format(amount)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAndRefund(BuildContext context, String uid, String docId, double amount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Transfer?', style: TextStyle(fontSize: 28)),
        content: const Text(
          'Are you sure you want to stop this transfer and get your money back?',
          style: TextStyle(fontSize: 22),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('No, keep it', style: TextStyle(fontSize: 22)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel', style: TextStyle(fontSize: 22)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(docId)
          .update({'status': 'cancelled'});
          
      if (context.mounted) {
        await context.read<WalletProvider>().addFunds(uid, amount);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transfer cancelled and money refunded.', style: TextStyle(fontSize: 20)),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }
}

typedef SeniorDashboardScreen = SeniorDashboard;
typedef SeniorHomeScreen = SeniorDashboard;
