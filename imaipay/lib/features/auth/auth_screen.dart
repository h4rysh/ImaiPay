import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_profile.dart';
import 'linking_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();

  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendSms(AuthProvider authProvider) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number (e.g. +1234567890).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await authProvider.verifyPhoneNumber(
        phoneNumber: phone,
        codeSent: (verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification code sent successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red[400],
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  Future<void> _verifySmsCode(AuthProvider authProvider) async {
    final code = _smsCodeController.text.trim();
    if (code.isEmpty || _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the SMS verification code.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await authProvider.signInWithSmsCode(_verificationId!, code);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Invalid SMS code. Please try again.'),
              backgroundColor: Colors.red[400],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying code: $e'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  Future<void> _selectRole(AuthProvider authProvider, UserRole role) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await authProvider.createUserProfile(role);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set role: $e'),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
    }

    // User is signed in
    if (authProvider.user != null) {
      // Role not selected yet
      if (authProvider.userProfile == null) {
        return _buildRoleSelectionScreen(context, authProvider);
      }
      // Profile exists, show linking screen
      return LinkingScreen(userProfile: authProvider.userProfile!);
    }

    // User not signed in, show phone auth
    return _buildPhoneAuthScreen(context, authProvider);
  }

  Widget _buildRoleSelectionScreen(BuildContext context, AuthProvider authProvider) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Select Role',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDE7F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      size: 48,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to ImaiPay',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please select how you would like to use the app to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _selectRole(authProvider, UserRole.senior),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8EAF6),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'I am a Senior',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _selectRole(authProvider, UserRole.guardian),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3E5F5),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'I am a Caretaker/Guardian',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 32),
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneAuthScreen(BuildContext context, AuthProvider authProvider) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8EAF6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _codeSent ? Icons.sms_rounded : Icons.shield_rounded,
                      size: 48,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _codeSent ? 'Verification Code' : 'Welcome to ImaiPay',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _codeSent
                      ? 'Enter the 6-digit code sent to ${_phoneController.text.trim()}'
                      : 'Safe and protected payments for everyday life.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 48),

                if (!_codeSent) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.phone_rounded, color: Color(0xFF6C63FF), size: 28),
                        hintText: '+1234567890',
                        hintStyle: TextStyle(fontSize: 20, color: Colors.black38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _sendSms(authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Send SMS',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _smsCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.pin_rounded, color: Color(0xFF6C63FF), size: 28),
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
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _verifySmsCode(authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Verify',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _codeSent = false;
                              _smsCodeController.clear();
                            });
                          },
                    icon: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF6C63FF)),
                    label: const Text(
                      'Change Phone Number',
                      style: TextStyle(fontSize: 18, color: Color(0xFF6C63FF)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
