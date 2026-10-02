# Phase 7 - Prescription and Medication Domain Foundation

## Status

COMPLETE for the prescription and medication foundation scope described below.
Prescription update, amendment/versioning, the pharmacy workflow and any UI are
explicitly deferred.

## Scope

Phase 7 adds the minimum real foundation for prescribing:

- a medication catalog,
- a prescription aggregate linked to one clinical visit,
- server-derived ownership and tenant/facility isolation,
- transactional writes with full rollback,
- offline-first creation through the Phase 6 queue.

It deliberately does **not** rebuild the architecture, add a second queue or a
second ORM path, or introduce a prescription update endpoint.

## Domain and Ownership

```
Medication (global catalog)
        ^
        | referenced by
        |
Prescription (one per visit) 1 --- N PrescriptionItem
        |
        | belongs to
        v
ClinicalVisit -> Patient
```

Ownership is always derived on the server, in this order:

```
authenticated user -> facility membership -> approved staff profile
                   -> clinical visit -> prescription
```

| Field | Source | Client may send it? |
| --- | --- | --- |
| `prescription_id` | Device-reserved UUID, adopted verbatim by the server | yes (offline path) |
| `visit_id` | Device request | yes |
| `items[].medication_id` | Device request | yes |
| `prescribed_by_staff_id` | Authenticated staff profile | **no** |
| `facility_id` | Owning clinical visit | **no** |
| `tenant_id` | Owning clinical visit | **no** |

Sending any ownership field through the REST endpoint is rejected with `400` by
the global `whitelist`/`forbidNonWhitelisted` validation pipe. Sending one
through the offline sync payload is rejected as a protected field and the
operation is recorded as `FAILED`, so a device can never dictate its own
identity.

## Database

Migration `1710000005000-CreatePrescriptionMedication`:

| Table | Notes |
| --- | --- |
| `medications` | Global catalog. No `tenant_id`/`facility_id`; deliberately not scoped. |
| `prescriptions` | One row per prescription, linked to `clinical_visits`. |
| `prescription_items` | One row per prescribed drug line. |

Integrity rules:

- **Every** foreign key uses `ON DELETE RESTRICT`, so clinical history can never
  be erased by a cascading delete.
- Check constraints reject blank `medications.name`, blank `prescriptions.tenant_id`,
  blank `dose`/`frequency`, and `quantity <= 0`.
- The existing `sync_operations_entity_type_check` constraint was widened to
  accept `PRESCRIPTION`. No Phase 6 migration was modified.
- Indexes cover every foreign key plus `medications.name`,
  `medications.generic_name`, `medications.is_active` and
  `prescriptions.prescribed_at`.

No medication catalog seed is bundled. Reference data is a deployment concern;
the catalog starts empty and is filled through the admin endpoint.

## Isolation

Authorization compares **exact (facility, tenant) membership pairs**, never two
independent lists.

The first implementation flattened memberships into `facilityIds` and
`tenantIds` and combined them with `OR`. That is wrong: it would let a member of
facility A read prescriptions of facility B whenever both facilities share a
tenant. Read predicates now emit one conjunction per pair:

```sql
(facility_id = :facilityId0 AND tenant_id = :tenantId0)
OR (facility_id = :facilityId1 AND tenant_id = :tenantId1)
```

Creation requires the caller's membership pair to match the visit's
`(facility_id, tenant_id)` exactly, so a membership that names the right
facility but the wrong tenant is rejected. A prescription outside the caller's
scope is reported as `404`, not `403`, so existence is not disclosed.

Note: `facilities.tenant_id` is currently `UNIQUE`, so two facilities cannot
share a tenant in this schema. The pair rule is still enforced because
`clinical_visits.tenant_id` is a plain column and a migrated or tampered visit row
can contradict its own facility. `prescription.e2e-spec.ts` covers exactly that.

## API

| Method | Route | Roles |
| --- | --- | --- |
| `POST` | `/api/prescriptions` | `SUPER_ADMIN`, `SYSTEM_ADMIN`, `DOCTOR`, `NURSE`, `MIDWIFE` |
| `GET` | `/api/prescriptions` | same |
| `GET` | `/api/prescriptions/visit/:visitId` | same |
| `GET` | `/api/prescriptions/:id` | same |
| `GET` | `/api/medications`, `/api/medications/:id` | any authenticated role, including `PHARMACY` |
| `POST` | `/api/admin/medications` | `SUPER_ADMIN`, `SYSTEM_ADMIN` |

`PHARMACY` may read the catalog but may not prescribe, matching the Phase 5 role
policy. Query parameters always arrive as strings, so `include_inactive` uses an
explicit transform that accepts only `true`/`false` and rejects anything else.

## Transactions

`PrescriptionService.create()` runs inside `dataSource.transaction()`.
`createWithinTransaction(manager, ...)` is the shared write path, so the online
REST route and the offline sync route use **one** authorization implementation and
one transactional boundary.

Every medication is resolved and validated *before* the first insert, so an
unknown or inactive medication aborts the whole aggregate and can never leave an
orphan prescription or a partial item list.

## Offline Synchronization

Prescription reuses the Phase 6 engine. There is no second queue.

```
SyncEntityType.prescription = 'PRESCRIPTION'
SyncQueue.enqueuePrescription()  -> SyncOperation(dependsOnOperationId: visit op)
SyncService._process()           -> apiClient.submitSyncOperation()
SyncService.executePrescription() -> PrescriptionService.createWithinTransaction()
```

The dependency chain is now `PATIENT -> CLINICAL_VISIT -> PRESCRIPTION`: a
prescription is never sent before its clinical visit exists on the server, and a
`FAILED` visit keeps the prescription `PENDING` so no orphan prescription is ever
produced.

The medication catalog is **not** queued. It is server-owned reference data, so
the device reads it while online and only the medication identifier travels
inside a queued prescription.

`src/frontend/lib/data/local/prescription_schema.dart` stores `PrescriptionItem`
as an Isar `@embedded` object: items are owned by the prescription, are never
synchronized independently, and never receive a device-invented identifier.

## Verification

| Check | Result |
| --- | --- |
| `npm run build` | pass |
| `npm run lint` | pass, no warnings |
| `npm test` (backend unit) | 6 suites / 55 tests pass |
| `npm run test:e2e` (real PostgreSQL) | 5 suites / 50 tests pass |
| `npm run migration:show` | 6 migrations applied in order |
| FK delete rules | all 5 new FKs report `confdeltype = 'r'` (RESTRICT) |
| `flutter analyze` | pass, no issues |
| `flutter test` | 41 pass, 1 skipped (needs a running backend) |
| Cross-stack acceptance | pass: patient + visit + prescription queued offline, restarted, synced, replayed, no duplicates |

The offline acceptance test requires a running backend and a disposable database
containing at least one synthetic active medication:

```bash
ISTORIA_SYNC_E2E_BASE_URL=http://127.0.0.1:3000/api \
ISTORIA_SYNC_E2E_LOGIN=<doctor@example.com> \
ISTORIA_SYNC_E2E_PASSWORD=<password> \
flutter test test/offline_acceptance_test.dart
```

Without those variables the test is **skipped explicitly**, never silently
passed.

### Operational note: the e2e suite empties the medication catalog

`npm run test:e2e` deletes every row of `medications` in its per-test setup, and
the acceptance user is deleted along with the other synthetic rows. So after
running the backend e2e suite you must **re-seed the catalog and re-provision the
acceptance account** before the cross-stack test can pass:

```sql
INSERT INTO medications (medication_id, name, generic_name, form, strength, unit, is_active, created_at, updated_at)
VALUES (gen_random_uuid(), 'Paracetamol (ACEITE)', 'Paracetamol', 'TABLET', '500 mg', 'TABLET', true, NOW(), NOW());
```

This ordering is intentional and was not changed: the suite must start from a
known empty catalog so that "the catalog serves exactly the rows this test
created" is a real assertion rather than an accident of leftover state.

## Regression Work Required by Phase 7

Two existing Phase 6 expectations had to change because the schema grew:

- `database.e2e-spec.ts`, `security.e2e-spec.ts` and `sync.e2e-spec.ts` now
  delete `prescription_items` and `prescriptions` before `clinical_visits`.
  `RESTRICT` would otherwise block their cleanup.
- `sync.e2e-spec.ts` asserted that `PRESCRIPTION` was an *unsupported* sync
  entity type. That negative assertion is now obsolete and uses `LAB_RESULT`
  instead.

## Deferred

- Prescription update, amendment, cancellation and version history. No update
  endpoint is provided: changing a signed prescription requires an
  amendment/versioning model that is out of scope here.
- Pharmacy dispensing workflow (issue, dispense, return, stock control)
- Pharmacy stock management and drug procurement (purchase orders, suppliers,
  receiving, expiry and batch tracking)
- Medication stock/inventory and interaction or allergy checking
- Billing, insurance and claim submission, including any revenue reporting
- Advanced reporting, analytics and export (beyond simple per-domain listings)
- National or WHO formulary catalog seed
- Prescription UI screens and BLoC (models, repository and sync layer only)
- Offline medication catalog cache (the catalog currently needs connectivity)
- `UPDATE`/`DELETE` sync operations and conflict resolution (still Phase 6
  deferred work)