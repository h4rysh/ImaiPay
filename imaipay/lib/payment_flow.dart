import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main.dart'; // To access mockSeniorId

class PaymentFlowScreen extends StatefulWidget {
  const PaymentFlowScreen({super.key});

  @override
  State<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends State<PaymentFlowScreen> {
  final PageController _pageController = PageController();
  
  List<Contact>? _contacts;
  String? _selectedContactName;
  double? _amount;
  bool _isProcessing = false;
  
  PhoneStateStatus _currentPhoneStatus = PhoneStateStatus.NOTHING;
  StreamSubscription<PhoneState>? _phoneStateSubscription;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _initPhoneState();
  }

  @override
  void dispose() {
    _phoneStateSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      final contacts = await FlutterContacts.getAll();
      if (mounted) {
        setState(() {
          _contacts = contacts.take(10).toList(); // Limit for demo
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _contacts = [];
        });
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacts Permission Required'),
        content: const Text(
          'Contacts permission is needed to select who to send money to. Please enable contacts access in your settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initPhoneState() async {
    final status = await Permission.phone.request();
    if (status.isGranted) {
      _phoneStateSubscription = PhoneState.stream.listen((event) {
        if (mounted) {
          setState(() {
            _currentPhoneStatus = event.status;
          });
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone permission is needed for Live-Call Guard.'),
          ),
        );
      }
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool get _isCallActive {
    return _currentPhoneStatus == PhoneStateStatus.CALL_INCOMING ||
           _currentPhoneStatus == PhoneStateStatus.CALL_STARTED;
  }

  Future<void> _submitPayment() async {
    setState(() => _isProcessing = true);

    String status = 'in_escrow';
    String? flaggedReason;

    if (_isCallActive) {
      status = 'pending_guardian';
      flaggedReason = 'active_call';
    } else if (_amount != null && _amount! > 1000) {
      status = 'pending_guardian';
      flaggedReason = 'high_value';
    }

    try {
      await FirebaseFirestore.instance.collection('transactions').add({
        'senderId': mockSeniorId,
        'receiverName': _selectedContactName,
        'amount': _amount,
        'status': status,
        'flaggedReason': flaggedReason,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final bool isFlagged = flaggedReason != null;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                isFlagged ? 'Sent for Guardian Review!' : 'Transfer submitted!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('OK', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context); // Go back to home
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit transfer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe to force button clicks
          children: [
            _buildWhoScreen(),
            _buildAmountScreen(),
            _buildReviewScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildWhoScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Who are you sending money to?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (_contacts == null)
            const Center(child: CircularProgressIndicator())
          else if (_contacts!.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 32.0),
                child: Text('No contacts found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _contacts!.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final contact = _contacts![index];
                  final name = contact.displayName ?? 'Unknown';
                  return _ContactCard(
                    name: name,
                    isSelected: _selectedContactName == name,
                    onTap: () {
                      setState(() => _selectedContactName = name);
                      _nextPage();
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How much to $_selectedContactName?', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          TextField(
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixText: '\$ ',
              border: InputBorder.none,
              hintText: '0.00',
            ),
            onChanged: (val) {
              setState(() => _amount = double.tryParse(val));
            },
          ),
          const Spacer(),
          SizedBox(
            height: 80,
            child: ElevatedButton(
              onPressed: (_amount != null && _amount! > 0) ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Next', style: TextStyle(fontSize: 24)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Review Transfer', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          if (_isCallActive)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red),
              ),
              child: const Column(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.red, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Are you on a phone call right now?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This transfer will be sent to your Guardian for review to keep you safe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          Text('To: $_selectedContactName', style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          Text('Amount: \$$_amount', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const Spacer(),
          SizedBox(
            height: 80,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCallActive ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isProcessing 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_isCallActive ? 'Send for Review' : 'Confirm & Send', style: const TextStyle(fontSize: 24)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContactCard({required this.name, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8EAF6) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
              child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontSize: 24, color: Color(0xFF6C63FF))),
            ),
            const SizedBox(width: 24),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
