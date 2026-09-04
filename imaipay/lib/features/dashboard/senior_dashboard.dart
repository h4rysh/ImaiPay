import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/wallet.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/services/transfer_service.dart';
import '../../core/services/pairing_service.dart';
import '../../core/models/money.dart';
import '../../payment_flow.dart';

class SeniorDashboard extends StatelessWidget {
  const SeniorDashboard({super.key});

  void _showPairingCodeDialog(BuildContext context) async {
    String code = '...';

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>>(
          future: PairingService().createPairingSession(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                content: Text('Failed to generate code: ${snapshot.error}'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
              );
            }

            code = snapshot.data?['code'] ?? 'ERROR';

            return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: Color(0xFF4338CA), size: 32),
            SizedBox(width: 12),
            Text('Pair with Caretaker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Show this 6-digit code to your Caretaker to enter on their phone:',
              style: TextStyle(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6366F1), width: 2),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Color(0xFF4338CA),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Once entered on their phone, your accounts will be securely linked.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4338CA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Done', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
          },
        );
      },
    );
  }

  void _showSafetyTipsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF4338CA), size: 36),
                SizedBox(width: 12),
                Text(
                  'Safety & Scam Tips',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep your money safe with these essential rules:',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            _buildTipCard(
              icon: Icons.people_outline,
              iconColor: const Color(0xFFEA580C),
              title: 'The Grandparent Scam',
              description:
                  'A caller pretends to be your grandchild in urgent distress needing money. Always hang up and call them directly on their known phone number.',
            ),
            const SizedBox(height: 16),
            _buildTipCard(
              icon: Icons.account_balance_outlined,
              iconColor: const Color(0xFFDC2626),
              title: 'Fake Government & IRS Calls',
              description:
                  'Scammers claim you owe back-taxes and threaten police action. Legitimate authorities will NEVER demand immediate payment over the phone.',
            ),
            const SizedBox(height: 16),
            _buildTipCard(
              icon: Icons.computer_outlined,
              iconColor: const Color(0xFF2563EB),
              title: 'Tech Support Scam',
              description:
                  'Popups or callers claiming your device is infected. Never give anyone remote access to your phone or computer, and never transfer money.',
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF4338CA), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Remember: With ImaiPay, your money is held in escrow so you can cancel accidental or pressured transfers anytime.',
                      style: TextStyle(fontSize: 16, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildTipCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, AuthProvider authProvider, UserProfile? profile) {
    final hasGuardian = profile?.linkedGuardianId != null && profile!.linkedGuardianId!.isNotEmpty;
    final escrowMinutes = profile?.escrowDelayMinutes ?? 5;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timer_outlined, color: Color(0xFF4338CA), size: 28),
              title: const Text('Escrow Delay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('$escrowMinutes minutes to cancel transfers', style: const TextStyle(fontSize: 15)),
            ),
            const Divider(),
            if (hasGuardian) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_off, color: Colors.red, size: 28),
                title: const Text('Unlink Caretaker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                subtitle: const Text('Disconnect from your guardian', style: TextStyle(fontSize: 15)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await PairingService().unlinkFromGuardian();
                    if (context.mounted) {
                      await authProvider.fetchProfileAgain();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      if (e.toString().contains('1 out of 2 underlying tasks failed')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Auth session expired. Please sign in again.')),
                        );
                        authProvider.signOut();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to unlink: $e')),
                        );
                      }
                    }
                  }
                },
              ),
              const Divider(),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: Colors.black87, size: 28),
              title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: const Text('Log out of this phone', style: TextStyle(fontSize: 15)),
              onTap: () {
                Navigator.pop(ctx);
                authProvider.signOut();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    final uid = authProvider.user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'ImaiPay',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          StreamBuilder<UserProfile?>(
            stream: uid.isNotEmpty ? authProvider.streamProfile(uid) : const Stream.empty(),
            builder: (context, snapshot) {
              return IconButton(
                icon: const Icon(Icons.settings_outlined, size: 30, color: Color(0xFF0F172A)),
                tooltip: 'Settings',
                onPressed: () => _showSettingsDialog(context, authProvider, snapshot.data),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSafetyTipsBottomSheet(context),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.lightbulb_rounded, size: 28, color: Color(0xFFFBBF24)),
        label: const Text(
          'Safety & Scam Tips',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: uid.isNotEmpty
            ? authProvider.streamProfile(uid)
            : const Stream.empty(),
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data;
          final escrowDelayMinutes = profile?.escrowDelayMinutes ?? 5;
          final hasGuardian = profile?.linkedGuardianId != null && profile!.linkedGuardianId!.isNotEmpty;

          return StreamBuilder<Wallet?>(
            stream: uid.isNotEmpty
                ? walletProvider.streamWallet(uid)
                : const Stream.empty(),
            builder: (context, walletSnapshot) {
              if (walletSnapshot.hasError) {
                return Center(child: Text('Wallet Error: ${walletSnapshot.error}'));
              }
              final wallet = walletSnapshot.data;
              final formattedBalance = wallet != null
                  ? Money(paise: wallet.availableBalancePaise).formatted
                  : Money(paise: 0).formatted;

              return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              Text(
                'Welcome,',
                style: TextStyle(
                  fontSize: 24,
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
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Caretaker Status Badge
              if (hasGuardian)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF22C55E)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Color(0xFF15803D), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Protected by Caretaker',
                          style: TextStyle(
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => _showPairingCodeDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF59E0B)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_rounded, color: Color(0xFFB45309), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Pair with Caretaker (Show Code)',
                            style: TextStyle(
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios, color: Color(0xFFB45309), size: 14),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 28),

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
                padding: const EdgeInsets.all(32),
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
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'MY MONEY',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                                letterSpacing: 1.5,
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
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (uid.isNotEmpty) {
                          await walletProvider.addDemoFunds(10000);
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
                height: 100,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentFlowScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 48),
                  label: const Text(
                    'SEND MONEY',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),

              if (uid.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                StreamBuilder<List<TransactionModel>>(
                  stream: context.read<TransactionProvider>().streamTransactionsForSenior(uid),
                  builder: (context, txSnapshot) {
                    if (txSnapshot.connectionState == ConnectionState.waiting &&
                        !txSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (txSnapshot.hasError) {
                      return Text('Error: ${txSnapshot.error}', style: const TextStyle(fontSize: 20, color: Colors.red));
                    }

                    final transactions = txSnapshot.data ?? [];

                    if (transactions.isEmpty) {
                      return const Text(
                        'No transactions yet.',
                        style: TextStyle(fontSize: 24, color: Colors.grey),
                      );
                    }

                    return Column(
                      children: transactions.map((tx) {
                        final formattedAmount = Money(paise: tx.amountPaise).formatted;
                        final receiverName = tx.recipientName;
                        final status = tx.status.name;
                        final createdAt = tx.createdAt;
                        
                        final isPending = tx.status == TransactionStatus.ESCROWED || tx.status == TransactionStatus.REVIEW_REQUIRED;
                        
                        // Check if within escrow delay
                        bool isWithinDelay = false;
                        if (isPending) {
                          if (createdAt == null) {
                            isWithinDelay = true;
                          } else {
                            final diff = DateTime.now().difference(createdAt).inMinutes;
                            if (diff < escrowDelayMinutes) {
                              isWithinDelay = true;
                            }
                          }
                        }

                        // If pending and within delay, show the big Escrow Undo card
                        if (isPending && isWithinDelay) {
                          return _buildEscrowUndoCard(
                            context: context,
                            uid: uid,
                            txId: tx.id,
                            receiverName: receiverName,
                            formattedAmount: formattedAmount,
                          );
                        }

                        // Otherwise show normal history card
                        final dateStr = createdAt != null
                            ? DateFormat('MMM d, yyyy • h:mm a').format(createdAt)
                            : 'Just now';

                        return _buildNormalTransactionCard(
                          receiverName: receiverName,
                          formattedAmount: formattedAmount,
                          status: status,
                          dateStr: dateStr,
                        );
                      }).toList(),
                    );
                  },
                ),
              const SizedBox(height: 80), // Extra space for FAB
            ],
          );
        },
      );
    },
  ),
);
  }

  Widget _buildEscrowUndoCard({
    required BuildContext context,
    required String uid,
    required String txId,
    required String receiverName,
    required String formattedAmount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Amount: $formattedAmount',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 70,
            child: ElevatedButton.icon(
              onPressed: () => _cancelAndRefund(context, uid, txId),
              icon: const Icon(Icons.cancel_outlined, size: 32),
              label: const Text(
                'CANCEL TRANSFER',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalTransactionCard({
    required String receiverName,
    required String formattedAmount,
    required String status,
    required String dateStr,
  }) {
    Color statusColor = Colors.grey;
    if (status == 'SETTLED' || status == 'completed' || status == 'APPROVED') statusColor = Colors.green;
    if (status == 'CANCELLED' || status == 'cancelled' || status == 'DENIED' || status == 'FAILED') statusColor = Colors.red;
    if (status == 'REVIEW_REQUIRED' || status == 'flagged' || status == 'ESCROWED') statusColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade100,
            child: const Icon(Icons.person, color: Colors.grey, size: 32),
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
                  style: TextStyle(fontSize: 16, color: statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            '-$formattedAmount',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAndRefund(BuildContext context, String uid, String txId) async {
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
      try {
        await TransferService().cancelTransfer(txId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transfer cancelled and money refunded.', style: TextStyle(fontSize: 20)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel transfer: $e', style: const TextStyle(fontSize: 20)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

typedef SeniorDashboardScreen = SeniorDashboard;
typedef SeniorHomeScreen = SeniorDashboard;
