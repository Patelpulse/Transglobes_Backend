import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../providers/app_providers.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';
import 'payments_screen.dart';
import 'offers_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';
import 'about_screen.dart';
import 'logistics_booking_screen.dart';
import 'bus_booking_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeTab(),
          const ActivityTab(),
          AccountTab(onTabChange: (index) => setState(() => _currentIndex = index)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Activity'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }
}

// ... I'll omit HomeTab and ActivityTab for brevity to ensure I am correctly editing JUST the AccountTab?
// NO, I must provide the WHOLE file if I am using write_to_file.

// Wait, I'll use replace_file_content for AccountTab to save context.
