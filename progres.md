# IstoriaMed-TL Progress

## Phase 0 - Audit

- [x] Repository audited
- [x] Existing architecture documented in `docs/existing-project-audit.md`

## Phase 1 - Foundation Stabilization

- [x] Repository structure verified
- [x] Existing tests baseline recorded
- [x] Backend foundation verified
- [x] Backend configuration verified
- [x] Environment configuration verified
- [x] Error handling standardized
- [x] DTO validation foundation implemented
- [x] Duplicate clinical implementation resolved
- [x] Flutter foundation verified
- [x] Isar foundation verified
- [x] Dio/API error handling verified
- [x] Repository error propagation corrected
- [x] Basic testing foundation improved
- [x] Documentation updated
- [x] Phase 1 acceptance tests passed
- [x] Phase 1 completed

## Known Limitations

- Central PostgreSQL/Supabase persistence is implemented for patients and clinical visits; production provisioning remains pending.
- Fingerprint, DHIS2/TLHIS, pharmacy, laboratory, and patient portal are deferred.

## Phase 2 - Database & Persistence Foundation

- [x] Database technology verified
- [x] ORM verified/selected
- [x] Database configuration implemented
- [x] Migration system implemented
- [x] Patient persistence implemented
- [x] Clinical visit persistence implemented
- [x] Patient/visit relationship implemented
- [x] Constraints implemented
- [x] API compatibility verified
- [x] Integration tests implemented
- [x] Flutter compatibility verified
- [x] Database documentation completed
- [x] Phase 2 acceptance tests passed
- [x] Phase 2 completed

## Phase 2 Known Limitations

- Production PostgreSQL/Supabase provisioning is not configured in this repository.
- Authentication, RBAC, facility authorization, and staff relationships are deferred.

## Phase 3 - Authentication, Users, Staff & Facility Foundation

- [x] User/account model
- [x] Password hashing
- [x] Authentication endpoint
- [x] Token validation
- [x] Authentication guard
- [x] Roles
- [x] Authorization guard/policy
- [x] Facility model
- [x] User-facility membership
- [x] Staff profile
- [x] Tenant isolation
- [x] Patient authorization
- [x] Clinical visit authorization
- [x] Security integration tests
- [x] Flutter auth compatibility
- [x] Documentation
- [x] Final verification

## Phase 3 Known Limitations

- Refresh tokens, password reset, rate limiting, account lockout, audit logging, and production onboarding restrictions are deferred.
- Secure persistent Flutter token storage and authentication UI are deferred.
- Staff-derived clinical visit attribution and central authority verification workflow are deferred.

## Phase 4 - Patient Domain Foundation

- [x] Patient entity audit
- [x] Patient schema finalized
- [x] MRN rules verified
- [x] KTP uniqueness verified
- [x] Patient DTO validation
- [x] Patient create
- [x] Patient detail
- [x] Patient update
- [x] Patient search
- [x] Facility ownership enforcement
- [x] Tenant isolation
- [x] Protected-field enforcement
- [x] Database constraints
- [x] Database indexes
- [x] PostgreSQL integration tests
- [x] Flutter patient compatibility
- [x] Flutter analyze
- [x] Flutter tests
- [x] Documentation
- [x] Final verification

## Phase 4 Known Limitations

- Users with multiple active facilities need an explicit facility selection context before creating patients.
- Delete/archive, full offline synchronization, and clinical visit expansion are deferred.

## Phase 5 - Clinical Visit Domain Foundation

- [x] Clinical visit inspection completed
- [x] Clinical visit persistence verified
- [x] Staff derived from authenticated user
- [x] Facility ownership enforced
- [x] Tenant isolation enforced
- [x] Patient ownership verified
- [x] DTO validation completed
- [x] Create endpoint verified
- [x] Detail endpoint verified
- [x] List endpoint verified
- [x] Patient history verified
- [x] Protected field enforcement verified
- [x] PostgreSQL e2e tests passed
- [x] Backend build passed
- [x] Backend lint passed
- [x] Flutter analyze passed
- [x] Flutter tests passed
- [x] Documentation updated
- [x] Final verification

## Phase 5 Known Limitations

- Full offline sync, conflict resolution, and background synchronization remain deferred (see Phase 6).
- Prescription and pharmacy foundation delivered in Phase 7; pharmacy workflow, laboratory, DHIS2, and biometric modules remain deferred.

## Phase 6 - Offline Synchronization Engine

- [x] Persistent Isar sync queue (`SyncOperation`) with stable `operation_id`
- [x] Device-reserved canonical entity UUID adopted by the server
- [x] Atomic local write of entity plus queue entry in one Isar transaction
- [x] Queue stores an entity reference; payload resolved from Isar at send time
- [x] Single synchronization pathway shared by online and offline operation
- [x] Status machine `PENDING -> SYNCING -> SYNCED`, plus `FAILED`
- [x] Transient vs permanent failure classification
- [x] Exponential backoff 2s to 60s with injected clock and sleeper
- [x] Dependency ordering: clinical visit waits for its patient CREATE
- [x] Recovery of operations interrupted in `SYNCING` after an app restart
- [x] Sequential, oldest-first processing with no parallel sends
- [x] Concurrent `syncPending()` calls join one run
- [x] Queue survives database close/reopen (restart persistence proven)
- [x] Server idempotency via `sync_operations` primary key and `ON CONFLICT`
- [x] Entity creation and operation outcome committed in one transaction
- [x] Server authority over facility, tenant, staff, and MRN
- [x] Protected-field rejection on the sync payload
- [x] Database failure never reported as success
- [x] Startup, post-create, and manual sync triggers (polling timer removed)
- [x] Backend PostgreSQL e2e tests passed
- [x] Backend build passed
- [x] Backend lint passed
- [x] Flutter analyze passed
- [x] Flutter tests passed
- [x] Cross-stack acceptance against live NestJS + PostgreSQL passed
- [x] Documentation updated
- [x] Final verification

## Phase 6 Known Limitations

- Only `CREATE` operations are queued; update and delete synchronization, record-level merge, and conflict resolution remain deferred.
- There is no connectivity detection or OS background scheduling; drains happen at startup, after a create, and via the manual sync button.
- Delta synchronization (pull/server change feed) and multi-queue prioritization remain deferred.
- Pharmacy workflow, laboratory and radiology, DHIS2/TLHIS integration, fingerprint matching, and the patient portal remain deferred. (Prescription and medication foundation delivered in Phase 7.)

## Phase 7 - Prescription and Medication Domain Foundation

- [x] Audited the repository; no existing prescription or medication implementation to reuse
- [x] `Medication` global reference catalog (not tenant/facility scoped, no bundled seed)
- [x] `Prescription` aggregate linked to `ClinicalVisit`, with `PrescriptionItem` rows
- [x] Migration `1710000005000-CreatePrescriptionMedication` with checks and indexes
- [x] Every new foreign key uses `ON DELETE RESTRICT` (verified against PostgreSQL)
- [x] `sync_operations_entity_type_check` widened to accept `PRESCRIPTION` (Phase 6 migration untouched)
- [x] Server-derived `prescribed_by_staff_id`, `facility_id`, `tenant_id`
- [x] Ownership fields rejected through the REST validation pipe
- [x] Ownership fields rejected as protected fields on the sync payload
- [x] Exact (facility, tenant) membership-pair authorization for reads and writes
- [x] Out-of-scope prescriptions reported as `404` so existence is not disclosed
- [x] RBAC: `PHARMACY` reads the catalog but cannot prescribe
- [x] Admin-only medication catalog creation
- [x] Transactional aggregate write with full rollback on any invalid item
- [x] Shared `createWithinTransaction` write path for online and offline creation
- [x] Offline prescription queued through the existing Phase 6 engine
- [x] Dependency chain `PATIENT -> CLINICAL_VISIT -> PRESCRIPTION`
- [x] Isar `Prescription` collection with embedded `PrescriptionItem`
- [x] `PrescriptionRepository` with offline-first create and read-through reads
- [x] Backend unit tests passed
- [x] Backend build passed
- [x] Backend lint passed
- [x] Backend PostgreSQL e2e tests passed (12 required scenarios plus offline sync)
- [x] Flutter analyze passed
- [x] Flutter tests passed
- [x] Cross-stack acceptance extended with a prescription and passed
- [x] Existing Phase 6 e2e cleanup updated for the new RESTRICT foreign keys
- [x] Obsolete Phase 6 `PRESCRIPTION`-is-unsupported assertion replaced
- [x] Documentation updated
- [x] Final verification

## Phase 7 Known Limitations

- No prescription update, amendment, cancellation or version history. Adding an update endpoint now would need an amendment/versioning model that is out of scope.
- The pharmacy workflow (issue, dispense, return) and stock control remain deferred.
- No medication interaction, allergy or dose-range checking.
- No bundled medication catalog seed; reference data is a deployment concern.
- The medication catalog requires connectivity. It is server-owned reference data and is never queued; an offline catalog cache is deferred.
- No prescription UI screens or BLoC. Phase 7 delivers the model, repository, and sync layers only.
- `UPDATE`/`DELETE` sync operations, conflict resolution, delta synchronization and background scheduling remain deferred from Phase 6.

## Phase 7.1 - Final Architecture Audit and Checkpoint

Read-only audit of the completed Phase 1-7 foundation. Two genuine security
defects were found and fixed; everything else was verified and left unchanged.

- [x] Repository, working tree and phase baseline inspected
- [x] Migration chain verified: 6 migrations, correct order, none duplicated, none edited
- [x] Delete behaviour verified: 12 foreign keys, zero CASCADE, zero SET NULL, all RESTRICT
- [x] Medical erasure blocked for patient, clinical visit, prescription and medication
- [x] Authentication audited: argon2 hashing, inactive user rejected on every request
- [x] RBAC audited, including `PHARMACY` read-only on the catalog
- [x] Facility/tenant isolation audited across every protected domain
- [x] Client-controlled identity manipulation audited on REST and sync payloads
- [x] Patient domain audited (server MRN, partial unique KTP, multiple NULL KTP)
- [x] Clinical visit domain audited, including `GET /api/istoria-klinis/tenant/:tenantId`
- [x] Prescription and medication domain audited
- [x] Prescription update confirmed still deferred, no write endpoint exists
- [x] `include_inactive` boolean regression still covered
- [x] Offline queue, dependency chain and `operation_id` idempotency audited
- [x] Flutter/Isar audited, single synchronization architecture confirmed
- [x] Cross-stack acceptance re-run against a real backend and PostgreSQL
- [x] Regression tests proven to fail when the fix is reverted
- [x] Documentation corrected (test counts, catalog-wipe operational note, deferred items)
- [x] All gates green

### Defects found and fixed in Phase 7.1

1. **Cross facility clinical visit access** (`istoria_klinis.service.ts`). The
   service matched `facility_id IN (...) OR tenant_id IN (...)`, which is not pair
   safe. A visit whose `tenant_id` column contradicts the tenant that owns its
   facility was readable through every read endpoint and, worse, **editable**
   through `PATCH` by another facility's user. Replaced with exact
   `(facility, tenant)` membership pairs while keeping legacy facility-less
   visits visible to their own tenant.

2. **SQL operator precedence in the authorization scope**
   (`istoria_klinis.service.ts` and `prescription.service.ts`). The scope is an
   `OR` disjunction that was not wrapped in parentheses. Because SQL binds `AND`
   before `OR`, the `:id` filter applied only to the first branch, so
   `GET /api/istoria-klinis/:id` and `GET /api/prescriptions/:id` could return an
   arbitrary in-scope record for an identifier that does not exist. The scope is
   now grouped. For prescriptions this was only observable for a caller holding
   more than one membership pair.

### Phase 7.1 Known Limitations

- `clinical_visits.staf_id` has no foreign key to `staff_profiles`, so deleting a
  clinician leaves a dangling reference on their visits. This cannot erase
  history (the visit row survives) and `prescriptions.prescribed_by_staff_id` is
  already RESTRICT protected, but the referential integrity gap should be closed
  with a composite constraint before clinical visits are further extended.
- `clinical_visits.tenant_id` is a plain column with no foreign key, so a
  migrated or corrupted row can name a tenant that contradicts its facility. The
  authorization layer now defends against this, but the schema does not prevent it.
- A composite foreign key `(facility_id, tenant_id)` referencing
  `facilities (facility_id, tenant_id)` would make the pair consistent by
  construction. Deferred because it alters an already applied migration.
- `facilities.tenant_id` is UNIQUE, so a tenant cannot yet own more than one
  facility. Supporting one health system with several clinics will require
  dropping that constraint; the authorization logic is already pair based and is
  ready for that change.
- Billing, insurance, claim submission, advanced reporting, drug procurement and
  pharmacy stock management remain deferred and are now recorded explicitly.

## Phase 8 - Database Integrity & Multi-Facility Foundation

Status: **BLOCKED** on the tenant foreign key. Goals A and C are complete and
verified; Goal B cannot be completed without inventing a domain that was
explicitly out of scope.

- [x] Read-only audit of entities, migrations, authorization and live PostgreSQL
- [x] Confirmed there is no Tenant entity and no `tenants` table
- [x] Goal A: `clinical_visits.staf_id` now references `staff_profiles.staff_id`
- [x] Staff orphans checked before the migration (0 found, nothing deleted)
- [x] Staff delete safety verified: RESTRICT, visit and staff row both survive
- [x] Goal C: `facilities.tenant_id` UNIQUE removed, lookup index added
- [x] Pair integrity added via composite `(facility_id, tenant_id)` foreign keys
- [x] Legacy facility-less visits still accepted, no backfill required
- [x] Down migration restores the old constraint with a descriptive guard
- [x] TypeORM entities synchronized with the new schema
- [x] Multi-facility coexistence tested (fails under the old UNIQUE constraint)
- [x] Same-tenant sibling facility isolation verified on every read surface
- [x] Cross-tenant sibling facility isolation verified
- [x] Client-forged facility and tenant pairs refused
- [x] Two legacy-row regressions adapted, not deleted
- [x] Phase 4-7 regressions green, plus cross-stack offline acceptance re-run
- [x] `docs/phase-8-database-integrity.md` written

### Blocker

No authoritative Tenant entity exists, therefore a safe `tenant_id` foreign key
cannot be introduced without a dedicated tenant-domain design phase. No
speculative `tenants` table was created.

### Phase 8 Known Limitations

- Tenant identity remains free text anchored only on `facilities.tenant_id`.
- `tenant_id` is never validated and a facility can be given an arbitrary value.
- `facility_memberships` deliberately has no `tenant_id`; the tenant is resolved
  through the facility, which is consistent but cannot be asserted separately.
- Legacy clinical visits without a `facility_id` are outside the composite pair
  constraint by PostgreSQL MATCH SIMPLE semantics and rely on the authorization
  layer's legacy branch.
- `staf_id` stays nullable, so the foreign key prevents a wrong clinician but not
  a missing one.
- Multi-facility is a database and authorization capability only. There is no
  facility selection UX, so a user with several memberships has no active
  facility concept yet.
- Patients stay facility scoped with no tenant column and cannot be shared across
  two facilities of the same tenant.
