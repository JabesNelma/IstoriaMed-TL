# Phase 4 - Patient Domain Foundation

## Status

COMPLETE. Patient create, search, detail, update, facility scope, persistence, and Flutter compatibility were verified.

## Implemented

- Reused PostgreSQL `patients` persistence and Phase 3 facility FK.
- Added patient create/update/search DTOs with trimming and validation.
- Added scoped `GET /api/pasien/:id` detail endpoint.
- Added scoped `GET /api/pasien?q=...` search with a 50-row limit.
- Added scoped `PATCH /api/pasien/:id` update endpoint.
- Kept MRN backend-generated and protected.
- Kept nullable KTP and database partial unique constraint.
- Rejected client-controlled facility, tenant, MRN, identity, and timestamp fields through whitelist validation and explicit mapping.
- Updated Isar patient schema for nullable KTP, MRN, and facility metadata.
- Added Dio client methods for patient search/detail/update.

## Database

No new migration was required. Phase 3 already provides `patients.facility_id` with a restrictive facility foreign key and facility lookup index. Existing Phase 2 MRN and KTP constraints remain unchanged.

## Security

Patient queries use authenticated membership facility scopes. Cross-facility detail and search return no data; update is similarly scoped. Creation derives facility from the server-side membership context and denies ambiguous multi-facility creation.

## Tests

- Backend build: PASS.
- Backend unit tests: 5 suites / 9 tests PASS.
- PostgreSQL e2e: 3 suites / 12 tests PASS.
- Migration: PASS, all existing migrations applied to disposable PostgreSQL.
- Acceptance coverage: create, nullable KTP, duplicate KTP, detail, search, authorized update, protected-field rejection, restart persistence, cross-facility detail/search denial, clinical relationship preservation.
- Backend lint: PASS.
- Flutter analyze: PASS.
- Flutter tests: 3 PASS.
- Isar generation: PASS.

## Known Limitations

- A user with multiple active facilities cannot create a patient until an explicit facility-selection context is implemented.
- No delete/archive endpoint was added.
- Tenant is derived through facility and is not duplicated on the patient table.
- Full sync queue and patient UI workflow remain deferred.

## Deferred

Clinical visit domain expansion, prescription, pharmacy, laboratory, fingerprint matching, DHIS2/TLHIS, fuzzy identity matching, patient portal, and full offline synchronization.

## Next Phase

Phase 5 - Clinical Visit Domain Foundation.
