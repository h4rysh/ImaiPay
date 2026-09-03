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
          'ImaiPay Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: uid.isNotEmpty
            ? walletProvider.streamProfile(uid)
            : const Stream.empty(),
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data;
          final balance = profile?.walletBalance ?? 0.0;
          final formattedBalance = currencyFormatter.format(balance);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Greeting Section
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 16,
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
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),

              // Big Balance Card
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'CURRENT BALANCE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        // Add Funds Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (uid.isNotEmpty) {
                              await walletProvider.addFunds(uid, 100.0);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added \$100.00 to your wallet!'),
                                    backgroundColor: Color(0xFF10B981),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'Add Funds',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4338CA),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      formattedBalance,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Protected by ImaiPay Guardian Escrow',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Big "Send Money" Button
              SizedBox(
                width: double.infinity,
                height: 68,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentFlowScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 28),
                  label: const Text(
                    'Send Money',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                    shadowColor: Colors.black26,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Recent Transactions Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Icon(Icons.history_rounded, color: Colors.grey.shade600),
                ],
              ),
              const SizedBox(height: 14),

              // Firestore Transactions where senderId == uid
              if (uid.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('senderId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, txSnapshot) {
                    if (txSnapshot.connectionState == ConnectionState.waiting &&
                        !txSnapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (txSnapshot.hasError) {
                      return Card(
                        color: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error loading transactions: ${txSnapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final docs = txSnapshot.data?.docs.toList() ?? [];

                    // Sort descending by createdAt in Dart to avoid missing composite indexes
                    docs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aTs = aData['createdAt'] as Timestamp?;
                      final bTs = bData['createdAt'] as Timestamp?;
                      if (aTs == null && bTs == null) return 0;
                      if (aTs == null) return -1;
                      if (bTs == null) return 1;
                      return bTs.compareTo(aTs);
                    });

                    if (docs.isEmpty) {
                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 36,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 40,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Your money transfers and security statuses will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final txData = doc.data() as Map<String, dynamic>;
                        final amount = (txData['amount'] is num)
                            ? (txData['amount'] as num).toDouble()
                            : 0.0;
                        final receiverName =
                            txData['receiverName']?.toString() ?? 'Recipient';
                        final status = txData['status']?.toString() ?? 'unknown';
                        final flaggedReason = txData['flaggedReason']?.toString();
                        final createdAt = (txData['createdAt'] as Timestamp?)?.toDate();
                        final dateStr = createdAt != null
                            ? DateFormat('MMM d, yyyy • h:mm a').format(createdAt)
                            : 'Just now';

                        return _buildTransactionCard(
                          context: context,
                          docId: doc.id,
                          receiverName: receiverName,
                          amount: amount,
                          status: status,
                          flaggedReason: flaggedReason,
                          dateStr: dateStr,
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

  Widget _buildTransactionCard({
    required BuildContext context,
    required String docId,
    required String receiverName,
    required double amount,
    required String status,
    required String? flaggedReason,
    required String dateStr,
  }) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isPendingGuardian = status == 'pending_guardian';
    final isInEscrow = status == 'in_escrow';
    final isCancelled = status == 'cancelled';
    final isCompleted = status == 'completed';

    Color statusColor;
    Color statusBgColor;
    String statusLabel;
    IconData statusIcon;

    if (isPendingGuardian) {
      statusColor = const Color(0xFFD97706);
      statusBgColor = const Color(0xFFFEF3C7);
      statusLabel = 'Awaiting Guardian';
      statusIcon = Icons.pause_circle_filled_rounded;
    } else if (isInEscrow) {
      statusColor = const Color(0xFF2563EB);
      statusBgColor = const Color(0xFFDBEAFE);
      statusLabel = 'In Escrow';
      statusIcon = Icons.lock_clock_rounded;
    } else if (isCompleted) {
      statusColor = const Color(0xFF16A34A);
      statusBgColor = const Color(0xFFDCFCE7);
      statusLabel = 'Completed';
      statusIcon = Icons.check_circle_rounded;
    } else if (isCancelled) {
      statusColor = const Color(0xFFDC2626);
      statusBgColor = const Color(0xFFFEE2E2);
      statusLabel = 'Cancelled';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = const Color(0xFF64748B);
      statusBgColor = const Color(0xFFF1F5F9);
      statusLabel = status;
      statusIcon = Icons.info_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPendingGuardian
              ? const Color(0xFFFDE68A)
              : isInEscrow
                  ? const Color(0xFFBFDBFE)
                  : Colors.grey.shade200,
          width: isPendingGuardian || isInEscrow ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar / Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 26),
                ),
                const SizedBox(width: 14),
                // Recipient & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receiverName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '-${currencyFormatter.format(amount)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status and Flagged Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (flaggedReason != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Color(0xFFEA580C),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          flaggedReason == 'active_call'
                              ? 'Active Call'
                              : 'High Value',
                          style: const TextStyle(
                            color: Color(0xFFEA580C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            // If the transfer is still active (in_escrow or pending_guardian), allow cancellation
            if (isPendingGuardian || isInEscrow) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isPendingGuardian
                        ? 'Guardian approval required'
                        : 'Held in protective escrow',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmAndCancel(context, docId),
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                    label: const Text(
                      'Cancel Transfer',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndCancel(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Transfer?'),
        content: const Text(
          'Are you sure you want to cancel this transfer? The transaction will be stopped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Keep Transfer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yes, Cancel'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer has been cancelled.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

typedef SeniorDashboardScreen = SeniorDashboard;
typedef SeniorHomeScreen = SeniorDashboard;
