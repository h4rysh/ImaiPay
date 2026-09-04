import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'core/providers/auth_provider.dart';
import 'core/services/transfer_service.dart';

class PaymentFlowScreen extends StatefulWidget {
  const PaymentFlowScreen({super.key});

  @override
  State<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends State<PaymentFlowScreen> {
  final PageController _pageController = PageController();

  List<Contact>? _contacts;
  String? _selectedContactName;
  String? _selectedPhoneNumber;
  double _amount = 0.0;
  String _amountString = '0';
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

  String _cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  Future<void> _fetchContacts() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.name, ContactProperty.phone},
      );
      if (mounted) {
        setState(() {
          _contacts = contacts.take(20).toList();
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

  void _onKeypadTap(String value) {
    setState(() {
      if (value == '<') {
        if (_amountString.length > 1) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
        } else {
          _amountString = '0';
        }
      } else if (value == '.') {
        if (!_amountString.contains('.')) {
          _amountString += '.';
        }
      } else {
        if (_amountString == '0') {
          _amountString = value;
        } else {
          final parts = _amountString.split('.');
          if (parts.length == 2 && parts[1].length >= 2) return;
          _amountString += value;
        }
      }
      _amount = double.tryParse(_amountString) ?? 0.0;
    });
  }

  Future<void> _submitPayment() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is not authenticated.')),
      );
      return;
    }
    
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final transferService = TransferService();
      final amountPaise = (_amount * 100).round();
      final requestId = const Uuid().v4();
      
      final result = await transferService.createTransfer(
        requestId: requestId,
        recipientName: _selectedContactName ?? 'Unknown',
        recipientPhone: _selectedPhoneNumber ?? '',
        amountPaise: amountPaise,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final status = result['status'] as String?;
      final bool isFlagged = status == 'REVIEW_REQUIRED';

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Icon(
                isFlagged ? Icons.warning_rounded : Icons.check_circle,
                color: isFlagged ? Colors.orange : Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                isFlagged ? 'Sent for Guardian Review!' : 'Transfer submitted!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text('OK', style: TextStyle(fontSize: 24)),
              ),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 28),
          onPressed: () {
            if (_pageController.page != null && _pageController.page! > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildWhoScreen(),
            _buildAmountScreen(),
            _buildReviewScreen(),
          ],
        ),
      ),
    );
  }

  void _showManualRecipientDialog() {
    final nameCtrl = TextEditingController(text: 'Grandson Alex');
    final phoneCtrl = TextEditingController(text: '+919876543210');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Recipient', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name (e.g. Grandson Alex)'),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim().isEmpty ? 'Recipient' : nameCtrl.text.trim();
              final phone = _cleanPhoneNumber(phoneCtrl.text.trim());
              Navigator.pop(ctx);
              setState(() {
                _selectedContactName = name;
                _selectedPhoneNumber = phone;
              });
              _nextPage();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildWhoScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Who are you paying?', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, height: 1.1)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _showManualRecipientDialog,
            icon: const Icon(Icons.edit_outlined, size: 24),
            label: const Text('Enter Name / Phone Manually', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: const Color(0xFF6C63FF),
              side: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 24),
          if (_contacts == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_contacts!.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.contacts_outlined, size: 64, color: Colors.black26),
                    const SizedBox(height: 16),
                    const Text('No phone contacts found.', style: TextStyle(fontSize: 20, color: Colors.black54)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showManualRecipientDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Enter Recipient Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _contacts!.length,
                separatorBuilder: (context, index) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final contact = _contacts![index];
                  final name = contact.displayName ?? 'Unknown';
                  final rawPhone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
                  final cleanPhone = _cleanPhoneNumber(rawPhone);
                  final isSelected = _selectedContactName == name && _selectedPhoneNumber == cleanPhone;

                  return _ContactCard(
                    name: name,
                    phoneNumber: rawPhone.isNotEmpty ? rawPhone : null,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedContactName = name;
                        _selectedPhoneNumber = cleanPhone;
                      });
                      Future.delayed(const Duration(milliseconds: 150), _nextPage);
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
          Text(
            'How much?',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, height: 1.1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'to ${_selectedContactName ?? 'Unknown'}',
            style: const TextStyle(fontSize: 24, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Center(
            child: Text(
              '₹$_amountString',
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          _buildKeypad(),
          const SizedBox(height: 24),
          SizedBox(
            height: 80,
            child: ElevatedButton(
              onPressed: (_amount > 0) ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Next', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 1; i <= 9; i++) _buildKeypadButton(i.toString()),
        _buildKeypadButton('.'),
        _buildKeypadButton('0'),
        _buildKeypadButton('<', isIcon: true),
      ],
    );
  }

  Widget _buildKeypadButton(String label, {bool isIcon = false}) {
    return InkWell(
      onTap: () => _onKeypadTap(label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: isIcon
              ? const Icon(Icons.backspace_rounded, size: 36, color: Colors.black87)
              : Text(label, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
      ),
    );
  }

  Widget _buildReviewScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Review & Send', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 48),
          
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.grey[200]!, width: 2),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  child: Text(
                    _selectedContactName?.isNotEmpty == true ? _selectedContactName![0] : '?',
                    style: const TextStyle(fontSize: 48, color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _selectedContactName ?? 'Unknown',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (_selectedPhoneNumber != null && _selectedPhoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_selectedPhoneNumber!, style: const TextStyle(fontSize: 24, color: Colors.black54)),
                ],
                const SizedBox(height: 32),
                const Divider(height: 1, thickness: 2),
                const SizedBox(height: 32),
                Text('Amount', style: TextStyle(fontSize: 24, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(
                  '₹$_amountString',
                  style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          SizedBox(
            height: 90,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String? phoneNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContactCard({
    required this.name,
    this.phoneNumber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF).withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent, 
            width: 3
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: isSelected 
                  ? const Color(0xFF6C63FF) 
                  : const Color(0xFF6C63FF).withValues(alpha: 0.2),
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: TextStyle(
                  fontSize: 36, 
                  color: isSelected ? Colors.white : const Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (phoneNumber != null && phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      phoneNumber!,
                      style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
