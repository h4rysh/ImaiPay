import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/models/user_profile.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/linking_screen.dart';
import 'features/dashboard/senior_dashboard.dart';
import 'features/dashboard/guardian_dashboard.dart';

// Mock IDs retained for backward compatibility with payment_flow.dart
const String mockSeniorId = 'senior_user_1';
const String mockGuardianId = 'guardian_user_1';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ImaiPayApp());
}

class ImaiPayApp extends StatelessWidget {
  const ImaiPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: MaterialApp(
        title: 'ImaiPay',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (authProvider.user == null) {
              return const AuthScreen();
            }

            final userProfile = authProvider.userProfile;
            if (userProfile == null) {
              return const AuthScreen();
            }

            if (userProfile.role == UserRole.senior) {
              if (userProfile.linkedGuardianId == null || userProfile.linkedGuardianId!.isEmpty) {
                return LinkingScreen(userProfile: userProfile);
              }
              return const SeniorDashboard();
            }

            if (userProfile.role == UserRole.guardian) {
              return const GuardianDashboard();
            }

            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
