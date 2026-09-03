import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';

class GuardianDashboard extends StatefulWidget {
  const GuardianDashboard({super.key});

  @override
  State<GuardianDashboard> createState() => _GuardianDashboardState();
}

class _GuardianDashboardState extends State<GuardianDashboard> {
  bool _isProcessing = false;

  Future<void> _authenticateAndApprove(String docId) async {
    final auth = LocalAuthentication();
    bool didAuthenticate = false;

    try {
      didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to approve this transfer',
        biometricOnly: true,
      );
    } catch (e) {
      if (!mounted) return;
      // Fallback dialog for devices or simulators without biometrics enrolled
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_open_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Confirm Approval'),
            ],
          ),
          content: const Text(
            'Biometric authentication is not configured on this device. Do you want to authorize this transfer manually?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve Transfer'),
            ),
          ],
        ),
      );
      didAuthenticate = confirmed == true;
    }

    if (!mounted) return;

    if (didAuthenticate) {
      setState(() => _isProcessing = true);
      try {
        final guardianUid = context.read<AuthProvider>().user?.uid;
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(docId)
            .update({
          'status': 'in_escrow',
          'approvedBy': guardianUid,
          'approvedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Transfer approved! Funds moved to protected escrow.'),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } catch (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update transfer: $err'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication was not completed. Transfer not approved.'),
        ),
      );
    }
  }

  Future<void> _denyTransfer(String docId, String receiverName, double amount) async {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Deny Transfer?'),
          ],
        ),
        content: Text(
          'Are you sure you want to deny this ${currencyFormatter.format(amount)} transfer to $receiverName? The transfer will be cancelled immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Deny Transfer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        final guardianUid = context.read<AuthProvider>().user?.uid;
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(docId)
            .update({
          'status': 'cancelled',
          'deniedBy': guardianUid,
          'deniedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 8),
                Text('Transfer denied and cancelled.'),
              ],
            ),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      } catch (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deny transfer: $err'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current user's UID from AuthProvider
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Guardian Dashboard',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('status', isEqualTo: 'pending_guardian')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Guardian Shield Hero Banner
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Color(0xFF10B981),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Guardian Protection Active',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUid.isNotEmpty
                                ? 'Monitoring transfers for suspicious behavior'
                                : 'Protecting senior transfers',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Section Header with count badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Pending Approvals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: docs.isNotEmpty
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          docs.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Empty State
              if (docs.isEmpty)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            size: 48,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'All Caught Up!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No pending transfers require your review right now. Flagged transfers will appear here immediately.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: docs.map((doc) {
                    final txData = doc.data() as Map<String, dynamic>;
                    final amount = (txData['amount'] is num)
                        ? (txData['amount'] as num).toDouble()
                        : 0.0;
                    final receiverName =
                        txData['receiverName']?.toString() ?? 'Recipient';
                    final flaggedReason = txData['flaggedReason']?.toString();
                    final isActiveCall = flaggedReason == 'active_call';
                    final createdAt = (txData['createdAt'] as Timestamp?)?.toDate();
                    final dateStr = createdAt != null
                        ? DateFormat('MMM d, yyyy • h:mm a').format(createdAt)
                        : 'Just now';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isActiveCall
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFFDE68A),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isActiveCall
                                    ? Colors.red
                                    : Colors.orange)
                                .withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Flagged Warning Banner
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isActiveCall
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isActiveCall
                                        ? Icons.phone_in_talk_rounded
                                        : Icons.warning_amber_rounded,
                                    size: 20,
                                    color: isActiveCall
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isActiveCall
                                          ? 'FLAGGED: Active Phone Call Detected'
                                          : 'FLAGGED: High Value Transfer',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isActiveCall
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Transfer Details
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attempted transfer to',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        receiverName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(amount),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            // Advisory notice
                            Text(
                              isActiveCall
                                  ? 'The user attempted this payment while currently speaking on the phone. Scammers frequently keep seniors on the phone to rush them into fraudulent payments.'
                                  : 'This transfer amount exceeds the normal threshold. Please verify before approving.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 22),
                            // Action Buttons: Deny & Approve
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isProcessing
                                        ? null
                                        : () => _denyTransfer(
                                              doc.id,
                                              receiverName,
                                              amount,
                                            ),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Deny',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(
                                        color: Color(0xFFFCA5A5),
                                        width: 1.5,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isProcessing
                                        ? null
                                        : () => _authenticateAndApprove(doc.id),
                                    icon: const Icon(
                                      Icons.fingerprint_rounded,
                                      size: 22,
                                    ),
                                    label: const Text(
                                      'Approve',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}

typedef GuardianDashboardScreen = GuardianDashboard;
typedef GuardianHomeScreen = GuardianDashboard;
