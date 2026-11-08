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

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final GoogleAuthService _authService;
  final ApiClient _apiClient;

  AuthNotifier(this._authService, this._apiClient)
      : super(const AsyncValue.loading()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = const AsyncValue.loading();
    final isAuthed = await _authService.isAuthenticated();
    if (!isAuthed) {
      state = const AsyncValue.data(null);
      return;
    }

    final res = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.userMe,
      parser: (data) => data as Map<String, dynamic>,
    );

    res.when(
      success: (data) {
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        state = AsyncValue.data(user);
      },
      failure: (err) {
        state = const AsyncValue.data(null);
      },
    );
  }

  Future<Result<User, String>> signIn() async {
    state = const AsyncValue.loading();
    final res = await _authService.signIn(role: UserRole.passenger);
    return res.when(
      success: (user) {
        state = AsyncValue.data(user);
        return Success(user);
      },
      failure: (err) {
        state = const AsyncValue.data(null);
        return Failure(err);
      },
    );
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(googleAuthServiceProvider);
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(authService, api);
});
