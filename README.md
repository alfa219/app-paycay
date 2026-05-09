# PAYCAY Mobile — Smart EV Charging Station App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.19+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-Auth_|_Firestore_|_RTDB_|_FCM-FFA000?style=for-the-badge&logo=firebase&logoColor=white" alt="Firebase">
  <img src="https://img.shields.io/badge/Riverpod-2.x-blue?style=for-the-badge&logo=dart&logoColor=white" alt="Riverpod">
  <img src="https://img.shields.io/badge/Platform-Android_|_iOS-green?style=for-the-badge&logo=android&logoColor=white" alt="Platform">
</p>

<p align="center">
  <b>Aplikasi mobile manajemen Stasiun Pengisian Kendaraan Listrik (SPKLU)</b><br>
  <i>Real-time charging monitoring · digital wallet · admin panel</i>
</p>

---

## Daftar Isi

- [Tentang Project](#tentang-project)
- [Fitur Utama](#fitur-utama)
- [Arsitektur](#arsitektur)
- [Tech Stack](#tech-stack)
- [Struktur Folder](#struktur-folder)
- [Skema Data](#skema-data)
- [Instalasi & Setup](#instalasi--setup)
- [Konfigurasi Firebase](#konfigurasi-firebase)
- [Menjalankan Aplikasi](#menjalankan-aplikasi)
- [Testing Flow](#testing-flow)
- [Roadmap](#roadmap)
- [Kontributor](#kontributor)

---

## Tentang Project

**PAYCAY** adalah aplikasi mobile berbasis Flutter untuk mengelola Stasiun Pengisian Kendaraan Listrik Umum (SPKLU). Aplikasi terdiri dari **dua sisi pengguna**:

- **User** — mencari stasiun, memulai sesi pengisian, monitor sensor real-time (volt/ampere/watt/kWh), top-up saldo, lihat riwayat transaksi
- **Admin** — monitor seluruh stasiun secara live, approve/reject request top-up, kelola status stasiun

Aplikasi terhubung ke perangkat **ESP32** (yang membaca sensor PZEM-004T dan mengontrol relay AC) melalui **Firebase Realtime Database** sebagai message broker — menggantikan kebutuhan koneksi Bluetooth atau WiFi direct.

> 💡 **Untuk fase development saat ini, sensor ESP32 disimulasikan langsung di app.** Saat hardware ESP32 siap, simulator tinggal dimatikan dan ESP32 mengambil alih penulisan data sensor ke RTDB — tidak perlu ubah UI.

---

## Fitur Utama

### Untuk User

| Fitur | Status | Detail |
|-------|--------|--------|
| Register / Login / Logout | ✅ | Firebase Auth (Email + Password) |
| Forgot Password | ✅ | Reset link via email |
| Dashboard | ✅ | Saldo, stasiun terdekat, aktivitas terbaru, banner sesi aktif |
| Peta Stasiun | ✅ | Custom marker per status, search, filter |
| Cari Stasiun via Kode | ✅ | Input kode `STN###` manual |
| Mulai Pengisian | ✅ | Validasi saldo & status stasiun |
| Live Charging Monitor | ✅ | Volt, Ampere, Watt, kWh update tiap 2 detik |
| Hitung Biaya Real-time | ✅ | `kWh × tariff` per stasiun |
| Auto-stop Saldo Habis | ✅ | Sesi otomatis berhenti saat cost ≥ balance |
| Resume Charging Session | ✅ | Sesi tetap aktif kalau app ditutup, banner di dashboard |
| Struk Digital | ✅ | Receipt detail per sesi |
| Top-up Saldo | ✅ | BCA VA / GoPay / OVO (otomatis) atau Mandiri (manual approval) |
| Riwayat Transaksi | ✅ | Filter per tipe, group per bulan |
| Pull-to-Refresh | ✅ | Dashboard, History, Wallet |

### Untuk Admin

| Fitur | Status | Detail |
|-------|--------|--------|
| Admin Dashboard | ✅ | Stat cards (total stasiun, available, charging, offline, pending top-up) |
| Approval Top-up | ✅ | Setujui / tolak request manual per item |
| Manajemen Stasiun | ✅ | Ubah status (available/charging/offline/maintenance) per stasiun |
| Live Station Monitoring | ✅ | List status real-time semua stasiun |

---

## Arsitektur

```
┌──────────────────────────────────────────────────────────────────────┐
│                          MOBILE APP LAYER                            │
│                                                                      │
│  ┌─────────────────┐              ┌─────────────────┐               │
│  │  User           │              │  Admin          │               │
│  │  ─────────────  │              │  ─────────────  │               │
│  │  • Live Monitor │              │  • Top-up Appr. │               │
│  │  • Top-up       │              │  • Station Mgmt │               │
│  │  • History      │              │  • Dashboard    │               │
│  └────────┬────────┘              └────────┬────────┘               │
└───────────┼────────────────────────────────┼────────────────────────┘
            │                                 │
            ▼                                 ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         BACKEND LAYER (Firebase)                     │
│  ┌─────────────────────────┐    ┌────────────────────────┐          │
│  │  Firebase Auth          │    │  Cloud Firestore       │          │
│  │  • Email/Password       │    │  • users               │          │
│  │  • Token persistence    │    │  • stations            │          │
│  └─────────────────────────┘    │  • transactions        │          │
│                                  │  • topupRequests       │          │
│  ┌─────────────────────────┐    └────────────────────────┘          │
│  │  Realtime Database      │                                         │
│  │  • Live sensor data     │                                         │
│  │  • Commands (start/stop)│                                         │
│  │  • Active session state │                                         │
│  └─────────────────────────┘                                         │
└──────────────────────────────────────────────────────────────────────┘
            │ RTDB Listener (saat ESP32 siap)
            ▼
┌──────────────────────────────────────────────────────────────────────┐
│                       HARDWARE LAYER (Future)                        │
│  ┌──────────────────────────────────────────────┐                    │
│  │               ESP32 DevKit V1                │                    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐     │                    │
│  │  │ PZEM-004T│ │ RC522    │ │ LCD 16x2 │     │                    │
│  │  │ (V,I,P,E)│ │ (RFID)   │ │ (Display)│     │                    │
│  │  └──────────┘ └──────────┘ └──────────┘     │                    │
│  │  ┌──────────┐                                │                    │
│  │  │  Relay   │ ← Kontrol Daya AC              │                    │
│  │  └──────────┘                                │                    │
│  └──────────────────────────────────────────────┘                    │
└──────────────────────────────────────────────────────────────────────┘
```

### Clean Architecture

```
Presentation (Riverpod + UI) → Services (Auth, Firestore, RTDB, Charging, Topup) → Firebase SDKs
```

State management menggunakan **Riverpod 2.x** dengan pattern:
- `Provider<Service>` — instance dependency injection
- `StreamProvider` — real-time data dari Firestore/RTDB
- `StateNotifierProvider` — local persistent state (active session via SharedPreferences)

---

## Tech Stack

### Core
- **Flutter** 3.19+
- **Dart** 3.3+

### State Management & Navigation
- `flutter_riverpod` ^2.5
- `go_router` ^13.2

### Backend
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_database` (Realtime DB untuk sensor)
- `firebase_messaging` (FCM, dipersiapkan untuk push notif)

### UI & Utilities
- `google_fonts` — typography
- `intl` — localization (Indonesian)
- `shared_preferences` — persist active session

---

## Struktur Folder

```
charger/
├── lib/
│   ├── main.dart                          # Entry: Firebase init + locale + prefs
│   ├── app.dart                           # MaterialApp + GoRouter
│   ├── firebase_options.dart              #  Generated, gitignored
│   │
│   ├── core/
│   │   ├── constants/                     # Colors, sizes
│   │   ├── theme/                         # AppTheme, TextStyles
│   │   ├── utils/                         # Formatters (currency, date, duration)
│   │   └── widgets/                       # Reusable: ShimmerBox, EmptyState, etc.
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart            # fromFirestore + toFirestore
│   │   │   ├── station_model.dart
│   │   │   ├── sensor_data_model.dart     # RTDB sensor
│   │   │   └── transaction_model.dart
│   │   ├── constants/
│   │   │   └── topup_methods.dart         # BCA, Mandiri, GoPay, OVO, RFID
│   │   └── services/
│   │       ├── auth_service.dart          # Firebase Auth wrapper
│   │       ├── user_service.dart          # users CRUD + atomic balance txn
│   │       ├── station_service.dart       # stations CRUD + auto-seed
│   │       ├── rtdb_service.dart          # Realtime DB wrapper
│   │       ├── charging_service.dart      # Session lifecycle + simulator
│   │       └── topup_service.dart         # Top-up + admin approval
│   │
│   ├── features/
│   │   ├── auth/                          # Splash, landing, login, register, forgot
│   │   ├── dashboard/                     # User home dashboard
│   │   ├── stations/                      # Map page + providers
│   │   ├── charging/                      # Session page + receipt + scan
│   │   ├── wallet/                        # Wallet, top-up flow
│   │   ├── history/                       # Transaction history
│   │   ├── profile/                       # Profile + Dev Tools + Admin entry
│   │   ├── admin/                         # Admin Panel (3 tabs)
│   │   └── shell/                         # Bottom nav shell
│   │
│   └── router/
│       ├── app_router.dart                # GoRouter config
│       └── route_names.dart
│
├── android/                               # Android platform config
├── ios/                                   # iOS platform config
├── pubspec.yaml                           # Dependencies
├── PAYCAY_FLUTTER.md                      # Detailed design document (lengkap)
└── README.md                              # File ini
```

---

## Skema Data

### Cloud Firestore

```
users/{uid}
  ├─ name: string
  ├─ firstName: string
  ├─ email: string
  ├─ phone: string
  ├─ balance: number
  ├─ rfid: string
  ├─ role: "user" | "admin"
  └─ createdAt: timestamp

stations/{stationId}      # ID format: STN001, STN002, ...
  ├─ slot: string         # "Slot A"
  ├─ address: string
  ├─ distance: string     # "0.3 km"
  ├─ tariff: number       # Rp per kWh
  ├─ status: "available" | "charging" | "offline" | "maintenance"
  ├─ maxKw: number
  ├─ posX: number         # Marker position 0-100 (UI map)
  └─ posY: number

transactions/{txId}
  ├─ userId: string
  ├─ type: "charging" | "topup"
  ├─ label: string
  ├─ sub: string
  ├─ amount: number       # negative for cost, positive for top-up
  ├─ status: "success"
  ├─ balanceBefore: number
  ├─ balanceAfter: number
  ├─ sessionId: string?   # untuk charging
  ├─ stationId: string?
  ├─ energyKwh: number?
  ├─ durationSeconds: number?
  ├─ methodId: string?    # untuk topup
  └─ createdAt: timestamp

topupRequests/{requestId}
  ├─ userId: string
  ├─ amount: number
  ├─ methodId, methodName, methodKind, fee, total
  ├─ status: "pending" | "approved" | "rejected" | "failed"
  ├─ autoApproved: boolean
  ├─ transactionId: string?
  ├─ rejectionReason: string?
  ├─ requestedAt: timestamp
  ├─ processedAt: timestamp?
  └─ processedBy: string?  # admin uid
```

### Realtime Database

```
stations/{stationId}/
  ├─ sensor:
  │   ├─ voltage: number       # ~220 V
  │   ├─ current: number       # 0-5.2 A
  │   ├─ power: number         # voltage × current
  │   ├─ energyKwh: number     # accumulated
  │   └─ updatedAt: timestamp
  ├─ currentSession: string?
  └─ lastSeen: timestamp

commands/{stationId}
  ├─ action: "start" | "stop"
  ├─ userId: string
  ├─ sessionId: string
  └─ timestamp: timestamp
```

---

## Instalasi & Setup

### Prerequisites

- Flutter SDK 3.19.0 atau lebih tinggi (`flutter doctor`)
- Dart 3.3.0+
- Android Studio atau VS Code dengan Flutter extension
- Android Emulator atau HP Android dengan Developer Mode
- Akun Firebase aktif

### Clone & Install

```bash
git clone https://github.com/alfa219/app-paycay.git
cd app-paycay
flutter pub get
```

### Install Firebase CLI Tools

```bash
# Node.js (jika belum ada): https://nodejs.org

npm install -g firebase-tools
firebase login

dart pub global activate flutterfire_cli
```

> **Windows users:** kalau `flutterfire` tidak dikenali, tambahkan path ke environment variable:
> ```
> C:\Users\<USER>\AppData\Local\Pub\Cache\bin
> ```

---

## Konfigurasi Firebase

 **File `lib/firebase_options.dart`, `google-services.json`, dan `GoogleService-Info.plist` tidak di-commit** — Anda perlu generate sendiri.

### 1. Buat Firebase Project

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Klik **Add Project** → kasih nama (misal `paycay-mobile`)
3. (Opsional) Skip Google Analytics

### 2. Aktifkan Services

| Service | Setup |
|---------|-------|
| **Authentication** | Build → Authentication → Sign-in method → Enable **Email/Password** |
| **Realtime Database** | Build → Realtime Database → Create → Region **asia-southeast1** → **Test mode** |
| **Firestore Database** | Build → Firestore → Create → Region **asia-southeast2** → **Test mode** |
| **Cloud Messaging** | Auto-aktif |

>  Storage di-skip — perlu upgrade Blaze plan.

### 3. Generate Config Files

Dari folder project:

```bash
flutterfire configure
```

Ikuti prompt:
- Pilih project Firebase Anda
- Centang platform: **android**, **ios**
- Application ID: `com.paycay.mobile` (atau bebas)

File yang akan ter-generate:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

---

## Menjalankan Aplikasi

```bash
# Pastikan emulator Android atau HP fisik terhubung
flutter devices

# Run
flutter run

# Hot reload: tekan r
# Hot restart: tekan R
# Quit: tekan q
```

### Build Release

```bash
# APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release

# iOS (Mac only)
flutter build ipa --release
```

---

## Testing Flow

### Setup Awal (One-time)

1. **Register akun** baru via app
2. **Top-up saldo manual** via Firestore Console:
   - Firestore → `users/{uid}` → field `balance` → ubah ke `100000`
3. **Seed sample stations**: di dashboard → klik tombol **"Seed"** di empty state stasiun terdekat
4. **(Optional) Promote ke admin**: Firestore → `users/{uid}` → field `role` → ubah ke `admin`

### Test Charging Flow

1. Dashboard → klik salah satu station yang status `available`
2. Bottom sheet → **"Mulai Pengisian"**
3. Sensor card update tiap 2 detik (volt, ampere, watt, kWh)
4. Cost real-time = `energyKwh × tariff`
5. Klik **"Hentikan Pengisian"** → konfirmasi → receipt

### Test Resume Session

1. Mulai charging → sambil aktif, **kill app** dari recent apps
2. Buka app lagi → splash → dashboard
3. ✅ Banner **"Sedang Mengisi"** otomatis muncul
4. Tap banner → kembali ke charging page dengan elapsed time terlanjut

### Test Auto-stop Saldo Habis

1. Set saldo ke nilai kecil (misal `100`) via Console
2. Mulai charging
3. Tunggu sampai cost ≥ 100 → ✅ snackbar kuning + auto navigate ke receipt

### Test Top-up

**Auto (BCA VA, GoPay, OVO):**
- Wallet → Top Up → 50000 → BCA Virtual Account → "Saya Sudah Bayar"
- ✅ Saldo bertambah langsung

**Manual (Mandiri):**
- Wallet → Top Up → 100000 → Mandiri Transfer → "Kirim Request"
- ✅ Status pending di Firestore
- Admin (atau pakai Dev Tools di profile) → approve → saldo bertambah

### Test Admin Panel

1. Login sebagai user yang `role: admin`
2. Profile → tombol **"Admin Panel"** muncul
3. Tab Dashboard / Top-up / Stasiun

---

## Roadmap

### Sudah Selesai
- [x] Authentication (login/register/logout/forgot password)
- [x] User profile real-time
- [x] Stations Firestore + auto-seed
- [x] Charging session simulator + real-time monitor
- [x] Receipt + transaction history
- [x] Wallet + top-up (auto + manual + admin approve)
- [x] Active session recovery + auto-stop
- [x] Admin panel (dashboard, top-up approval, station management)
- [x] Polish UI (shimmer loading, empty states, pull-to-refresh, inline form validation)

### Belum / Next
- [ ] Real ESP32 firmware integration
- [ ] Biometric login (`local_auth`)
- [ ] Real Google Maps + geolocation
- [ ] Camera QR code scanner (`mobile_scanner`)
- [ ] Photo upload (profile, payment proof) — butuh Firebase Storage
- [ ] Push notification handler (FCM)
- [ ] Cloud Functions untuk auto-trigger
- [ ] Dark mode
- [ ] User management di admin
- [ ] Analytics dashboard (revenue chart, kWh trends)
- [ ] Cetak / unduh struk PDF

---

## Konvensi Kode

| Tipe | Konvensi | Contoh |
|------|----------|--------|
| File | `snake_case` | `charging_session_page.dart` |
| Class | `PascalCase` | `ChargingSessionPage` |
| Variable / Method | `camelCase` | `startSession()` |
| Konstanta | `camelCase` atau `kSCREAMING` | `kTopupMethods` |
| Provider | `camelCase` + `Provider` | `currentUserDataProvider` |

---




---

<p align="center">
  <i>Powering the future of electric mobility, in your pocket.</i><br>
  <b>PAYCAY Mobile</b>
</p>
