import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/driver_splash_screen.dart';
import '../features/shift/driver_home_screen.dart';
import '../features/earnings/earnings_screen.dart';
import '../features/profile/driver_profile_screen.dart';

final driverRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const DriverSplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/earnings',
        builder: (context, state) => const EarningsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const DriverProfileScreen(),
      ),
    ],
  );
});
