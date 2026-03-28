import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'models/logistics_provider.dart';
import 'models/corporate_auth_provider.dart';
import 'pages/login_page.dart';
import 'firebase_options.dart';
import 'pages/dashboard_page.dart';

import 'pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LogisticsProvider()),
        ChangeNotifierProvider(create: (context) => CorporateAuthProvider()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
      ],
      child: const CorporatePanelApp(),
    ),
  );
}

class CorporatePanelApp extends StatelessWidget {
  const CorporatePanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<CorporateAuthProvider>();

    return MaterialApp(
      title: 'Transglobe Logistics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authProvider.isAuthenticated
          ? const DashboardPage()
          : const LoginPage(),
    );
  }
}
