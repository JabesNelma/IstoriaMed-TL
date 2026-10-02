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

- Full offline sync, conflict resolution, and background synchronization remain deferred.
- Prescription, pharmacy, laboratory, DHIS2, and biometric modules remain deferred.

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
- Prescription and pharmacy workflow, laboratory and radiology, DHIS2/TLHIS integration, fingerprint matching, and the patient portal remain deferred.
