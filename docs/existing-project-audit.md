# Existing Project Audit

## Current Architecture

The repository contains a NestJS backend under `src/backend` and a Flutter client under `src/frontend`. The Flutter client uses BLoC, Dio, and Isar. The backend currently uses in-memory arrays rather than a central database.

## Backend Status

Patient and clinical visit modules exist with basic controllers and services. The backend builds, but persistence, authentication, authorization, facility entities, DTO validation before Phase 1, and database migrations were missing.

## Flutter Status

Patient registration and SOAP clinical visit screens exist. BLoCs delegate to repositories, and repositories write to Isar before attempting API synchronization.

## Database Status

No PostgreSQL/Supabase client, ORM, migration, seed, Docker database, or SQL migration was found. Local Isar schemas exist for patients and clinical visits.

## Authentication Status

Not found. There is no login, token, session, secure offline session, or authentication guard.

## RBAC Status

Not found. There are no roles, permissions, guards, or policy checks.

## Facility/Tenant Status

Clinical visits contain a client-supplied `tenant_id`, but there is no facility model or server-side tenant authorization. This is a known security limitation deferred to a later phase.

## Patient Status

Patient registration exists. Before Phase 1, the service used an in-memory list and required KTP at the type level. Phase 1 adds DTO validation, nullable KTP support, an internal medical record number, and timestamps; persistence remains in-memory until the database phase.

## Clinical Visit Status

SOAP and ICD-10 fields exist, with patient existence checking and tenant filtering. The tenant value is still request supplied and is not an authorization boundary. An unused duplicate clinical entity source file was present and is removed in Phase 1.

## Offline Status

Isar persistence exists and records are written locally before network synchronization. This is partial offline support, not a complete sync queue.

## Sync Status

Basic periodic synchronization exists for pending patients and clinical visits. There is no operation ID, retry count, `SYNCING` state, idempotency, or full conflict handling.

## Testing Status

Backend tests previously covered mostly construction and the root endpoint. Flutter had one widget smoke test. Phase 1 adds backend request validation and domain behavior tests plus typed API failure tests for Flutter.

## Documentation Status

The root and subproject READMEs were framework templates. `docs/` and `progres.md` were absent before the audit documentation was added.

## Existing Problems

- Backend data is lost on restart.
- No authentication, RBAC, facility authorization, or central persistence.
- Client-supplied tenant IDs are not security boundaries.
- DTO validation was absent.
- API and repository failures were previously treated as pending/offline indiscriminately.
- Clinical entity source was duplicated.

## Missing Requirements

Central database, authentication, RBAC, facility management, secure session, full sync queue, retry/idempotency, patient search, and server-side tenant enforcement remain missing.

## Duplicate Implementations

`src/backend/src/modules/istoria_klinis/entities/istoria-klinis.entity.ts` duplicated the canonical `istoria-klinis.entity.ts` and had no source imports. The unused duplicate was removed safely; the patient compatibility re-export remains because it is a separate compatibility file.

## Recommended Corrections

Phase 1 stabilizes request validation, typed client error handling, tests, and documentation. The next major phase should introduce PostgreSQL-compatible persistence and migrations before authentication and tenant authorization.

## Safe Next Step

Phase 2 - Database and persistence foundation, with no destructive reset or migration operation.
