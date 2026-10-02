# Authentication and Authorization Architecture

## Authentication

`POST /api/auth/register` creates a development account and stores only an Argon2id password hash. `POST /api/auth/login` verifies an active account and returns a short-lived JWT access token. The JWT secret and expiration are environment variables; no secret is committed.

Authentication failures return `401 Unauthorized` without revealing whether an identifier exists. Password hashes are never returned in the safe user response or JWT payload.

## Authorization

Protected patient and clinical visit controllers use `AuthGuard` and `RolesGuard`. `AuthGuard` validates the Bearer JWT and reloads the active user and memberships from PostgreSQL. `RolesGuard` applies the allowed application roles through the `@Roles` decorator.

Current clinical roles:

- `SUPER_ADMIN`
- `SYSTEM_ADMIN`
- `DOCTOR`
- `NURSE`
- `MIDWIFE`
- `PHARMACY`

Patient and clinical visit endpoints allow administrative and clinical roles. Pharmacy is intentionally denied from those endpoints at this foundation stage.

## User, Facility, Membership, and Staff

- `users`: login identifier, Argon2 password hash, active state, timestamps.
- `facilities`: facility code/name/type, location, and logical `tenant_id`.
- `facility_memberships`: explicit user/facility relationship, role, active state.
- `staff_profiles`: user/facility relationship, medical license, profession, verification status.

Application role and medical profession are separate concepts. Staff verification workflow is represented but central authority approval is deferred.

## Security Boundary

The backend derives facility access from authenticated memberships. New patients are assigned the selected active membership facility; the client cannot submit a facility assignment. Clinical visit creation requires the submitted tenant to match an authenticated membership and checks the patient facility before writing. Tenant listing and history queries are filtered by memberships.

A client-supplied `tenant_id` is therefore not an authorization source. Unknown or unauthorized tenants are rejected before resource lookup where applicable.

## Environment

```text
JWT_SECRET=replace-with-a-long-random-secret
JWT_ACCESS_TOKEN_EXPIRES_IN=15m
```

Use secret management in production. Never log passwords, password hashes, JWT secrets, or access tokens.

## Development and Test Setup

Run the Phase 3 integration database with the existing disposable PostgreSQL workflow, apply migrations, then provide `DATABASE_URL` and `JWT_SECRET` to the test command. Test accounts and facilities are generated inside the integration suite and are not production seed data.

## Flutter Compatibility

`ApiClient.login` calls the backend login endpoint. `setAccessToken` and `clearAccessToken` configure the current Dio instance. Tokens are intentionally not persisted by this phase; platform secure storage and login UI are deferred until the frontend authentication workflow is explicitly implemented.

## Known Limitations

Refresh tokens, password reset, rate limiting, account lockout, audit logging, staff approval workflow, facility administration endpoints, and production secure token storage remain deferred. The current registration endpoint is a minimal foundation and must be restricted or replaced by an administrative onboarding workflow before production deployment.
