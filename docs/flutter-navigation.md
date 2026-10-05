# Flutter APK Navigation — Current State

Terakhir diperbarui: 2026-10-03 (fase APK UI Foundation).

## Flow navigasi aktual (yang benar-benar sudah dibuat)

```text
APP START
   ↓
Splash (/splash)            ← cek session lokal (Isar), TIDAK ada API call
   ↓
   ├── belum login  → Login (/login)
   ├── session ada  → Role Router (berdasarkan role dari memberships)
   │                    ├── DOCTOR / NURSE / MIDWIFE / PHARMACY → Staff Shell (/staff)
   │                    ├── PATIENT                              → Patient Shell (/patient)
   │                    └── role lain (mis. SUPER_ADMIN)         → Unsupported Role (/unsupported-role)
   └── (fallback timer 4 detik → Login, mencegah infinite splash)
```

## Routing

Satu sistem routing: **named routes** di `MaterialApp.routes` (lib/app.dart).
Tidak ada GoRouter/auto_route/Navigator 2.0 — tidak ada alasan mengganti.

| Route | Screen | Akses |
|---|---|---|
| `/splash` | `SplashScreen` | publik (entry point) |
| `/login` | `LoginScreen` | publik |
| `/staff` | `StaffShell` | terproteksi (guard) |
| `/patient` | `PatientShell` | terproteksi (guard) |
| `/unsupported-role` | `UnsupportedRoleScreen` | sesi valid, role tidak didukung APK |

Guard: `AuthGuardListener` (lib/presentation/shell/auth_guard_listener.dart) membungkus
kedua shell. Setiap kali state `AuthBloc` keluar dari AUTHENTICATED (logout), navigasi
`pushNamedAndRemoveUntil('/login')` membersihkan seluruh stack, sehingga tombol back
tidak bisa kembali ke halaman terautentikasi.

## Session

- `AuthSession` (lib/data/session/auth_session.dart): dibangun persis dari response
  `POST /api/auth/login` yang ada (`access_token`, `user.user_id`, `user.login_identifier`,
  `user.memberships[{facility_id, tenant_id, role}]`). Tidak ada role yang dikarang.
- Penyimpanan: koleksi Isar `AppSession_2026_10_03` (satu baris) via `SessionStore`.
  **Catatan keamanan**: token tersimpan di database Isar milik aplikasi (app-private),
  bukan secure storage terenkripsi (flutter_secure_storage belum menjadi dependency
  proyek). Ini keterbatasan yang diketahui.
- Token dipasang ke `ApiClient.setAccessToken()` yang sudah ada; logout memanggil
  `clearAccessToken()` + hapus baris session.
- `AuthBloc` (lib/logic/auth_bloc/): `UNKNOWN → AUTHENTICATED / UNAUTHENTICATED`,
  plus state `Authenticating` (button disabled) dan `LoginFailure` (pesan manusiawi;
  tidak ada stack trace/JWT/raw exception di UI).

## Shell

- **StaffShell** (`/staff`): bottom nav Beranda | Pasien | Sync | Profil (4 tab).
  Kunjungan dan resep tidak punya tab sendiri — keduanya selalu dibuka dari
  konteks pasien (Pasien -> Profil Pasien -> Kunjungan Foun / Riwayat Kunjungan
  -> Detalhu Kunjungan -> Rese Foun), sehingga tidak ada menu untuk fitur yang
  tidak berdiri sendiri. Sync memakai `SyncService.syncPending()` existing.
- **PatientShell** (`/patient`): bottom nav Beranda | Riwayat | Resep | Profil.
  Semua halaman placeholder eksplisit — backend belum menerbitkan role PATIENT,
  jadi shell ini belum terjangkau lewat login nyata; routing-nya siap untuk nanti.

## Mode Preview (DEV ONLY)

`lib/data/session/demo_mode.dart` memuat `kDemoMode = true` (dev-only). Saat aktif,
halaman login menampilkan dua tombol di bagian bawah: **"Lihat UI Staf"** dan
**"Lihat UI Pasien"**. Tombol ini masuk ke shell masing-masing memakai sesi sintetis
(`AuthSession.demo()`): tidak memanggil backend, tidak menyimpan apa pun ke Isar,
logout hanya kembali ke login. Set `kDemoMode = false` (atau hapus branch demo di
`LoginScreen`/`AuthBloc`) sebelum deployment nyata. Catatan: dalam mode preview,
panggilan data nyata (mis. registrasi pasien) tetap akan ditolak backend karena
tidak membawa token — yang bisa dinilai hanya tampilan, navigasi, dan state UI.

## Yang BELUM dibuat (jangan dianggap selesai)

- Validasi token ke server saat splash (splash hanya membaca session lokal; token
  expired 15 menit baru terasa saat request API ditolak — belum ada re-auth flow).
- Pembatasan menu per role di dalam staff shell (semua role staf melihat shell sama).
- Reset password (tombol "Lupa password?" menampilkan pesan bahwa fitur belum ada).

## Test

`test/auth_flow_test.dart` mencakup: fresh app → login; login staff → staff home;
session tersimpan → langsung staff home; login pasien → patient home; logout →
login (stack bersih); login invalid → error, tetap di login; role tidak dikenal →
layar error aman.
