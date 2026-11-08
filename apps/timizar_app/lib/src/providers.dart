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
  static const User _localUser = User(
    id: 'usr_local_microg',
    name: 'Passager Timizar (microG)',
    email: 'local@timizar.dz',
    role: UserRole.passenger,
  );

  AuthNotifier() : super(const AsyncValue.data(_localUser));

  Future<void> checkAuth() async {
    state = const AsyncValue.data(_localUser);
  }

  Future<Result<User, String>> signIn() async {
    state = const AsyncValue.data(_localUser);
    return const Success(_localUser);
  }

  Future<void> signOut() async {
    state = const AsyncValue.data(_localUser);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});
