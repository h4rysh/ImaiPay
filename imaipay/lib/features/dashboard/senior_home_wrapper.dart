import 'package:flutter/material.dart';
import 'senior_dashboard.dart';
import 'scam_education_screen.dart';
import 'settings_screen.dart';

class SeniorHomeWrapper extends StatefulWidget {
  const SeniorHomeWrapper({super.key});

  @override
  State<SeniorHomeWrapper> createState() => _SeniorHomeWrapperState();
}

class _SeniorHomeWrapperState extends State<SeniorHomeWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SeniorDashboard(),
    ScamEducationScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF4338CA),
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        iconSize: 36, // Massive icons
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_rounded),
            label: 'Scam Tips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
