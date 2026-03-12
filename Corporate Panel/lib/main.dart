import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'models/logistics_provider.dart';
import 'pages/login_page.dart';

import 'pages/profile_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LogisticsProvider()),
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
    return MaterialApp(
      title: 'Transglobe Logistics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}
