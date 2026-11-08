import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../utils/result.dart';
import '../utils/app_logger.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'auth_token.dart';
import 'secure_token_storage.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;

  GoogleAuthService({
    GoogleSignIn? googleSignIn,
    ApiClient? apiClient,
    SecureTokenStorage? tokenStorage,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']),
        _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage();

  Future<Result<User, String>> signIn({required UserRole role}) async {
    try {
      AppLogger.i('Initiating Google Sign-In for role: ${role.name}');
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        return const Failure('Connexion annulée par l\'utilisateur');
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        return const Failure('Impossible d\'obtenir le jeton d\'authentification Google');
      }

      AppLogger.i('Google ID token obtained. Exchanging with Timizar backend...');
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.googleLogin,
        data: {
          'idToken': idToken,
          'role': role.name,
        },
      );

      return response.when(
        success: (data) async {
          final tokens = AuthTokens.fromJson(data);
          await _tokenStorage.saveTokens(tokens);

          final userJson = data['user'] as Map<String, dynamic>;
          final user = User.fromJson(userJson);
          await _tokenStorage.saveUserRole(user.role.name);
          await _tokenStorage.saveUserId(user.id);

          AppLogger.i('Signed in successfully as ${user.email} (${user.role.name})');
          return Success(user);
        },
        failure: (err) {
          AppLogger.e('Backend Google auth failed: $err');
          return Failure(err);
        },
      );
    } catch (e, stack) {
      AppLogger.e('Unexpected error during Google Sign-In', e, stack);
      return Failure('Erreur de connexion: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _tokenStorage.clearAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
