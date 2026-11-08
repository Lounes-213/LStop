import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timizar_core/timizar_core.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final tokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  final api = ref.watch(apiClientProvider);
  final storage = ref.watch(tokenStorageProvider);
  return GoogleAuthService(apiClient: api, tokenStorage: storage);
});

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient();
  ref.onDispose(() => client.dispose());
  return client;
});

class DriverAuthState {
  final User? user;
  final Driver? driver;
  final bool isLoading;

  const DriverAuthState({
    this.user,
    this.driver,
    this.isLoading = false,
  });

  bool get isAuthenticated => user != null;
  bool get isApproved => driver?.approvalStatus == DriverApprovalStatus.approved;
  bool get isPending => driver?.approvalStatus == DriverApprovalStatus.pending;
  bool get isRejected => driver?.approvalStatus == DriverApprovalStatus.rejected;
}

class DriverAuthNotifier extends StateNotifier<DriverAuthState> {
  final GoogleAuthService _authService;
  final ApiClient _apiClient;

  DriverAuthNotifier(this._authService, this._apiClient)
      : super(const DriverAuthState(isLoading: true)) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = const DriverAuthState(isLoading: true);
    final isAuthed = await _authService.isAuthenticated();
    if (!isAuthed) {
      state = const DriverAuthState(isLoading: false);
      return;
    }

    final userRes = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.userMe,
      parser: (data) => data as Map<String, dynamic>,
    );

    final driverRes = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.driverStatus,
      parser: (data) => data as Map<String, dynamic>,
    );

    User? user;
    userRes.when(
      success: (data) => user = User.fromJson(data['user'] as Map<String, dynamic>),
      failure: (_) {},
    );

    Driver? driver;
    driverRes.when(
      success: (data) => driver = Driver.fromJson(data['driver'] as Map<String, dynamic>),
      failure: (_) {},
    );

    state = DriverAuthState(user: user, driver: driver, isLoading: false);
  }

  Future<Result<User, String>> signIn() async {
    state = const DriverAuthState(isLoading: true);
    final res = await _authService.signIn(role: UserRole.driver);

    return res.when(
      success: (user) async {
        await checkAuth();
        return Success(user);
      },
      failure: (err) {
        state = const DriverAuthState(isLoading: false);
        return Failure(err);
      },
    );
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const DriverAuthState(isLoading: false);
  }

  Future<bool> toggleShift(bool isOnline) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.driverShift,
      data: {'isOnline': isOnline},
      parser: (data) => data as Map<String, dynamic>,
    );

    return res.when(
      success: (data) {
        if (state.driver != null) {
          final updated = Driver(
            id: state.driver!.id,
            licenseNumber: state.driver!.licenseNumber,
            approvalStatus: state.driver!.approvalStatus,
            isOnline: isOnline,
            ratingAvg: state.driver!.ratingAvg,
            ratingCount: state.driver!.ratingCount,
            vehicle: state.driver!.vehicle,
          );
          state = DriverAuthState(user: state.user, driver: updated, isLoading: false);
        }
        return true;
      },
      failure: (err) {
        AppLogger.e('Shift toggle error: $err');
        return false;
      },
    );
  }
}

final driverAuthProvider = StateNotifierProvider<DriverAuthNotifier, DriverAuthState>((ref) {
  final authService = ref.watch(googleAuthServiceProvider);
  final api = ref.watch(apiClientProvider);
  return DriverAuthNotifier(authService, api);
});
