import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../features/auth/driver_login_screen.dart';
import '../features/onboarding/document_upload_screen.dart';
import '../features/approval/pending_approval_screen.dart';
import '../features/shift/driver_home_screen.dart';
import '../features/navigation/active_trip_screen.dart';
import '../features/earnings/earnings_screen.dart';
import '../features/profile/driver_profile_screen.dart';

final driverRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(driverAuthProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuthed = authState.isAuthenticated;
      final isLoginRoute = state.uri.path == '/login';
      final isOnboardRoute = state.uri.path == '/onboard';
      final isApprovalRoute = state.uri.path == '/approval';

      if (!isAuthed && !isLoginRoute) {
        return '/login';
      }

      if (isAuthed) {
        if (isLoginRoute) {
          if (!authState.isApproved) {
            return authState.driver?.licenseNumber == null ? '/onboard' : '/approval';
          }
          return '/';
        }

        if (!authState.isApproved && !isApprovalRoute && !isOnboardRoute) {
          return authState.driver?.licenseNumber == null ? '/onboard' : '/approval';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const DriverLoginScreen(),
      ),
      GoRoute(
        path: '/onboard',
        builder: (context, state) => const DocumentUploadScreen(),
      ),
      GoRoute(
        path: '/approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/active-trip/:tripId',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId'] ?? '';
          return ActiveTripScreen(tripId: tripId);
        },
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
