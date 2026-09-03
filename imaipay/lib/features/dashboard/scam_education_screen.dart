import 'package:flutter/material.dart';

class ScamEducationScreen extends StatelessWidget {
  const ScamEducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Scam Tips',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28, // Massive typography
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _ScamCard(
            title: 'The Grandparent Scam',
            description:
                'Someone calls claiming to be your grandchild in trouble and needs money immediately. Always hang up and call your grandchild or family member directly on a known number.',
            icon: Icons.family_restroom,
            color: Colors.orange,
          ),
          SizedBox(height: 20),
          _ScamCard(
            title: 'Fake IRS Calls',
            description:
                'A caller claims you owe taxes and threatens arrest if you don\'t pay immediately. The real IRS will never call you and demand immediate payment over the phone.',
            icon: Icons.account_balance,
            color: Colors.red,
          ),
          SizedBox(height: 20),
          _ScamCard(
            title: 'Tech Support Scam',
            description:
                'A popup on your computer or a caller claims your device is infected with a virus. Never give remote access to your computer to someone who contacts you out of the blue.',
            icon: Icons.computer,
            color: Colors.blue,
          ),
          SizedBox(height: 20),
          _ScamCard(
            title: 'Lottery/Sweepstakes Scam',
            description:
                'You are told you won a prize but must pay a fee or taxes to claim it. Legitimate sweepstakes never require you to pay upfront to receive a prize.',
            icon: Icons.monetization_on,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _ScamCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final MaterialColor color;

  const _ScamCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 48, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24, // Massive typography
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                fontSize: 18, // Massive typography
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
