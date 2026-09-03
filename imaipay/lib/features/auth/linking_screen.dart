import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_profile.dart';

class LinkingScreen extends StatelessWidget {
  final UserProfile userProfile;
  final TextEditingController _codeController;

  LinkingScreen({
    super.key,
    required this.userProfile,
    TextEditingController? codeController,
  }) : _codeController = codeController ?? TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentProfile = authProvider.userProfile ?? userProfile;
    final isSenior = currentProfile.role == UserRole.senior;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isSenior ? 'Link Caretaker' : 'Link Senior Account',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: isSenior
              ? _buildSeniorView(context, currentProfile)
              : _buildGuardianView(context),
        ),
      ),
    );
  }

  Widget _buildSeniorView(BuildContext context, UserProfile profile) {
    final linkingCode = profile.linkingCode;
    final isLinked = profile.linkedGuardianId != null && profile.linkedGuardianId!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: Color(0xFFE8EAF6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.link_rounded,
              size: 48,
              color: Color(0xFF6C63FF),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Connect with Caretaker',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Share your pairing code with a trusted guardian to help protect your transactions.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        if (isLinked) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 36),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Linked',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your caretaker is connected to protect your account.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (linkingCode != null && linkingCode.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.vpn_key_rounded,
                  size: 40,
                  color: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  linkingCode,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Show this to your Caretaker to link accounts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.shield_outlined, size: 48, color: Colors.black38),
                SizedBox(height: 12),
                Text(
                  'No code generated yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tap "Generate Code" below to generate your 6-digit linking code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],

        SizedBox(
          width: double.infinity,
          height: 70,
          child: ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await context.read<AuthProvider>().generateLinkingCode();
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to generate code: $e'),
                    backgroundColor: Colors.red[400],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Generate Code',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            context.read<AuthProvider>().skipLinkingForDemo();
          },
          child: const Text(
            'Skip for Now (Explore Senior Dashboard) →',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C63FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuardianView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: Color(0xFFF3E5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 48,
              color: Color(0xFF6C63FF),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Link Senior Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Enter the 6-digit code displayed on your senior\'s screen to link accounts and review transfers.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: Colors.black87,
            ),
            decoration: const InputDecoration(
              hintText: '123456',
              hintStyle: TextStyle(
                fontSize: 32,
                letterSpacing: 8,
                color: Colors.black26,
              ),
              counterText: '',
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 70,
          child: ElevatedButton(
            onPressed: () async {
              final code = _codeController.text.trim();
              if (code.isEmpty || code.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid 6-digit code.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final authProvider = context.read<AuthProvider>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await authProvider.linkWithCode(code);

              if (success) {
                _codeController.clear();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Senior account linked successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('Invalid code or Senior not found.'),
                    backgroundColor: Colors.red[400],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Link Account',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
