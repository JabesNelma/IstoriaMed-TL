import 'dart:convert';

import 'package:isar/isar.dart';

part 'session_schema.g.dart';

/// Persistent login session, stored in the existing local Isar database.
///
/// The backend currently exposes no refresh flow, so the access token is kept
/// exactly as login returned it and is replayed until the user logs out. The
/// session is a single row (id is always [sessionId]).
@collection
@Name('AppSession_2026_10_03')
class AppSession {
  static const Id sessionId = 1;

  Id id = sessionId;

  late String accessToken;
  late String userId;
  late String loginIdentifier;

  /// JSON-encoded list of `{facility_id, tenant_id, role}` objects, exactly as
  /// the login response delivered them. No role is invented here.
  late String membershipsJson;

  late DateTime savedAt;

  @ignore
  List<Map<String, dynamic>> get memberships {
    final decoded = jsonDecode(membershipsJson);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
}
