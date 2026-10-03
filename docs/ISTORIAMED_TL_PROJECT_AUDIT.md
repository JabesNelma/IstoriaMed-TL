# IstoriaMed-TL
# Project Audit & Current State Report

Tanggal audit: 2026-10-03 · Mode: READ-ONLY (tidak ada source code, schema, migration, konfigurasi, atau dependensi yang diubah). Tes TIDAK dijalankan karena seluruh e2e suite melakukan `TRUNCATE`/seed terhadap test database (mutasi database) — sesuai aturan audit, hanya dilaporkan.

## 1. Executive Summary

IstoriaMed-TL adalah EMR open-source untuk Timor-Leste (Tetum UI), monorepo berisi backend NestJS 12 + TypeORM (dialek MySQL/TiDB) dan frontend Flutter (Android-first) dengan offline-first sync berbasis Isar. Status: **backend jauh lebih matang daripada frontend**. Backend memiliki identitas/tenant/fasilitas/staf, RBAC server-side nyata, isolasi `(facility_id, tenant_id)` yang kuat dan teruji, prescription + medication catalog, dan sync push-only yang idempoten. Frontend hanya punya 2 layar (registrasi pasien, istoria klinis), **tanpa login UI / penyimpanan token**, tanpa layar prescription, dan sync hanya CREATE/push-only. Satu pekerjaan tidak selesai (uncommitted) ada di working tree: domain **Tenant** (entity, migration `1710000007000`, module `api/admin/tenants`, tests) — progres.md mencatat Phase 8 BLOCKED di titik ini.

## 2. Project Identity

| Item | Nilai | Evidence |
|---|---|---|
| Nama | IstoriaMed-TL | README.md |
| Root | /home/jabesnelma/projetu/IstoriaMed-TL | — |
| Branch aktif | main (satu-satunya, origin/main) | git branch |
| Commit terakhir | `69e55b9` "hamos file nebe la importante" | git log |
| Working tree | **35 file dimodifikasi + 6 file baru TIDAK ter-commit** (tenant domain, setup-e2e-env) | git status |
| Backend | NestJS 12, TypeScript, TypeORM | src/backend/package.json |
| Frontend | Flutter (Dart) | src/frontend/pubspec.yaml |
| Database | Dialek **MySQL (mysql2, target TiDB)** di config runtime; test e2e memakai **PostgreSQL** disposable | src/backend/src/database/database.config.ts, test/setup-e2e-env.ts |
| ORM | TypeORM | src/database/ |
| Auth | JWT access-only (Bearer), argon2 | src/modules/auth/ |
| Testing | Jest (unit + e2e supertest); flutter_test | jest.config.ts, test/ |
| Package manager | npm (backend); pub (frontend) | package-lock.json |
| Struktur | Monorepo sederhana: `src/backend` + `src/frontend` | — |

## 3. Technology Stack

| Teknologi | Untuk apa | Bukti | Status |
|---|---|---|---|
| NestJS 12 | HTTP API | src/backend/src/main.ts, app.module.ts | IMPLEMENTED |
| TypeORM | ORM + migrations | src/database/* | IMPLEMENTED |
| argon2 | Password hashing | src/modules/auth/auth.service.ts | IMPLEMENTED |
| @nestjs/jwt | Access token 15m | src/modules/auth/auth.module.ts | IMPLEMENTED |
| class-validator/transformer | Validasi DTO global | main.ts ValidationPipe whitelist+forbidNonWhitelisted | IMPLEMENTED |
| mysql2 + pg | Driver DB | package.json | PARTIAL — config hardcode `mysql`, `pg` hanya untuk e2e; inkonsistensi dialek (lihat §25) |
| Flutter/Dart | Mobile app | src/frontend/lib/ | PARTIAL (2 layar) |
| Isar 3.1 | Local DB offline | pubspec.yaml, lib/data/local/local_database.dart | IMPLEMENTED |
| flutter_bloc | State management | lib/logic/pasien_bloc, istoria_bloc | IMPLEMENTED |
| Dio | HTTP client | lib/data/remote/api_client.dart | IMPLEMENTED |
| @nestjs/observe | — | tidak ada import di src | **TIDAK DIGUNAKAN** (dependensi mati) |
| helmet / @nestjs/throttler | — | tidak ada di package.json | NOT FOUND |

## 4. Project Structure

```text
IstoriaMed-TL/
├── README.md, prd.md, progres.md          # PRD & laporan progres fase (progres.md = sumber status fase)
├── docs/                                  # 11 dokumen arsitektur + phase-1..8 + laporan audit ini
└── src/
    ├── backend/
    │   ├── src/
    │   │   ├── main.ts                    # bootstrap, ValidationPipe global (tanpa CORS/helmet/throttler)
    │   │   ├── database/                  # config, data-source, 11 entities, 8 migrations
    │   │   └── modules/
    │   │       ├── auth/                  # register/login, AuthGuard, RolesGuard
    │   │       ├── pasien/                # pasien domain (Tetum naming)
    │   │       ├── istoria_klinis/        # clinical visit (SOAP + ICD-10)
    │   │       ├── prescription/          # prescriptions + medications
    │   │       ├── sync/                  # POST /api/sync/operations (push-only)
    │   │       └── tenant/                # BARU, belum ter-commit: api/admin/tenants
    │   └── test/                          # 8 e2e spec + setup-e2e-env.ts
    └── frontend/
        ├── lib/                           # app Flutter: 2 screens, blocs, repositories, Isar, sync engine
        └── test/                          # 6 test suite flutter (sync queue, prescription sync, acceptance)
```

## 5. Current Architecture

```text
Flutter (Android)                          NestJS API (:3000)
┌────────────────────────────┐             ┌──────────────────────────────────┐
│ UI: Register Pasien,       │   Dio       │ AuthGuard → RolesGuard → Service │
│ Istoria Klinis             │────────────▶│  /api/auth /pasien /istoria-     │
│ BLoC (pasien, istoria)     │             │   klinis /prescriptions          │
│ Repositories (read-through)│             │  /medications /sync /admin/*     │
│ Isar local DB              │             │  ownership dari JWT (server-     │
│  └ SyncQueue (PENDING→     │──push──────▶│  derived), predikat pasang       │
│    SYNCING→SYNCED/FAILED)  │             │  (facility_id, tenant_id)        │
└────────────────────────────┘             └───────────────┬──────────────────┘
                                                           ▼
                                              MySQL/TiDB (runtime) | PostgreSQL (e2e)
                                              11 tabel, FK RESTRICT, sync_operations
```

## 6. Database Architecture

- TypeORM, `synchronize: false`, `migrationsRun: false` — schema hanya berubah via `migration:run` eksplisit (src/database/database.config.ts).
- Migrations (8): patients+clinical_visits → widen MRN → users/facilities/facility_memberships/staff_profiles + patients.facility_id → visits.facility_id → sync_operations → medications/prescriptions/prescription_items → HardenDatabaseIntegrity (composite FK `(facility_id, tenant_id)`) → **CreateTenantDomain (baru, uncommitted: tabel `tenants`, tenant_id jadi FK)**.
- Semua FK `onDelete: RESTRICT` (tanpa cascade).
- Konfigurasi runtime: MySQL/TiDB via `DATABASE_URL`, SSL opsional (`DATABASE_SSL=true`).

## 7. Entity Inventory

| Entity | Tabel | Status | Purpose | Relations | Evidence |
|---|---|---|---|---|---|
| Patient | patients | Implemented | Data demografis pasien (no_ktp unique, MRN unique, fingerprint_hash) | facility_id → facilities | entities/patient.record.ts |
| ClinicalVisit | clinical_visits | Implemented | Kunjungan SOAP, kode_icd10, status_sinkronisasi | pasien_id→patients, facility_id→facilities, staf_id→staff_profiles | entities/clinical-visit.record.ts |
| User | users | Implemented | Login (login_identifier unique, password_hash select:false) | — | entities/user.record.ts |
| Facility | facilities | Implemented | Fasilitas kesehatan (facility_code unique) | tenant_id→tenants | entities/facility.record.ts |
| Tenant | tenants | Implemented (uncommitted) | Tenant natural-key slug | — | entities/tenant.record.ts, migration 1710000007000 |
| FacilityMembership | facility_memberships | Implemented | User↔Facility + role, unique (user,facility) | user_id, facility_id | entities/facility-membership.record.ts |
| StaffProfile | staff_profiles | Implemented | Profil medis (medical_license unique, verification_status) | user_id, facility_id | entities/staff.record.ts |
| Prescription | prescriptions | Implemented | Resep per visit | visit_id, prescribed_by_staff_id, facility+tenant | entities/prescription.record.ts |
| PrescriptionItem | prescription_items | Implemented | Item resep (dose/frequency/route/duration/quantity) | prescription_id, medication_id | entities/prescription-item.record.ts |
| Medication | medications | Implemented | Katalog obat GLOBAL (bukan per-tenant) | — | entities/medication.record.ts |
| SyncOperation | sync_operations | Implemented | Queue server-side: status PENDING/SYNCING/SYNCED/FAILED, retry_count, payload json | — | entities/sync-operation.record.ts |
| Allergy / Lab / Imaging / Referral / Appointment / Document / AuditLog | — | **NOT IMPLEMENTED** | — | — | tidak ditemukan |

## 8. Feature Inventory

| Feature | Status | Evidence | Notes |
|---|---|---|---|
| Patient registration | IMPLEMENTED (backend) | modules/pasien/pasien.service.ts; MRN server-side | UI ada (RegisterPasienScreen) tapi tanpa token auth |
| Patient identity (MRN, no_ktp unique) | IMPLEMENTED | patient.record.ts; database.e2e-spec | MRN = `MRN-<uuid>`, bukan penomoran sekuensial |
| Patient search/list/update | IMPLEMENTED (scoped) | pasien.service.ts findAll/findOneForUser | take(50); facility-scoped untuk non-admin |
| Facility + membership | IMPLEMENTED | migration 1710000002000 | — |
| Tenant domain | PARTIALLY IMPLEMENTED (uncommitted) | modules/tenant/, migration 1710000007000 | Admin CRUD tenant selesai + tests; progres.md: Phase 8 BLOCKED |
| Clinical visit (SOAP, ICD-10) | IMPLEMENTED | istoria_klinis module | Butuh staf berstatus Approved |
| Prescription + items | IMPLEMENTED | prescription module, prescription.e2e (~25 kasus) | Aggregate rollback transaksional |
| Medication catalog | IMPLEMENTED (backend) | medication module, admin-only create | Global, tidak tenant-scoped |
| RBAC | IMPLEMENTED (backend) | roles.guard.ts; 6 role: SUPER_ADMIN, SYSTEM_ADMIN, DOCTOR, NURSE, MIDWIFE, PHARMACY | PHARMACY diblokir dari endpoint klinis |
| Tenant/facility isolation | IMPLEMENTED | predikat exact-pair (facility,tenant) di visit/prescription; sync payload menolak field protected | Teruji di security.e2e & database-integrity.e2e |
| Cross-facility patient access | **NOT IMPLEMENTED** (untuk user facility-scoped) | pasien.service.ts: filter `facility_id IN (...)` | Hanya global admin yang lintas fasilitas (lihat §12) |
| Offline local storage | IMPLEMENTED | Isar, lib/data/local/ | 4 koleksi |
| Sync push (CREATE) | IMPLEMENTED | lib/core/sync/ + POST /api/sync/operations | Idempoten, dependency ordering, backoff |
| Sync pull / delta | NOT IMPLEMENTED | tidak ada GET sync endpoint | Baca data via read-through cache biasa |
| Offline auth (token persist, re-auth) | NOT IMPLEMENTED | ApiClient.setAccessToken tidak pernah dipanggil dari UI | 401 → operasi tetap queued |
| Login UI | NOT IMPLEMENTED | tidak ada login screen di lib/presentation | backend login endpoint ada |
| Prescription UI/BLoC | NOT IMPLEMENTED | prescription_repository.dart tanpa UI/BLoC | Sesuai catatan fase 7 |
| Fingerprint biometrik | NOT IMPLEMENTED (simulasi) | register_pasien_screen.dart `_scanFingerprint()` (hash in-memory) | PRD menyebut biometric engine — NOT FOUND |
| DHIS2/TLHIS integration | NOT IMPLEMENTED | tidak ditemukan | Requirement PRD |
| Audit log klinis | NOT IMPLEMENTED | tidak ada entity/Logger | sync_operations satu-satunya jejak operasi |
| Rate limiting / helmet / CORS | NOT IMPLEMENTED | main.ts, package.json | — |
| Password reset / logout / refresh token | NOT IMPLEMENTED | auth module | Access-only 15m |

## 9. Authentication

- Login: IMPLEMENTED — `POST /api/auth/register` & `/login`; argon2 hash/verify (auth.service.ts). Password min 12 char (RegisterUserDto).
- JWT access token 15 menit; JWT_SECRET wajib (throw saat startup jika kosong). TESTED (security.e2e-spec: hash check, password_hash absen dari response, token invalid/expired/inactive ditolak).
- Guard: custom AuthGuard; setiap request **membangun ulang memberships dari DB** (verifyPayload) dan menyaring user/tenant non-aktif — perubahan status langsung berlaku.
- Refresh token / logout / revocation / password reset: NOT FOUND. Risk: token 15m tamat = harus login ulang; tidak ada rotasi.
- Offline authentication: NOT IMPLEMENTED di app.

## 10. Authorization

Role aktual (facility-membership.record.ts): `SUPER_ADMIN, SYSTEM_ADMIN, DOCTOR, NURSE, MIDWIFE, PHARMACY`. Profesi staf: Doctor, Enfermeiru, Parteira, Farmasi.

- **Authorization backend NYATA**, bukan hanya UI: `RolesGuard` + `@Roles()` pada semua controller klinis/admin; PHARMACY dikecualikan dari registrasi pasien & endpoint klinis. TESTED (403 di prescription.e2e, security.e2e).
- Global admin (SUPER_ADMIN/SYSTEM_ADMIN) bypass facility scoping pada pasien (`isGlobalAdmin`); endpoint `/api/admin/*` (medications, tenants) admin-only.
- Facility boundary dari server: ownership selalu diturunkan dari JWT → memberships DB, tidak pernah dari body request. Client `tenant_id` yang tidak cocok → 403.

## 11. Facility / Tenant Boundary

Tenant architecture: **PRESENT (baru saja, uncommitted)** — `tenants` table, `facilities.tenant_id`, composite FK `(facility_id, tenant_id)` pada visits & prescriptions, module admin tenant.

- User → Facility: via `facility_memberships` (unique per user+facility, role per membership, is_active).
- Patient → Facility: `patients.facility_id` (nullable), ditetapkan server dari membership pembuat.
- Visit/Prescription → Facility+Tenant: disalin dari membership/visit, bukan dari client; sync payload menolak `facility_id/tenant_id/staf_id/prescribed_by_staff_id` (PROTECTED_PAYLOAD_FIELDS).
- Identifier tersebut **authoritative server-side**; field client hanya diterima jika identik dengan membership.
- Cross-facility dalam satu tenant tetap terisolasi (predikat exact-pair, bukan tenant-only).

## 12. Cross-Facility Patient Access

```text
CROSS-FACILITY PATIENT ACCESS
Status: NOT IMPLEMENTED untuk user facility-scoped; tersedia hanya bagi SUPER_ADMIN/SYSTEM_ADMIN.
Evidence: pasien.service.ts findAll/findOneForUser — filter `patient.facility_id IN (:...facilityIds)`
          untuk non-admin; tidak ada endpoint lookup pasien lintas fasilitas berbasis identifier global.
Current behavior: fasilitas hanya melihat pasien miliknya. MRN/no_ktp unik global, tetapi tidak dipakai
          untuk lookup lintas fasilitas oleh user biasa.
Limitation: core requirement PRD (pasien lintas RS masih harus diselesaikan; keputusan arsitektur
          tentang authorization lintas fasilitas belum ada — progres.md/docs tidak memuatnya).
```

## 13. Offline Capability

```text
Local Storage: IMPLEMENTED — Isar 3.1, DB "istoria_med", 4 koleksi (pasien, istoria, prescription, sync_operation).
Sync Queue:    IMPLEMENTED (push, CREATE saja) — entity + operation ditulis dalam satu Isar writeTxn; UUID kanonik
               di-reserve device dan diadopsi server (tanpa id-mapping).
Push:          IMPLEMENTED — POST /api/sync/operations; PENDING→SYNCING→SYNCED/FAILED; transient → retry
               backoff eksponensial 2s→60s; permanent (400/403/404/409) → FAILED; 401 → tetap queued.
Pull:          NOT IMPLEMENTED — hanya read-through cache per-request + fallback offline ke Isar.
Conflict Resolution: TIDAK ADA versi klasik — strategi server-authority: payload dibersihkan dari field
               server-owned; replay idempoten via operation_id.
Retry:         IMPLEMENTED — backoff, recovery operasi SYNCING yang terputus → PENDING, single-flight.
Idempotency:   IMPLEMENTED dua sisi — operationId UUID unik di klien; server PK claim + row lock +
               replay terminal outcome.
Current Limitation: CREATE-only (tidak ada UPDATE/DELETE), tanpa pull/delta, tanpa connectivity detection,
               tanpa background OS scheduler (trigger: startup, post-create, tombol manual), tanpa offline auth.
```

## 14. Synchronization

Server: satu endpoint `POST /api/sync/operations`; entity_type = PATIENT | CLINICAL_VISIT | PRESCRIPTION; claim + insert entity + hasil operasi dalam **satu transaksi DB**; entitas ditulis lewat service online yang sama (aturan otorisasi identik); unique violation → Conflict, FK violation → 404; kegagalan permanen dicatat FAILED dalam transaksi terpisah (tidak ada false-success saat rollback). Urutan dependency (pasien → visit → prescription) ditegakkan di klien. TESTED: sync.e2e (replay 2x/3x, ownership, DB-failure honesty) dan prescription.e2e (adopsi offline).

## 15. API Inventory

| Method | Path | Auth | Roles | Boundary | Test |
|---|---|---|---|---|---|
| POST | /api/auth/register | — (publik) | — | — | security.e2e |
| POST | /api/auth/login | — (publik) | — | — | security.e2e |
| POST | /api/pasien/register | ✔ | SA,SYSA,DR,NR,MW | facility dari membership | database.e2e |
| GET | /api/pasien (?q=) | ✔ | idem | facility-scoped | database.e2e |
| GET / PATCH | /api/pasien/:id | ✔ | idem | facility-scoped | database.e2e |
| POST | /api/istoria-klinis/create | ✔ | klinis | (facility,tenant) exact; staf Approved | sync/prescription e2e |
| GET | /api/istoria-klinis, /:id, /pasien/:pid, /tenant/:tid | ✔ | klinis | exact-pair | security.e2e |
| PATCH | /api/istoria-klinis/:id | ✔ | klinis | canAccessVisit | — |
| POST | /api/prescriptions | ✔ | klinis (no PHARMACY) | ownership dari visit | prescription.e2e |
| GET | /api/prescriptions, /visit/:visitId, /:id | ✔ | idem | inAuthorizedScope | prescription.e2e |
| GET | /api/medications, /:id | ✔ | klinis + PHARMACY | global | prescription.e2e |
| POST | /api/admin/medications | ✔ | SUPER_ADMIN, SYSTEM_ADMIN | — | prescription.e2e |
| POST | /api/sync/operations | ✔ | klinis | payload protected fields ditolak | sync.e2e |
| POST/GET/PATCH | /api/admin/tenants (+:id) | ✔ | SUPER_ADMIN, SYSTEM_ADMIN | — | tenant.e2e (uncommitted) |
| GET | / | ✖ | — | — | app.e2e |

Tidak ada secret/credential yang ditampilkan (lihat hanya .env.example untuk nama variabel; .env TIDAK dibaca).

## 16. Flutter / Frontend Inventory

| Screen/Feature | Exists | Connected to API | Offline | Tested |
|---|---|---|---|---|
| Home (2 tab, NavigationBar) | ✔ | — | — | widget_test (smoke) |
| Register Pasien (Tetum, fingerprint simulasi) | ✔ | ✔ (butuh token) | ✔ (Isar + queue) | sync_queue_test |
| Istoria Klinis (SOAP + ICD-10 + history) | ✔ | ✔ | ✔ | sync_queue_test |
| Status indicator (Pending/Synced/Failed) | ✔ | — | ✔ | ✔ |
| Manual sync button | ✔ | ✔ | ✔ | ✔ |
| Login | ✖ | login() ada di ApiClient tapi tak dipanggil | ✖ | — |
| Patient search screen | ✖ | repository ada | fallback lokal | — |
| Prescription UI/BLoC | ✖ | repository ada | ✔ (queue) | prescription_sync_test |
| Sync engine (queue, backoff, dependency, idempotency) | ✔ | ✔ | ✔ | ~50+ test |
| Error/loading/empty states | PARTIAL | — | — | — |

Acceptance evidence: `src/frontend/build/acceptance-evidence.json` — artefak acceptance run lintas-stack (chain PATIENT→VISIT→PRESCRIPTION tersinkron), tanpa timestamp/pass-fail.

## 17. Testing Status

TIDAK DIJALANKAN (read-only): semua e2e backend melakukan TRUNCATE + seed raw-SQL terhadap test DB (setup-e2e-env.ts) — mutasi database. Laporan inventaris saja:

- Backend e2e (8 spec, jest + supertest): app, database, database-integrity, security, sync, prescription (~25 kasus), tenant (uncommitted). Test DB: PostgreSQL disposable `127.0.0.1:5432/istoria_test`.
- Backend unit: spec di samping tiap service/controller.
- Flutter: 6 suite (sync_queue ~25 test, prescription_sync, sync_classification, api_exception, offline_acceptance [skip tanpa env], widget smoke).
- Environment dicatat, bukan hasil run: `TESTS RUN: NONE (read-only audit)`.

## 18. Security Status

| Area | Status | Evidence |
|---|---|---|
| Password hashing | IMPLEMENTED — argon2 | auth.service.ts; TESTED |
| Token expiration | IMPLEMENTED — 15m access-only | auth.module.ts |
| Input validation | IMPLEMENTED — ValidationPipe global whitelist+forbidNonWhitelisted, DTO lengkap | main.ts |
| SQL injection | PROTECTED — TypeORM parameterized; raw SQL hanya di test | — |
| Role/facility boundary | IMPLEMENTED backend, TESTED | roles.guard.ts, security.e2e |
| password_hash leakage | PROTECTED — select:false + toSafeUser; TESTED | user.record.ts |
| fingerprint_hash exposure | GAP — dikembalikan dalam response pasien | pasien.service.ts toEntity |
| CORS / helmet / rate limiting | NOT FOUND | main.ts, package.json |
| Audit logging | NOT FOUND (tidak ada Logger sama sekali) | — |
| Secrets handling | .env ada di working tree (TIDAK dibaca); JWT_SECRET wajib ada | .env.example |
| JWT_SECRET strength validation | NOT FOUND (hanya kehadiran yang dicek) | auth.module.ts |

## 19. Documentation Status

Dokumen: README (2 baris), prd.md, progres.md, docs/ (11 file: audit awal, phase-1..8, database-architecture, authentication-authorization, patient-domain-architecture).

Akurasi: dokumentasi fase **konsisten dengan kode** (langka dan patut dicatat): phase-6 doc cocok dengan sync engine; fase 7 jujur "repository & sync layer only, tanpa UI"; fase 8 BLOCKED di tenant FK. Ketidakakuratan/stale:
1. `database-architecture.md` masih mengatakan "staf_id nullable karena tabel auth/staf belum ada" — stale sejak Phase 3.
2. `phase-6-offline-sync.md` & komentar `sync_types.dart`/`sync_operation_schema.dart` menyebut entityType hanya PATIENT/CLINICAL_VISIT — kode sudah mendukung PRESCRIPTION.
3. PRD vs implementasi: biometrik, DHIS2/TLHIS, RBAC pasien, penamaan tabel PRD (`staf_medis_peran`, `resep_obat`) — belum diimplementasi; dokumentasi deferred list jujur soal ini.

## 20. Git / Development History

7 commit: setup → ilustrasi/logika → auth+domain pasien (`bfc048f`) → offline (`b88bcec`) → fitur (`690a84`) → pembersihan (`69e55b9`). **Unfinished work di working tree (uncommitted, 35 modified + 6 baru, +495/−175): domain Tenant penuh** (entity, migration 1710000007000, module, e2e, setup-e2e-env) — cocok dengan progres.md Phase 8 BLOCKED. Tidak ada branch lain.

## 21. Current Project Phase

Struktur fase formal ADA: progres.md + docs/phase-1..8.

```text
Phase 1 Foundation                    COMPLETE (docs/phase-1)
Phase 2 Database Persistence          COMPLETE (docs/phase-2)
Phase 3 Authentication/Users/Facility COMPLETE (docs/phase-3)
Phase 4 Patient Domain                COMPLETE (docs/phase-4)
Phase 5 Clinical Visit Domain         COMPLETE (docs/phase-5)
Phase 6 Offline Sync                  COMPLETE (docs/phase-6)
Phase 7 Prescription/Medication       COMPLETE (+ audit 7.1, docs/phase-7)
Phase 8 Database Integrity/Tenant     PARTIAL — progres.md: BLOCKED; Goals A & C selesai,
                                      tenant domain dikerjakan di working tree (uncommitted)
```

AUDITOR INTERPRETATION (bukan fakta resmi): proyek berada di akhir Phase 8; pekerjaan berikutnya yang paling wajar adalah menuntaskan & meng-commit tenant domain, lalu keputusan arsitektur cross-facility access dan auth frontend.

## 22. Confirmed Working Features

1. Auth (register/login, argon2, JWT 15m, inactive-user rejection) — Evidence: auth module; Test: security.e2e-spec. Status: CONFIRMED (via test suite, tidak dijalankan ulang).
2. Patient domain scoped CRUD — Test: database.e2e. CONFIRMED.
3. Clinical visit SOAP dengan exact-pair isolation — Test: security.e2e, sync.e2e. CONFIRMED.
4. Prescription aggregate + katalog obat — Test: prescription.e2e (~25 kasus). CONFIRMED.
5. Sync push idempoten lintas-stack — Test: sync.e2e + prescription_sync_test + acceptance-evidence.json. CONFIRMED.
6. Offline queue klien (atomik, dependency, backoff, recovery) — Test: sync_queue_test (~25 test). CONFIRMED.
7. Tenant admin CRUD + suspensi mencabut membership — Test: tenant.e2e. CONFIRMED (kode uncommitted).

## 23. Partially Implemented Features

1. **Tenant domain** — Exists: entity/migration/module/tests. Missing: commit, keputusan final Phase 8. Risk: working tree besar belum ter-commit mudah hilang/tercampur.
2. **Frontend app** — Exists: 2 layar + sync engine lengkap. Missing: login UI, token storage, prescription UI, patient search UI, loading/empty states menyeluruh. Risk: **app berjalan tanpa token → semua request API ditolak 401; operasi offline menumpuk selamanya**.
3. **Offline sync** — Exists: push CREATE idempoten. Missing: UPDATE/DELETE, pull/delta, offline auth. Risk: data lama tidak pernah ter-update di perangkat lain.
4. **Dukungan DB ganda** — Exists: config mysql + dependensi pg + e2e postgres. Missing: resolusi dialek tunggal. Risk: runtime vs test divergen.
5. **Security hardening** — Exists: argon2, validasi, RBAC. Missing: CORS, helmet, rate limit, audit log.

## 24. Missing Features (NOT YET IMPLEMENTED)

Critical (security / architectural necessity):
- Cross-facility patient access (core requirement, keputusan arsitektur dibutuhkan)
- Login UI + penyimpanan token + re-auth offline (tanpa ini frontend tidak berfungsi terhadap backend sekarang)
- CORS/helmet/rate-limiting; audit log klinis; resolusi dialek DB
- Menuntaskan Phase 8 tenant (commit)

Important (stated requirements / dependency):
- Sync UPDATE/DELETE + pull/delta; offline authentication
- Prescription UI & BLoC; patient search UI
- Fingerprint biometrik nyata (PRD); verifikasi otoritas (PRD)

Later (PRD, belum ada dependensi implementasi):
- DHIS2/TLHIS integration; Laboratory; Imaging; Referral; Appointment; Documents; Allergy; password reset/refresh token; Swagger/API docs; peran PASIEN (portal pasien)

## 25. Architecture Risks

1. **Dialect mismatch MySQL vs PostgreSQL** — Evidence: database.config.ts (`type:'mysql'`) vs test/setup-e2e-env.ts (postgres URL, placeholder `$1`). Impact: test e2e tidak membuktikan path runtime; `pg` di runtime dead. Why: keputusan produksi (TiDB?) belum dituangkan konsisten.
2. **Frontend tanpa auth flow** — Evidence: `setAccessToken` tidak pernah dipanggil dari lib/. Impact: 401 massal; queue menumpuk; UX offline-first gagal secara end-to-end.
3. **Working tree besar uncommitted** — Evidence: git status 41 file. Impact: risiko kehilangan; audit baseline meliputi kode yang belum masuk history.
4. **No transport hardening** — Evidence: main.ts tanpa CORS/helmet/throttler. Impact: eksposur di deployment publik.
5. **fingerprint_hash diekspos** — Evidence: pasien.service.ts toEntity. Impact: data biometrik-hash terbaca pembaca ter-scope.
6. **No audit trail** — Evidence: tidak ada entity/Logger. Impact: EMR tanpa jejak akses/mutasi klinis.
7. **Access-only JWT tanpa revocation** — Impact: token curian valid sampai 15m; tidak ada mekanisme logout server.

## 26. DO NOT CHANGE YET

- Migration history & skema existing (termasuk migration 1710000007000 yang uncommitted — jangan diedit, putuskan commit/review dulu)
- Predikat exact-pair `(facility_id, tenant_id)` di visit/prescription (hasil perbaikan kebocoran OR yang terdokumentasi)
- Alur ownership server-derived (verifyPayload → memberships)
- Arsitektur sync (idempotency PK + single transaction) di kedua sisi
- Konvensi penamaan Tetum domain (pasien, istoria klinis)
- Isar schema koleksi klien (ada data device yang mengandalkannya)

## 27. Suggested Discussion Roadmap (proposal diskusi, bukan instruksi coding)

- Phase A — Tenant selesai: review & commit working tree, tutup Phase 8.
- Phase B — Auth frontend: login UI, token storage aman, re-auth, sehingga app benar-benar end-to-end.
- Phase C — Keputusan & implementasi cross-facility patient access (identifier global + authorization).
- Phase D — Security hardening: CORS/helmet/rate limit, audit log, refresh/revocation, dialek DB tunggal.
- Phase E — Offline sync lengkap: UPDATE/DELETE, pull/delta, konflik.
- Phase F — Fitur klinis lanjut: prescription UI, search UI, lab/imaging/referral sesuai PRD.

## 28. Questions / Decisions Required

1. Database produksi final: MySQL/TiDB atau PostgreSQL? (mismatch config vs test harus diselesaikan)
2. Model authorization cross-facility: siapa boleh melihat pasien fasilitas lain, dan berdasarkan apa (break-the-glass, consent, per-tenant policy)?
3. MRN: tetap UUID acak atau penomoran nasional/terstruktur?
4. Strategi sync pull/delta & resolusi konflik untuk UPDATE/DELETE.
5. Penyimpanan token di perangkat (secure storage mana) dan masa pakai sesi offline.
6. Status Phase 8: apakah working tree tenant sudah final dan siap commit?
7. Kebutuhan audit log (format, retensi) untuk EMR.

## 29. Final Audit Conclusion

Baseline kondisi nyata: backend solid dan teruji (identity, RBAC, tenant isolation, prescription, sync idempoten), frontend punya sync engine kelas satu tetapi belum bisa dipakai end-to-end (tanpa login/token), core requirement cross-facility access belum ada, dan Phase 8 (tenant) berada di working tree yang belum di-commit. Semua klaim di atas berbasis evidence file-path; hal yang tidak ditemukan dilaporkan NOT FOUND, bukan diasumsikan.

---
FILES ANALYZED: struktur repo, git history/status, 11 entities, 8 migrations, 6 modul backend + guards/DTOs, 8 e2e spec + setup, pubspec + seluruh lib/ Flutter + 6 test suite, README/prd/progres + 11 dokumen docs/.
TESTS RUN: NONE (read-only; e2e memutasi test database).
FILES CHANGED: ONLY docs/ISTORIAMED_TL_PROJECT_AUDIT.md.
SOURCE CODE CHANGED: NO · DATABASE CHANGED: NO · MIGRATIONS CHANGED: NO · CONFIGURATION CHANGED: NO.
