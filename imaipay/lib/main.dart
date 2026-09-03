import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'firebase_options.dart';
import 'payment_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ImaiPayApp());
}

const String mockSeniorId = 'senior_user_1';
const String mockGuardianId = 'guardian_user_1';

class ImaiPayApp extends StatelessWidget {
  const ImaiPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImaiPay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MockAuthScreen(),
    );
  }
}

class MockAuthScreen extends StatelessWidget {
  const MockAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_rounded, size: 80, color: Color(0xFF6C63FF)),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to ImaiPay',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SeniorHomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8EAF6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text(
                      'Login as Senior',
                      style: TextStyle(fontSize: 24, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const GuardianHomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3E5F5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text(
                      'Login as Guardian',
                      style: TextStyle(fontSize: 24, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SeniorHomeScreen extends StatelessWidget {
  const SeniorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ImaiPay'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hello, there!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              // Escrow Stream
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('senderId', isEqualTo: mockSeniorId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final activeTransactions = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['status'] == 'in_escrow' || data['status'] == 'pending_guardian';
                  }).toList();

                  if (activeTransactions.isEmpty) {
                    return const Card(
                      color: Color(0xFFF5F5F5),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No pending transfers.',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    );
                  }

                  // Just show the first active one for the demo
                  final txData = activeTransactions.first.data() as Map<String, dynamic>;
                  final isPending = txData['status'] == 'pending_guardian';

                  return Card(
                    color: isPending ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(isPending ? Icons.pause_circle_filled : Icons.access_time_filled, 
                               size: 48, 
                               color: isPending ? Colors.orange : Colors.green),
                          const SizedBox(height: 16),
                          Text(
                            isPending ? 'Awaiting Guardian Approval' : 'Transfer in Escrow',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${txData['amount']} to ${txData['receiverName']}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('transactions')
                                    .doc(activeTransactions.first.id)
                                    .update({'status': 'cancelled'});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Cancel Transfer', style: TextStyle(fontSize: 20)),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              SizedBox(
                height: 80,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentFlowScreen()),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 32),
                  label: const Text('Send Money', style: TextStyle(fontSize: 24)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  Future<void> _authenticateAndApprove(String docId) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to approve this transfer',
        biometricOnly: true,
      );
      if (!mounted) return;
      if (didAuthenticate) {
        await FirebaseFirestore.instance
            .collection('transactions')
            .doc(docId)
            .update({'status': 'in_escrow'});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed. Cannot approve.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian Dashboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('status', isEqualTo: 'pending_guardian')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('All good! No pending approvals.', style: TextStyle(fontSize: 20)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final txData = docs[index].data() as Map<String, dynamic>;
              
              return Card(
                color: const Color(0xFFFFF3E0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        'Flagged: ${txData['flaggedReason'] == 'active_call' ? 'Active Phone Call' : 'High Value'}',
                        style: const TextStyle(fontSize: 18, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'User is trying to send \$${txData['amount']} to ${txData['receiverName']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('transactions')
                                    .doc(docs[index].id)
                                    .update({'status': 'cancelled'});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                              ),
                              child: const Text('Deny', style: TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _authenticateAndApprove(docs[index].id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                              ),
                              child: const Text('Approve', style: TextStyle(fontSize: 20)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}
