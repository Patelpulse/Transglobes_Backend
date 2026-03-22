import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC7SGsD3I7EOEKDh8VXchJGSYz6dnLqM4I",
      authDomain: "mera-ubar.firebaseapp.com",
      projectId: "mera-ubar",
      storageBucket: "mera-ubar.firebasestorage.app",
      messagingSenderId: "1072284227316",
      appId: "1:1072284227316:web:f7c08816b810cc00cd30a1",
      measurementId: "G-1BETFQFRZV",
    ),
  );

  runApp(const ProviderScope(child: TransglobeAdminApp()));
}

class TransglobeAdminApp extends ConsumerWidget {
  const TransglobeAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Transglobe Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
    );
  }
}
