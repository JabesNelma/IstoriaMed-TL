# Phase 5 - Clinical Visit Domain Foundation

## Status

COMPLETE for the implemented foundation scope.

## Implemented

- Clinical visit DTO validation for patient, visit date, diagnosis, and SOAP fields.
- Protected server-side derivation of `staff_id`, `facility_id`, and `tenant_id` from the authenticated user and membership context.
- Server-side patient scope verification before visit creation.
- `GET /api/istoria-klinis` list endpoint scoped by facility/tenant membership.
- `GET /api/istoria-klinis/:id` detail endpoint scoped by facility/tenant membership.
- `GET /api/istoria-klinis/pasien/:pasienId` history endpoint scoped to authorized patient and tenancy.
- `PATCH /api/istoria-klinis/:id` update endpoint for visit content only.
- Additional `facility_id` foreign key and index on `clinical_visits`.
- Patient/visit authorization boundaries remain enforced across facility and tenant scope.

## Database

Migration `AddFacilityToClinicalVisits1710000003000` adds `clinical_visits.facility_id` and a restrictive `facility_id` foreign key, plus an index for query performance.

## Ownership and Authorization Rules

- Client input is not trusted for `staff_id`, `facility_id`, or `tenant_id`.
- The authenticated staff profile is used to populate `staf_id`.
- The first matching authorized facility membership default is used when a user has valid access, and any mismatched tenant is rejected.
- A patient outside the user facility scope is rejected before a visit is created.
- A visit outside the user's facility/tenant scope is not returned.

## Security Boundaries

- Facility-only or tenant-only cross-scope requests return not found or forbidden as required by the existing security model.
- Protected clinical fields cannot be manipulated by client input.
- Full sync, retry workers, and conflict reconciliation remain deferred.

## Deferred

- Full offline synchronization engine (implemented in `phase-6-offline-sync.md`)
- Conflict-resolution queue (implemented in `phase-6-offline-sync.md`)
- Patient portal and scheduling
- Prescription and pharmacy workflow
- Laboratory and radiology
- DHIS2/TLHIS integration
- Fingerprint matching
- National staff verification workflow
