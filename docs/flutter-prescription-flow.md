# Flutter Prescription Flow (Frontend Phase 4)

Status: implemented and tested on the offline/local path. Backend
integration was exercised only through stubbed HTTP in
`test/prescription_sync_test.dart`; it is NOT claimed as end-to-end verified
against a live NestJS server.

## Relationship

The device reuses the existing model layer — no new collections, no new
repositories, no second queue:

```text
Patient (Pasien)
   |
   | visit.pasienId = patient.remoteId (device-reserved UUID)
   v
Clinical Visit (IstoriaKlinis)
   |
   | prescription.visitId = visit.remoteId (device-reserved UUID)
   v
Prescription  --embedded-->  PrescriptionItem[]
```

`Prescription.forPatient` resolution happens in
`PrescriptionRepository.forPatient(patientId)`: it reads the local visits of
the patient, then the local prescriptions whose `visitId` matches. It is a
pure local read — the patient profile section never does a network round trip.

## Screens

| Screen | File | Notes |
|---|---|---|
| Resep & Aimoruk (list) | `presentation/screens/prescription_list_screen.dart` | one card per prescription: date, item count, sync status; opens detail |
| Rese Foun (create) | `presentation/screens/prescription_form_screen.dart` | requires visit context; opened only from Visit Detail |
| Detalhu Rese | `presentation/screens/prescription_detail_screen.dart` | renders from the record the caller holds; works fully offline |

Navigation (all pushed routes, no named-route changes):

```text
Patient Profile
  |- Resep / Aimoruk  -> Prescription List -> Prescription Detail
  |- Riwayat Kunjungan -> Visit Detail -> "Kria Rese" -> Prescription Form
                                                      -> (save) Prescription Detail
```

## Create flow

1. The form loads the medication catalog through the existing
   `PrescriptionRepository.medications()` (server owned reference data,
   session memory cache only).
2. If the catalog cannot be reached:
   - in `kDemoMode` a clearly synthetic catalogue (`demoMedications` in
     `demo_seed.dart`) keeps the flow reviewable;
   - otherwise the form states explicitly: *Katalog aimoruk seidauk
     disponivel offline. Presiza koneksaun ba servidor.* There is no offline
     catalog cache yet — this is a documented limitation, not hidden.
3. Items are edited in a dialog using only existing `PrescriptionItem`
   fields: medication (from catalog), dose, frequency, duration, quantity,
   instructions. Required: medication, dose, frequency, quantity > 0.
4. Save validates: visit context exists (fixed by navigation), at least one
   item, anti double-submit (`AppButton` loading state).
5. `PrescriptionBloc.add(CreatePrescription)` -> `PrescriptionRepository.create`
   -> `SyncQueue.enqueuePrescription`: the prescription and its queue entry are
   written in ONE Isar transaction, then `SyncService.syncPending()` runs.

## Status display

`Prescription.syncStatus` uses the existing local statuses
(`Pending` / `Synced` / `Failed`) rendered by the shared `StatusIndicator`:
*Pending* reads as "Lokal / Offline", *Synced* as "Sinkroniza / Online",
*Failed* as "Erro server". No new status enum was created.

## Demo mode

`demo_seed.dart` additionally seeds one demo prescription for the demo
patient Maria A. Guterres, attached to her demo visit, with no queue entry —
demo data is never synchronized (behaviour preserved from Phase 2).

## Tests

`test/prescription_ui_flow_test.dart` (plain async test, real Isar — Isar
queries do not complete inside `testWidgets` fake async, the documented
gotcha):

- offline chain: register patient -> visit -> prescription, all appear
  immediately, all three queue entries in dependency order;
- `forPatient` list resolves through the visit relationship;
- restart persistence for patient, visit, prescription and queue;
- failed prescription retry requeues the SAME operation id (no duplicate).
