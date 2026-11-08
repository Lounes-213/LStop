import '../models/user.dart';
import '../utils/result.dart';
import '../auth/google_auth_service.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

abstract interface class AuthRepository {
  Future<Result<User, String>> signInWithGoogle(UserRole role);
  Future<void> signOut();
  Future<bool> isAuthenticated();
  Future<Result<User, String>> getCurrentUser();
}

class AuthRepositoryImpl implements AuthRepository {
  final GoogleAuthService _authService;
  final ApiClient _apiClient;

  AuthRepositoryImpl({
    GoogleAuthService? authService,
    ApiClient? apiClient,
  })  : _authService = authService ?? GoogleAuthService(),
        _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<User, String>> signInWithGoogle(UserRole role) async {
    return await _authService.signIn(role: role);
  }

  @override
  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _authService.isAuthenticated();
  }

  @override
  Future<Result<User, String>> getCurrentUser() async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.userMe,
      parser: (data) => data as Map<String, dynamic>,
    );

    return res.when(
      success: (data) {
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        return Success(user);
      },
      failure: (err) => Failure(err),
    );
  }
}

