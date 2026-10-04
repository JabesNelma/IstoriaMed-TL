import 'package:isar/isar.dart';

import '../local/session_schema.dart';
import 'auth_session.dart';

/// Loads and saves the login session in the local Isar database.
///
/// Single-row store: saving replaces the previous session, clearing removes
/// the row, so "logout then back" can never resurrect an old token.
class SessionStore {
  SessionStore(this._isar);

  final Isar _isar;

  Future<AuthSession?> load() async {
    final stored =
        await _isar.collection<AppSession>().get(AppSession.sessionId);
    if (stored == null) return null;
    return AuthSession.fromStore(stored);
  }

  Future<void> save(AuthSession session) async {
    await _isar.writeTxn(
      () => _isar.collection<AppSession>().put(session.toStore()),
    );
  }

  Future<void> clear() async {
    await _isar.writeTxn(
      () => _isar.collection<AppSession>().delete(AppSession.sessionId),
    );
  }
}
