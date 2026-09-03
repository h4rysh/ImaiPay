import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _updateEscrowDelay(String uid, int currentDelay) async {
    int newDelay = currentDelay;
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Escrow Delay (Minutes)', style: TextStyle(fontSize: 24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$newDelay Minutes',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: newDelay.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    onChanged: (val) {
                      setState(() {
                        newDelay = val.toInt();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, currentDelay),
                  child: const Text('Cancel', style: TextStyle(fontSize: 20)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, newDelay),
                  child: const Text('Save', style: TextStyle(fontSize: 20)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result != currentDelay && context.mounted) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'escrowDelayMinutes': result,
      });
    }
  }

  Future<void> _unlinkAccount(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Guardian?', style: TextStyle(fontSize: 24)),
        content: const Text(
          'This will remove your guardian. They will no longer be able to approve large transfers.',
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 20)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlink', style: TextStyle(fontSize: 20, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'linkedGuardianId': FieldValue.delete(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final uid = authProvider.user?.uid;
    
    if (uid == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return const SizedBox();

          final profile = UserProfile.fromMap(data, snapshot.data!.id);
          final hasGuardian = profile.linkedGuardianId != null && profile.linkedGuardianId!.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SettingsCard(
                title: 'Escrow Delay',
                subtitle: '${profile.escrowDelayMinutes} minutes',
                icon: Icons.timer,
                onTap: () => _updateEscrowDelay(uid, profile.escrowDelayMinutes),
              ),
              const SizedBox(height: 20),
              if (hasGuardian)
                _SettingsCard(
                  title: 'Unlink Guardian',
                  subtitle: 'Remove connected guardian account',
                  icon: Icons.link_off,
                  iconColor: Colors.red,
                  onTap: () => _unlinkAccount(uid),
                ),
              if (hasGuardian) const SizedBox(height: 20),
              _SettingsCard(
                title: 'Sign Out',
                subtitle: 'Log out of your account',
                icon: Icons.logout,
                onTap: () => authProvider.signOut(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: iconColor ?? Colors.blue),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
