import 'package:cloud_functions/cloud_functions.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/wallet.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/transaction_provider.dart';
import '../../core/services/guardian_service.dart';
import '../../core/models/money.dart';
import '../../core/providers/auth_provider.dart';
import '../auth/guardian_linking_screen.dart';

class GuardianDashboard extends StatefulWidget {
  const GuardianDashboard({super.key});

  @override
  State<GuardianDashboard> createState() => _GuardianDashboardState();
}

class _GuardianDashboardState extends State<GuardianDashboard> {
  bool _isProcessing = false;
  StreamSubscription? _flaggedTxSub;
  final Set<String> _knownFlaggedTxIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToFlaggedTransactions();
    });
  }

  void _listenToFlaggedTransactions() {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    _flaggedTxSub = context
        .read<TransactionProvider>()
        .streamTransactionsForGuardian(uid)
        .listen((transactions) {
      for (final tx in transactions) {
        if (tx.status == TransactionStatus.REVIEW_REQUIRED) {
          if (!_knownFlaggedTxIds.contains(tx.id)) {
            _knownFlaggedTxIds.add(tx.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Action Required: Suspicious Transfer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.redAccent,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          }
        } else {
          _knownFlaggedTxIds.remove(tx.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _flaggedTxSub?.cancel();
    super.dispose();
  }

  Future<void> _authenticateAndApprove(String txId) async {
    final auth = LocalAuthentication();
    bool didAuthenticate = false;

    try {
      didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to approve this transfer',
        biometricOnly: true,
      );
    } catch (e) {
      if (!mounted) return;
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
        await GuardianService().approveTransfer(txId);

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
            content: Text('Failed to approve transfer: $err'),
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

  Future<void> _denyTransfer(String txId, String receiverName, String formattedAmount) async {
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
          'Are you sure you want to deny this $formattedAmount transfer to $receiverName? The transfer will be cancelled immediately.',
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
        await GuardianService().denyTransfer(txId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 8),
                Text('Transfer denied and cancelled. Funds refunded.'),
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

  Future<void> _topUpSeniorWallet(String seniorId, String seniorPhone) async {
    double amount = 0;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF4338CA)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Top Up $seniorPhone',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: '0.00',
            prefixText: '₹ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          onChanged: (val) => amount = double.tryParse(val) ?? 0,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amount > 0) {
                final paise = (amount * 100).round();
                try {
                  final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('addDemoFunds');
                  await callable.call({'amountPaise': paise, 'targetUserId': seniorId});
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add funds: $e'), backgroundColor: Colors.red),
                    );
                  }
                  return;
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Successfully added ${Money.fromRupees(amount).formatted} to senior\'s wallet!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Top Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showManageContactsDialog(
      BuildContext context, String seniorId, List<String> currentContacts) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Color(0xFF4338CA)),
                SizedBox(width: 8),
                Text('Trusted Contacts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Transfers to trusted numbers bypass fraud warnings and do not require guardian review.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '+91 98765 43210',
                            labelText: 'Add Phone Number',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () async {
                          final phone = phoneController.text.trim().replaceAll(' ', '');
                          if (phone.isNotEmpty) {
                            try {
                              await GuardianService().modifyTrustedContacts(
                                seniorId: seniorId,
                                phone: phone,
                                add: true,
                              );
                              phoneController.clear();
                              setDialogState(() {
                                currentContacts.add(phone);
                              });
                            } catch (err) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to add contact: $err'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF4338CA)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (currentContacts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No trusted contacts added yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: currentContacts.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final contact = currentContacts[index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading:
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            title: Text(contact,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () async {
                                try {
                                  await GuardianService().modifyTrustedContacts(
                                    seniorId: seniorId,
                                    phone: contact,
                                    add: false,
                                  );
                                  setDialogState(() {
                                    currentContacts.removeAt(index);
                                  });
                                } catch (err) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to remove contact: $err'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEscrowDelayDialog(BuildContext context, String seniorId, int currentDelay) {
    int selected = currentDelay;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Configure Escrow Hold',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Set how long transfers are held before final settlement so the Senior can cancel if scammed:'),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: [5, 15, 30, 60, 1440].contains(selected) ? selected : 5,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)))),
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 minutes (Quick)')),
                    DropdownMenuItem(value: 15, child: Text('15 minutes')),
                    DropdownMenuItem(value: 30, child: Text('30 minutes')),
                    DropdownMenuItem(value: 60, child: Text('1 hour (Recommended)')),
                    DropdownMenuItem(value: 1440, child: Text('24 hours (Maximum Safety)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selected = val);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await GuardianService().updateEscrowDelay(seniorId: seniorId, minutes: selected);
                    if (ctx.mounted) Navigator.pop(ctx);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Escrow delay set to $selected minutes.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (err) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to update escrow delay: $err'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4338CA), foregroundColor: Colors.white),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Guardian Control Center',
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
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF4338CA)),
            tooltip: 'Link Another Senior',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GuardianLinkingScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: currentUid.isEmpty
            ? null
            : FirebaseFirestore.instance
                .collection('users')
                .where('linkedGuardianId', isEqualTo: currentUid)
                .snapshots(),
        builder: (context, seniorSnapshot) {
          final seniorDocs = seniorSnapshot.data?.docs ?? [];
          final Map<String, dynamic>? seniorData =
              seniorDocs.isNotEmpty ? (seniorDocs.first.data() as Map<String, dynamic>) : null;
          final String seniorId = seniorDocs.isNotEmpty ? seniorDocs.first.id : '';
          final String seniorPhone = seniorData?['phoneNumber'] ?? 'Senior';
          final double seniorBalance =
              (seniorData?['walletBalance'] is num) ? (seniorData!['walletBalance'] as num).toDouble() : 0.0;
          final int escrowDelay = seniorData?['escrowDelayMinutes'] ?? 5;
          final List<String> trustedContacts =
              List<String>.from(seniorData?['trustedContacts'] ?? []);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              // Monitored Senior Profile & Wallet Card
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF10B981),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                seniorDocs.isNotEmpty ? 'Monitoring $seniorPhone' : 'No Senior Linked',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                seniorDocs.isNotEmpty
                                    ? 'Active Protection • $escrowDelay min Escrow'
                                    : 'Tap + above to pair a senior account',
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
                    if (seniorDocs.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Senior Balance',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 4),
                              StreamBuilder<DocumentSnapshot>(
                                stream: seniorId.isNotEmpty
                                    ? FirebaseFirestore.instance
                                        .collection('wallets')
                                        .doc(seniorId)
                                        .snapshots()
                                    : null,
                                builder: (context, walletSnap) {
                                  if (walletSnap.hasData &&
                                      walletSnap.data != null &&
                                      walletSnap.data!.exists) {
                                    final wallet = Wallet.fromFirestore(walletSnap.data!);
                                    return Text(
                                      Money(paise: wallet.availableBalancePaise).formatted,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    );
                                  }
                                  return Text(
                                    Money(paise: (seniorBalance * 100).round()).formatted,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _topUpSeniorWallet(seniorId, seniorPhone),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Top Up'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4338CA),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showManageContactsDialog(context, seniorId, trustedContacts),
                              icon: const Icon(Icons.people_outline, size: 18),
                              label: Text('Safe Contacts (${trustedContacts.length})'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showEscrowDelayDialog(context, seniorId, escrowDelay),
                              icon: const Icon(Icons.timer_outlined, size: 18),
                              label: const Text('Escrow Delay'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Flagged Approvals Section Header
              StreamBuilder<List<TransactionModel>>(
                stream: currentUid.isEmpty
                    ? null
                    : context.read<TransactionProvider>().streamTransactionsForGuardian(currentUid),
                builder: (context, flaggedSnapshot) {
                  final allTxs = flaggedSnapshot.data ?? [];
                  final pendingTxs = allTxs
                      .where((tx) => tx.status == TransactionStatus.REVIEW_REQUIRED)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Pending Approvals',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: pendingTxs.isNotEmpty
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pendingTxs.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (pendingTxs.isEmpty)
                        Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFECFDF5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_rounded,
                                    size: 40,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'All Caught Up!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No flagged transfers require review right now.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: pendingTxs.map((tx) {
                            final txId = tx.id;
                            final amount = Money(paise: tx.amountPaise).formatted;
                            final receiverName =
                                tx.recipientName.isNotEmpty ? tx.recipientName : 'Recipient';
                            final flaggedReason =
                                tx.riskReasons.isNotEmpty ? tx.riskReasons.join(', ') : 'Unknown';
                            final isActiveCall = tx.riskReasons.contains('active_call') ||
                                tx.riskReasons.any((r) => r.toLowerCase().contains('call'));
                            final isUntrusted = tx.riskReasons.contains('untrusted_contact') ||
                                tx.riskReasons.any((r) => r.toLowerCase().contains('untrusted'));
                            final createdAt = tx.createdAt;
                            final dateStr = createdAt != null
                                ? DateFormat('MMM d, yyyy • h:mm a').format(createdAt)
                                : 'Just now';

                            String warningMsg = 'FLAGGED: $flaggedReason';
                            IconData warningIcon = Icons.warning_amber_rounded;
                            if (isActiveCall) {
                              warningMsg = 'FLAGGED: Active Phone Call Detected';
                              warningIcon = Icons.phone_in_talk_rounded;
                            } else if (isUntrusted) {
                              warningMsg = 'FLAGGED: Untrusted Contact';
                              warningIcon = Icons.person_off_rounded;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(warningIcon, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          warningMsg,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            receiverName,
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                                fontSize: 13, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        amount,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _isProcessing
                                              ? null
                                              : () => _denyTransfer(txId, receiverName, amount),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14)),
                                          ),
                                          child: const Text('Block & Refund',
                                              style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isProcessing
                                              ? null
                                              : () => _authenticateAndApprove(txId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF16A34A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14)),
                                          ),
                                          child: const Text('Approve',
                                              style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Activity & Audit History
              const Text(
                'Activity & Audit History',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              StreamBuilder<List<TransactionModel>>(
                stream: currentUid.isEmpty
                    ? null
                    : context.read<TransactionProvider>().streamTransactionsForGuardian(currentUid),
                builder: (context, auditSnapshot) {
                  final allTxs = auditSnapshot.data ?? [];
                  final auditTxs = allTxs
                      .where((tx) => tx.status != TransactionStatus.REVIEW_REQUIRED)
                      .toList();

                  if (auditTxs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text(
                          'No audit transactions recorded yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: auditTxs.map((tx) {
                      final amount = Money(paise: tx.amountPaise).formatted;
                      final receiver =
                          tx.recipientName.isNotEmpty ? tx.recipientName : 'Recipient';
                      final status = tx.status.name;
                      final createdAt = tx.createdAt;
                      final dateStr =
                          createdAt != null ? DateFormat('MMM d, h:mm a').format(createdAt) : '';

                      Color chipColor = Colors.grey;
                      if (status == 'SETTLED' || status == 'APPROVED' || status == 'completed') {
                        chipColor = Colors.green;
                      } else if (status == 'CANCELLED' || status == 'DENIED' || status == 'FAILED') {
                        chipColor = Colors.red;
                      } else if (status == 'ESCROWED' || status == 'pending' || status == 'REVIEW_REQUIRED') {
                        chipColor = Colors.orange;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(receiver,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(dateStr,
                                    style: TextStyle(
                                        color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: chipColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                        color: chipColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  amount,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

typedef GuardianDashboardScreen = GuardianDashboard;
typedef GuardianHomeScreen = GuardianDashboard;
