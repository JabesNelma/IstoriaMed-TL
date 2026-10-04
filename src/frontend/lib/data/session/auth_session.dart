import 'dart:convert';

import '../local/session_schema.dart';

/// One facility membership as delivered by the login response.
class AppMembership {
  const AppMembership({
    required this.facilityId,
    required this.tenantId,
    required this.role,
  });

  final String facilityId;
  final String tenantId;
  final String role;

  factory AppMembership.fromJson(Map<String, dynamic> json) => AppMembership(
        facilityId: json['facility_id'] as String? ?? '',
        tenantId: json['tenant_id'] as String? ?? '',
        role: json['role'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'facility_id': facilityId,
        'tenant_id': tenantId,
        'role': role,
      };
}

/// Which shell the role router opens.
enum RoleGroup { staff, patient, unsupported }

/// Roles the APK treats as healthcare staff. These are the roles that exist on
/// the backend and are allowed to use the clinical screens.
const staffRoles = {'DOCTOR', 'NURSE', 'MIDWIFE', 'PHARMACY'};

/// The patient-facing role is part of the routing contract, but the backend
/// does not issue it yet — the branch exists so the shell is ready when it is.
const patientRole = 'PATIENT';

/// In-memory representation of a restored or freshly created session.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.loginIdentifier,
    required this.memberships,
  });

  final String accessToken;
  final String userId;
  final String loginIdentifier;
  final List<AppMembership> memberships;

  /// First membership that determines the shell, so staff with several
  /// memberships land on a consistent facility.
  AppMembership? get primaryMembership {
    for (final membership in memberships) {
      if (staffRoles.contains(membership.role)) return membership;
    }
    for (final membership in memberships) {
      if (membership.role == patientRole) return membership;
    }
    return memberships.isEmpty ? null : memberships.first;
  }

  RoleGroup get roleGroup {
    for (final membership in memberships) {
      if (staffRoles.contains(membership.role)) return RoleGroup.staff;
    }
    for (final membership in memberships) {
      if (membership.role == patientRole) return RoleGroup.patient;
    }
    return RoleGroup.unsupported;
  }

  factory AuthSession.fromLoginResponse(Map<String, dynamic> response) {
    final user = response['user'];
    if (user is! Map<String, dynamic>) {
      throw const AuthSessionFormatException();
    }
    final token = response['access_token'];
    final userId = user['user_id'];
    if (token is! String || token.isEmpty || userId is! String) {
      throw const AuthSessionFormatException();
    }
    final rawMemberships = user['memberships'];
    final memberships = rawMemberships is List
        ? rawMemberships
            .whereType<Map<String, dynamic>>()
            .map(AppMembership.fromJson)
            .toList(growable: false)
        : const <AppMembership>[];
    return AuthSession(
      accessToken: token,
      userId: userId,
      loginIdentifier: user['login_identifier'] as String? ?? '',
      memberships: memberships,
    );
  }

  /// Dev-preview only session (kDemoMode). Never persisted, never sent to the
  /// backend; exists so the UI/UX can be reviewed without login credentials.
  factory AuthSession.demo({required String role, String facilityId = 'demo-fasilitas'}) =>
      AuthSession(
        accessToken: 'demo-preview-token',
        userId: 'demo-user',
        loginIdentifier: 'demo@$facilityId',
        memberships: [
          AppMembership(facilityId: facilityId, tenantId: 'demo-tenant', role: role),
        ],
      );

  AppSession toStore() => AppSession()
    ..accessToken = accessToken
    ..userId = userId
    ..loginIdentifier = loginIdentifier
    ..membershipsJson =
        jsonEncode(memberships.map((membership) => membership.toJson()).toList())
    ..savedAt = DateTime.now();

  factory AuthSession.fromStore(AppSession stored) => AuthSession(
        accessToken: stored.accessToken,
        userId: stored.userId,
        loginIdentifier: stored.loginIdentifier,
        memberships: stored.memberships.map(AppMembership.fromJson).toList(),
      );
}

/// The login response did not match the documented backend contract.
class AuthSessionFormatException implements Exception {
  const AuthSessionFormatException();

  @override
  String toString() => 'Login response format unexpected.';
}
