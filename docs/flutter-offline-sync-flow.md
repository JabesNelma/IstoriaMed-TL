# Flutter Offline Sync Flow (Frontend Phase 6)

Status: Sync Center implemented on top of the existing sync engine. The
engine itself (queue, dependency ordering, backoff, idempotency, restart
recovery) is unchanged.

## Data path

```text
UI
 |
BLoC (PasienBloc / IstoriaBloc / PrescriptionBloc)
 |
Repository (Pasien / Istoria / Prescription)
 |
Isar transaction (entity + SyncOperation, atomic)
 |
SyncService.syncPending()
 |
ApiClient.submitSyncOperation (operationId = idempotency key)
 |
Backend
```

## Sync Center (`presentation/screens/sync_center_screen.dart`)

Replaces the old placeholder Sync tab in the Staff Shell. Backed by a small
`SyncBloc` (`logic/sync_bloc/`) that only reads the queue and calls the
existing `SyncService` — no second sync engine, no UI-level retry logic.

### Status line (honest state only)

The app has NO connectivity detection yet, so the screen never claims
"Online"/"Offline". The status dot is derived from the queue itself:

| Queue state | Label |
|---|---|
| any FAILED operation | Iha problema sinkronizasaun |
| pending operations, none failed | Dadus hein sinkronizasaun |
| queue empty / all synced | Dadus hotu sinkroniza tiha ona |

Also shown: waiting count (pending + failed) and last successful sync time
(max `syncedAt` of the queue).

### Pending queue

Lists PENDING and FAILED `SyncOperation`s (existing model) oldest-first:
entity label (Pasiente / Kunjungan Klinis / Rese), status chip, created time,
and for failures the stored reason. JWTs, raw payloads, stack traces and
internal errors are never shown.

### Manual sync

`Sinkroniza Agora` calls `SyncService.syncPending()` only. The result is
reported per outcome (X susesu, Y falha, Z sei hela) — a partial failure is
never reported as full success.

### Retry

`Koko Fali` on a FAILED operation calls the new
`SyncQueue.requeueFailed(isar, operationId)`, which returns the SAME
operation to PENDING (identity/backoff fields intact, no new queue entry) and
then runs `syncPending()`. The operationId/entityId idempotency key is never
regenerated, so a retried operation cannot create a duplicate record on the
server.

## Offline UX

After creating a patient, visit or prescription offline, the detail screens
show `StatusIndicator` with the local status (`Pending` = Lokal / Offline),
so the user can see: **data is saved on the device, waiting for the
server.** Sync failure after a server rejection shows the entity as
`Failed` in the queue and in the Sync Center.

## Known limitations (unchanged, by design)

- No connectivity detection, no background/OS scheduling; sync happens on
  app start, after each create, and on the manual button.
- Only CREATE operations are synchronized; UPDATE/DELETE remain deferred.
- The medication catalog has no offline cache (server-owned reference data);
  without connectivity prescription creation is only possible in demo mode.
- No conflict resolution; the server response is authoritative.
