# Phase 6 - Offline Synchronization Engine

## Status

COMPLETE for the implemented offline queue and sync orchestration scope.

## Architecture

One synchronization pathway is used for both online and offline operation:

```
Flutter UI -> BLoC -> Repository -> Isar transaction -> SyncQueue
                                                   |
                            SyncService -> ApiClient -> NestJS -> PostgreSQL
```

There is no separate "online" code path. A create request always writes the
local entity and its queue entry first; `SyncService` is the only component that
talks to the sync endpoint.

## Local Queue

`SyncOperation` (Isar, `src/frontend/lib/data/local/sync_operation_schema.dart`):

| Field | Purpose |
| --- | --- |
| `operationId` | Stable UUID created once, never regenerated on retry. Unique index. |
| `entityType` | `PATIENT` or `CLINICAL_VISIT`. |
| `operationType` | `CREATE`. |
| `entityId` | Canonical entity UUID reserved by the device and adopted by the server. |
| `localEntityId` | Isar primary key used to resolve the payload at sync time. |
| `status` | `PENDING`, `SYNCING`, `SYNCED`, `FAILED`. |
| `retryCount`, `lastError`, `nextAttemptAt` | Retry bookkeeping. |
| `dependsOnOperationId` | Patient CREATE a visit waits for. |
| `createdAt`, `updatedAt`, `syncedAt` | Audit trail. |

Design decisions:

- The queue stores an **entity reference**, not a duplicated JSON payload. The
  payload is resolved from the live Isar record when the operation is sent, so a
  locally edited record is never synced from a stale snapshot.
- The device reserves the canonical entity UUID up front (`remoteId`), so the
  server adopts the identifier verbatim and **no identifier mapping is needed**.
- The local entity and its queue entry are always written in **one Isar
  transaction**, so an orphan queue entry or an unqueued record is impossible.

## Status Machine

```
PENDING -> SYNCING -> SYNCED
              |
              +-> transient error -> PENDING (nextAttemptAt set, retryCount++)
              +-> permanent error -> FAILED
```

- `SyncService` processes operations strictly sequentially, oldest `createdAt`
  first. Concurrent `syncPending()` calls join the in-flight run instead of
  starting a second parallel sync.
- A clinical visit whose patient CREATE is not yet `SYNCED` is skipped, and a
  `FAILED` patient dependency keeps the visit `PENDING` so **no orphan visit is
  ever produced**.
- Operations left in `SYNCING` by a process death are recovered to `PENDING` on
  the next run.
- Backoff: 2s, 4s, 8s, 16s, 32s, capped at 60s. `clock` and `sleeper` are
  injected, so tests never sleep through real backoff windows.

### Failure classification

| Condition | Result |
| --- | --- |
| No connection, DNS failure, socket error, `408`, `429`, `5xx` | transient -> stays `PENDING` |
| `400`, `403`, `404`, `409` | permanent -> `FAILED`, stops retrying |
| `401` | stays queued with backoff (never hot-loops, never dropped) |
| `201` with a `FAILED` status body | permanent rejection |
| Unknown status body | permanent -> `FAILED`, never silently swallowed |
| Missing local record | permanent -> `FAILED`, never loops forever |

## Server Contract

`POST /api/sync/operations` (auth required, roles `DOCTOR`, `NURSE`, `MIDWIFE`).

- Envelope is validated strictly (`whitelist`, `forbidNonWhitelisted`).
- Server-owned fields in the payload (`facility_id`, `tenant_id`, `staf_id`,
  `staff_id`, `user_id`, `membership_id`, `status_sinkronisasi`,
  `medical_record_number`, server timestamps) are **rejected**, never trusted.
- `operation_id` is the `sync_operations` primary key. A replay uses
  `ON CONFLICT DO NOTHING`, then re-reads the stored terminal result, so the same
  operation can be submitted any number of times without creating a second
  record.
- Entity creation and the operation outcome are committed in a single
  transaction under a row lock, so concurrent replays serialize.
- A database failure rolls the transaction back and is **not** reported as
  success.
- The authenticated membership derives facility, tenant, and staff; a patient
  outside that scope is rejected.

## Verification Evidence

All commands run against the real stack (Flutter, NestJS, PostgreSQL 16 in the
`istoria-med-postgres` container).

| Check | Command | Result |
| --- | --- | --- |
| Backend build | `npm run build` | PASS |
| Backend lint | `npm run lint` | PASS |
| Backend unit | `npm test -- --runInBand` | 5 suites / 9 tests PASS |
| Backend PostgreSQL e2e | `npm run test:e2e` | 4 suites / 22 tests PASS |
| Flutter analyze | `flutter analyze` | `No issues found!` |
| Flutter tests | `flutter test` | 30 passed, 1 skipped (cross-stack test) |

### Cross-stack acceptance scenario

`src/frontend/test/offline_acceptance_test.dart` runs the required scenario
against a live backend and PostgreSQL. Offline is simulated with a real Dio
client pointed at a closed port, so a genuine transport failure occurs; no HTTP
mocking is involved in the acceptance path.

1. `NETWORK OFF` - register a patient and create a clinical visit.
   The queue holds 2 `PENDING` operations and the visit depends on the patient.
2. `syncPending()` offline - the patient fails with a real network error and
   goes back to `PENDING` with a backoff window; the visit is `skipped` and was
   never sent.
3. Close and reopen the Isar database - both operations, their retry counters,
   their backoff windows, and both local entities are still there. A sync run at
   the same instant still skips both, proving the backoff survives the restart.
4. `NETWORK ON` - after the backoff elapses, `syncPending()` drains the queue:
   both operations reach `SYNCED` and both local entities become `Synced`.
5. Replay - the same `operation_id` values are forced back to `PENDING` and sent
   again. Both resolve to `SYNCED` and **no duplicate is created**.

Database state confirmed directly with `psql`:

```
 patient_id              |        no_ktp        | medical_record_number           | jenis_kelamin
-------------------------+----------------------+--------------------------------+---------------
 05fc9327-0e8a-...-ded732 | ACC-1790905985041212 | MRN-04ef5f16-...-025eb3af71f3 | Perempuan

 visit_id               |  tenant_id          |  staf_id                           | kode_icd10
------------------------+----------------------+------------------------------------+------------
 7d9138bc-0c02-...b24046 | tenant-acceptance-6b | 77d0ea43-5a3e-44fe-9435-a262137dba03 | J06.9

 count(patients where no_ktp like 'ACC-%')     = 1
 count(clinical_visits for that patient)      = 1
```

The `tenant_id` and `staf_id` are the server's values, not the client-supplied
`klinika-lokal`, which demonstrates server authority over protected fields.

Run it with:

```bash
ISTORIA_SYNC_E2E_BASE_URL=http://127.0.0.1:3000/api \
ISTORIA_SYNC_E2E_LOGIN=user@example.com \
ISTORIA_SYNC_E2E_PASSWORD=some-password \
flutter test test/offline_acceptance_test.dart
```

Without those variables the test reports **skipped**, never silently passed.

### Isar native library in tests

`flutter test` does not bundle the Isar core the way a device build does, so
`test/support/isar_test_support.dart` loads it from the `isar_flutter_libs`
artifact resolved through `.dart_tool/package_config.json`, falling back to a
download. The queue tests therefore run against a real Isar instance on disk,
which is required to prove restart persistence.

## Triggers

`SyncService` has no internal timer and no network-detection dependency. The
queue is drained:

- at application startup (`main.dart`, via `unawaited`),
- after a patient or clinical visit is created (from the BLoC),
- from the manual sync button on the clinical visit screen.

`timeUntilNextAttempt()` is exposed for a host that wants to schedule a follow-up
run. The previous one-minute polling `Timer` was removed so an idle device does
not wake the network needlessly.

## Deferred

- Conflict resolution and record-level merge for concurrent edits
- UPDATE/DELETE queue operations (only `CREATE` is implemented)
- Connectivity detection and OS background scheduling
- Push/pull delta synchronization and server change feed
- Multi-queue prioritization
- Patient portal, prescription and pharmacy workflow, laboratory and radiology,
  DHIS2/TLHIS integration, fingerprint matching