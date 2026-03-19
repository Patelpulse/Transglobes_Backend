import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/drivers/presentation/screens/drivers_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/support/presentation/screens/alerts_screen.dart';
import '../../features/users/presentation/screens/users_screen.dart';
import '../../features/vehicles/presentation/screens/fleet_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/vehicles/presentation/screens/logistics_management_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/admin_scaffold.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/vehicles/presentation/screens/logistics_booking_screen.dart';
import '../../features/vehicles/domain/models/logistics_booking.dart';
import '../../features/vehicles/presentation/screens/fleet_screen.dart';
import '../../features/users/presentation/screens/user_form_screen.dart';
import '../../features/drivers/presentation/screens/driver_form_screen.dart';
import '../../features/settings/presentation/screens/country_code_management_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      if (authState.isLoading) return null; // Let the splash screen or whatever handle it if needed
      
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      
      if (!authState.isAuthenticated && !isLoggingIn && !isRegistering) {
        return '/login';
      }
      
      if (authState.isAuthenticated && (isLoggingIn || isRegistering)) {
        return '/';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          if (authState.isLoading) {
             return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return AdminScaffold(child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const AdminDashboardScreen()),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/drivers',
            builder: (context, state) => const DriversScreen(),
          ),
          GoRoute(
            path: '/users/new',
            builder: (context, state) => const UserFormScreen(),
          ),
          GoRoute(
            path: '/drivers/new',
            builder: (context, state) => const DriverFormScreen(),
          ),
          GoRoute(
            path: '/country-code',
            builder: (context, state) => const CountryCodeManagementScreen(),
          ),
          GoRoute(
            path: '/trips',
            builder: (context, state) => const FleetScreen(), // Mapping trips to fleet for now
          ),
          GoRoute(
            path: '/vehicles',
            builder: (context, state) =>
                const Center(child: Text('Vehicles Management')),
          ),
          GoRoute(
            path: '/logistics',
            builder: (context, state) => const LogisticsBookingScreen(),
          ),
          GoRoute(
            path: '/logistics/pending',
            builder: (context, state) => const LogisticsBookingScreen(filterStatus: LogisticsBookingStatus.pending),
          ),
          GoRoute(
            path: '/logistics/processing',
            builder: (context, state) => const LogisticsBookingScreen(filterStatus: LogisticsBookingStatus.processing),
          ),
          GoRoute(
            path: '/logistics/in-transit',
            builder: (context, state) => const LogisticsBookingScreen(filterStatus: LogisticsBookingStatus.inTransit),
          ),
          GoRoute(
            path: '/logistics/completed',
            builder: (context, state) => const LogisticsBookingScreen(filterStatus: LogisticsBookingStatus.completed),
          ),
          GoRoute(
            path: '/logistics/alerts', // Maps to Delayed/Alerts
            builder: (context, state) => const LogisticsBookingScreen(filterStatus: LogisticsBookingStatus.delayed),
          ),
          GoRoute(
            path: '/services',
            builder: (context, state) =>
                const Center(child: Text('Services & Routes')),
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) =>
                const Center(child: Text('Bookings & Operations')),
          ),
          GoRoute(
            path: '/tracking',
            builder: (context, state) =>
                const Center(child: Text('Live Tracking (Map Integration)')),
          ),
          GoRoute(
            path: '/finance',
            builder: (context, state) => const FinanceScreen(),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/super-admin',
            builder: (context, state) =>
                const Center(child: Text('Super Admin Management')),
          ),
        ],
      ),
    ],
  );
});
