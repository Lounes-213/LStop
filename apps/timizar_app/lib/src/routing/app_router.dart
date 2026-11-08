import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/ride_request/ride_request_sheet.dart';
import '../features/live_tracking/live_tracking_screen.dart';
import '../features/trip_history/trip_history_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/safety/sos_dialog.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.value != null;
      final isLoginRoute = state.uri.path == '/login';

      if (isLoading) return null;

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (isAuthenticated && isLoginRoute) {
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
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const DestinationSearchScreen(),
      ),
      GoRoute(
        path: '/request',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RideRequestScreen(destination: extra);
        },
      ),
      GoRoute(
        path: '/tracking/:tripId',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId'] ?? '';
          return LiveTrackingScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const TripHistoryScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/sos',
        builder: (context, state) => const SosSafetyScreen(),
      ),
    ],
  );
});
