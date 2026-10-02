# Phase 3 - Authentication, Users, Staff & Facility Foundation

## Status

COMPLETE for the defined foundation scope. Real PostgreSQL integration tests verify authentication and facility authorization.

## Implemented

- User account persistence with active state.
- Argon2id password hashing and verification.
- JWT access-token login with environment-only secret.
- Authentication guard and current-user request context.
- Reusable role decorator and authorization guard.
- Facility, tenant, membership, and staff profile entities.
- Restrictive foreign keys and uniqueness constraints for identity/facility data.
- Protected patient and clinical visit endpoints.
- Server-side facility/tenant checks; client tenant values are not trusted.
- Minimal Flutter Dio login and in-memory bearer token compatibility.

## Database

Migration `CreateIdentityFacilityStaff1710000002000` adds `users`, `facilities`, `facility_memberships`, `staff_profiles`, and a nullable `patients.facility_id` reference. Existing Phase 2 migrations remain unchanged.

## Authentication

`POST /api/auth/register` creates a test/development account. `POST /api/auth/login` returns a short-lived JWT and safe user/membership information. Wrong, unknown, inactive, invalid-token, and expired-token cases return 401.

## Authorization

Patient and clinical visit APIs require a Bearer token and clinical/admin role. Pharmacy receives 403 on these endpoints. Facility membership determines tenant access; a mismatched tenant is rejected.

## Staff

Staff profile persistence separates medical profession from application role and links user plus facility. Full verification workflow and staff-derived visit attribution are deferred.

## Tests

- Backend build: PASS.
- Backend unit tests: 5 suites / 9 tests PASS.
- PostgreSQL e2e tests: 3 suites / 11 tests PASS.
- Migration: PASS, Phase 3 migration applied to disposable PostgreSQL.
- Security coverage: valid/wrong/unknown/inactive login, password hash, safe response, invalid/expired token, 401, 403 role, facility isolation, tenant isolation, client tenant manipulation.
- Flutter compatibility: login/token API added; analyzer and 3 Flutter tests PASS.

## Known Limitations

- Registration is intentionally minimal and must be restricted for production onboarding.
- No refresh tokens, password reset, rate limiting, account lockout, audit log, facility administration API, or secure persistent Flutter token storage.
- Existing clinical visits do not yet derive `staff_id` from the authenticated staff profile.
- Central authority verification remains represented but not implemented as a workflow.

## Deferred Features

Fingerprint production integration, DHIS2/TLHIS, pharmacy workflow, laboratory, patient portal, full sync queue, conflict resolution, and Phase 4 patient-domain expansion.

## Next Phase

Phase 4 - Patient Domain Foundation.
