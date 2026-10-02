# Phase 2 - Database & Persistence Foundation

## Status

COMPLETE. Persistence was verified against PostgreSQL 16 in an isolated disposable Podman container.

## Database Technology

PostgreSQL, with Supabase-compatible SQL types and constraints.

## ORM

TypeORM is the only backend ORM.

## Connection Architecture

Flutter continues to call NestJS over Dio. NestJS owns the TypeORM connection and repositories. `DATABASE_URL` is required; schema synchronization is disabled.

## Migration Strategy

Two versioned migrations exist:

- `CreatePatientAndClinicalVisitTables1710000000000`
- `WidenMedicalRecordNumber1710000001000`

The second migration was added after the real integration test exposed the MRN width mismatch. No applied migration was edited and no database reset was used.

## Schema

### Patient

`patients` stores UUID patient IDs, unique MRNs, nullable KTP, identity/demographic fields, optional fingerprint placeholder, and timestamps.

### Clinical Visit

`clinical_visits` stores UUID visits, patient reference, current tenant reference, nullable staff reference, visit date, SOAP fields, ICD-10, local diagnosis, synchronization status, and timestamps.

## Relationships

`clinical_visits.pasien_id` references `patients.patient_id` with `ON DELETE RESTRICT`. Staff is intentionally not a foreign key until the staff/authentication phase exists.

## Constraints

- Patient ID: UUID primary key.
- MRN: unique, backend-generated, immutable after creation.
- KTP: partial unique index for non-null values; multiple null values are allowed.
- Gender: database check constraint matching the current domain values.
- Clinical patient reference: non-null foreign key.
- Schema synchronization: disabled; migrations are required.

## Persistence Changes

Patient and clinical visit services now use TypeORM repositories instead of process-local arrays. API routes and response shapes remain compatible with the Phase 1 contract.

## API Compatibility

Existing patient registration/list and clinical visit create/history/tenant routes remain in place. DTO validation now also rejects malformed clinical UUID references before database access.

## Flutter Compatibility

Flutter continues to use Dio, BLoC, repositories, and Isar. No local database or offline behavior was removed. Central persistence is transparent to the existing API client.

## Integration Tests

Real integration tests cover:

- Patient create and read after application restart.
- Nullable KTP.
- Duplicate KTP rejection.
- Clinical visit create and read after restart.
- Invalid patient relationship rejection.
- Existing root/e2e endpoint behavior.

Command used:

```bash
DATABASE_URL=postgres://istoria:istoria_test@localhost:5432/istoria_test npm run migration:run
DATABASE_URL=postgres://istoria:istoria_test@localhost:5432/istoria_test npm run test:e2e
```

## Security Considerations

No credentials are committed. The database URL is environment-only. No tenant authorization is claimed yet; `tenant_id` remains a stored request field until the authentication/facility phase. Medical records use restrictive patient deletion behavior.

## Known Limitations

The backend requires a PostgreSQL connection to start. There is no production database provisioning, authentication, RBAC, staff table, facility authorization, audit log, soft deletion, or full sync queue yet.

## Deferred Features

Authentication, RBAC, facilities, staff, tenant authorization, fingerprint matching, DHIS2/TLHIS, pharmacy, laboratory, patient portal, and full sync remain deferred.

## Acceptance Test Results

- Backend build: PASS.
- Backend unit tests: PASS, 5 suites / 9 tests.
- TypeORM migrations: PASS, 2 migrations applied.
- PostgreSQL integration tests: PASS, 2 suites / 6 tests.
- Flutter analyze: PASS.
- Flutter tests: PASS, 3 tests.
- Git diff check: PASS.

## Next Phase

Phase 3 - Authentication, Users, Staff & Facility Foundation.
