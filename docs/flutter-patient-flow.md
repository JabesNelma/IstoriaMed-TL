# Flutter Patient Flow (APK)

Status: **FRONTEND / LOCAL-FIRST — backend integration NOT completed.**

Phase: FRONTEND PHASE 2 — PATIENT MANAGEMENT (2026-10-04).

## Flow

```text
STAFF SHELL (bottom nav: Beranda | Pasien | Kunjungan | Sync | Profil)
  ↓ tab "Pasien"
PASIEN LIST (PasienListScreen)
  ├── search (nama / MRN / KTP, case-insensitive, local Isar only)
  ├── +  →  REGISTRATION (RegisterPasienScreen)
  │            ↓ save (local, queued for sync)
  │         PATIENT PROFILE (pushReplacement)
  └── tap patient → PATIENT PROFILE
                      ↓
                 + Kunjungan Baru → Clinical Visit Form (see
                   flutter-clinical-visit-flow.md)
                 Riwayat Kunjungan → Visit History → Visit Detail
```

## States

- Loading: `Maka dadus pasiente...`
- Empty: `Seidauk iha dadus pasiente.`
- Search empty: `La hetan pasiente ho lian neba.`
- Error: `Dadus pasiente la konsege maka.` (shown inline, no raw exceptions)

## Architecture

```text
UI (PasienListScreen / RegisterPasienScreen / PasienProfileScreen)
 ↓
PasienBloc (LoadPasienList / RegisterPasien / SyncPendingPasien)
 ↓
PasienRepository (findAll(query) — local only; register — offline-first)
 ↓
Isar `Pasien_538` + SyncQueue (single Phase 6 synchronization pathway)
```

`findAll()` is deliberately local-only: the patient list works with no
connectivity. The online read-through (`searchRemote`) still exists in the
repository for a later online catalogue phase; it is not wired to the list UI.

## Registration

- Fields are exactly the existing `Pasien` model fields: Numeru KTP, naran
  kompletu, fatin moris, data moris (date picker), jéneru, fingerprint
  simulation. No invented fields — the model has no address/phone, so the UI
  asks for none.
- Validation: required fields, birth date mandatory.
- Duplicate KTP is rejected against the local store
  (`DuplicatePasienException`); server-side uniqueness remains a backend
  responsibility.
- Save path: validate → local Isar write + sync-queue entry (one transaction)
  → `pushReplacement` to Patient Profile. No API call.

## Local MRN placeholder

`nextLocalMrn()` in `lib/repositories/pasien_repository.dart` generates
`MRN-LOCAL-XXXXXXXX` for display only. The server owns the authoritative MRN
(it is never part of the sync payload); after the first successful
synchronization the server-assigned value overwrites the local placeholder.
This is NOT an official national MRN.

## Demo data

`lib/data/local/demo_seed.dart` seeds 3 synthetic patients (names suffixed
`(DEMO)`) and 3 visits when `kDemoMode` is enabled and the store is empty.
It runs only from `main()`, writes no sync-queue entries, and must be turned
off before real deployment.

## Known limitations

- Patient model has no contact fields (address/phone) — no contact section is
  shown rather than inventing data.
- Patient update/delete UI does not exist yet.
- Offline search covers only local records; remote catalogue search is a
  later phase.
