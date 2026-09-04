import 'core/theme/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/models/user_profile.dart';
import 'features/auth/auth_screen.dart';
import 'features/dashboard/senior_dashboard.dart';
import 'features/dashboard/guardian_dashboard.dart';
import 'features/auth/guardian_linking_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'core/providers/transaction_provider.dart';
import 'dart:io';

// Mock IDs retained for backward compatibility with payment_flow.dart
const String mockSeniorId = 'senior_user_1';
const String mockGuardianId = 'guardian_user_1';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Connect to local emulators
  const host = String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
  try {
    FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instanceFor(region: 'asia-south1').useFunctionsEmulator(host, 5001);
  } catch (e) {
    debugPrint('Failed to connect to emulators: $e');
  }

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
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'ImaiPay',
        theme: ImaiDesignSystem.theme,
        debugShowCheckedModeBanner: false,
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
              return const SeniorDashboard();
            }

            if (userProfile.role == UserRole.guardian) {
              if (userProfile.linkedSeniorIds.isEmpty) {
                return const GuardianLinkingScreen();
              }
              return const GuardianDashboard();
            }

            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
