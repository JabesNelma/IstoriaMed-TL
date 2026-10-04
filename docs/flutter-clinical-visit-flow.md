# Flutter Clinical Visit Flow (APK)

Status: **FRONTEND / LOCAL-FIRST — backend integration NOT completed.**

Phase: FRONTEND PHASE 3 — CLINICAL VISIT (2026-10-04).

## Flow

```text
PATIENT PROFILE (PasienProfileScreen)
  ├── + Kunjungan Baru → VISIT FORM (IstoriaKlinisScreen, patient context fixed)
  │        ↓ save (local, queued for sync, pushReplacement)
  │     VISIT DETAIL (VisitDetailScreen)
  ├── Riwayat Kunjungan preview (top 3) → Visit Detail
  └── "Haree hotu" → VISIT HISTORY (VisitHistoryScreen) → Visit Detail
```

The visit form is always opened from a patient profile; the patient is never
re-selected inside the form. There is intentionally no global "Kunjungan" list
— the shell tab is an explicit placeholder because no global clinical
workflow has been agreed.

## Form fields

Exactly the existing `IstoriaKlinis` model / backend domain:

- Data kunjungan (date picker, defaults to today) → `tanggal_kunjungan`
- S – Keluhan subjektivu → `keluhan_subjektif` (required)
- O – Pemeriksaan objetivu → `pemeriksaan_objektif` (required)
- A – Analiza no asesmentu → `analisis_asesmen` (required)
- P – Planu asaun → `rencana_tindakan` (required)
- Diagnoze / ICD-10 kode → `kode_icd10` (required)
- Naran moras lokal → `nama_penyakit_lokal` (required)

`tenant_id` comes from the authenticated session membership (never typed by
the user), matching the sync payload rules. `pasien_id` is the patient's
device-reserved identifier (`Pasien.remoteId`) — the same key the Phase 6
sync queue uses to order `PATIENT -> CLINICAL_VISIT` dependencies.

## Save path

```text
Validate → local Isar write + sync-queue entry (one transaction)
        → pushReplacement to Visit Detail
```

No API call on this phase. Offline, the visit stays `Pending` and is sent by
the existing SyncService when connectivity returns.

## History reads

`IstoriaRepository.history(pasienId)` is read-through: it tries the backend
first, caches the response in Isar, and falls back to the local store on
network failure **or 404** (a locally created patient is not yet known to the
server). The UI therefore always renders offline.

## States

- Loading: `Maka riwayat...`
- Empty: `Seidauk iha riwayat kunjungan.`
- Error: `Riwayat kunjungan la konsege maka.` (no raw exceptions)
- Save in progress disables the submit button (no double-submit).

## Known limitations

- Resep / Obat section on the profile is an explicit placeholder; no
  prescription UI in this phase (model/repository/sync layers exist from
  Phase 7).
- Visit edit/delete does not exist (matches the backend: no update endpoint).
- ICD-10 is free-text entry; no catalog lookup yet.
- History ordering uses `tanggalKunjungan` (newest first); visits created
  without that field sort to the end.
