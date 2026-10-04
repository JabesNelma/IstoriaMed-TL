import '../data/remote/api_client.dart';
import '../data/remote/api_exception.dart';
import '../data/session/auth_session.dart';
import '../data/session/session_store.dart';

/// Thrown when login cannot proceed. Carries a user-facing message only —
/// never raw exceptions, tokens, or server internals.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Session lifecycle: login against the existing backend endpoint, restore the
/// persisted session on app start, and clear it on logout.
abstract class AuthRepository {
  Future<AuthSession> login({
    required String loginIdentifier,
    required String password,
  });

  Future<AuthSession?> restore();

  Future<void> logout();
}

class ApiClientAuthRepository implements AuthRepository {
  ApiClientAuthRepository(this._apiClient, this._store);

  final ApiClient _apiClient;
  final SessionStore _store;

  @override
  Future<AuthSession> login({
    required String loginIdentifier,
    required String password,
  }) async {
    final Map<String, dynamic> response;
    try {
      response = await _apiClient.login(
        loginIdentifier: loginIdentifier,
        password: password,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        throw const AuthFailure('Login falha. Login identifier ka password la loos.');
      }
      if (error.isNetworkFailure) {
        throw const AuthFailure(
          'Koneksaun la boot. Favor koko tan bainhira rede mosu ona.',
        );
      }
      throw const AuthFailure('Login falha. Favor koko tan fali.');
    }
    final AuthSession session;
    try {
      session = AuthSession.fromLoginResponse(response);
    } on AuthSessionFormatException {
      throw const AuthFailure('Login falha. Resposta servidor la esperadu.');
    }
    _apiClient.setAccessToken(session.accessToken);
    await _store.save(session);
    return session;
  }

  @override
  Future<AuthSession?> restore() async {
    final session = await _store.load();
    if (session == null) return null;
    _apiClient.setAccessToken(session.accessToken);
    return session;
  }

  @override
  Future<void> logout() async {
    _apiClient.clearAccessToken();
    await _store.clear();
  }
}
