# SyncLife - Habits Tracker 🚀

Aplikasi pelacak kebiasaan (habit tracker) berbasis Flutter dengan antarmuka yang modern, dinamis, dan terintegrasi dengan mesin prediksi *Naive Bayes* untuk menganalisis peluang sukses kebiasaan harian Anda.

Proyek ini dibangun menggunakan **Flutter**, **Riverpod** (State Management), dan **Supabase** (Backend as a Service).

---

## 🛠️ Persyaratan Sistem (Prerequisites)

Sebelum melakukan *clone* pada proyek ini, pastikan Anda telah menginstal perangkat lunak berikut di laptop/komputer Anda:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.11.0 atau lebih baru)
- [Dart SDK](https://dart.dev/get-dart)
- IDE yang direkomendasikan: [VS Code](https://code.visualstudio.com/) atau [Android Studio](https://developer.android.com/studio)

---

## 📥 Cara Menjalankan Proyek (Setup & Clone)

Ikuti langkah-langkah di bawah ini untuk mengkloning dan menjalankan aplikasi ini secara lokal:

### 1. Clone Repository
Buka terminal Anda dan jalankan perintah clone (ganti `URL_REPO_ANDA` dengan link GitHub repository proyek ini):
```bash
git clone https://github.com/USERNAME_ANDA/SyncLife-Habit-Tracker.git
```

### 2. Pindah ke Folder Proyek
```bash
cd SyncLife-Habit-Tracker/synclife
```

### 3. Install Dependencies
Unduh semua library dan *package* yang dibutuhkan oleh aplikasi:
```bash
flutter pub get
```

### 4. Setup Konfigurasi Backend (Supabase)
Karena alasan keamanan, API Keys untuk database tidak disertakan di GitHub. 
1. Minta kredensial `supabaseUrl` dan `supabaseAnonKey` kepada pemilik proyek.
2. Pastikan kredensial tersebut sudah dimasukkan ke dalam file `lib/core/constants/supabase_constants.dart` atau dilempar melalui `.env` sesuai dengan konfigurasi proyek yang berjalan.

### 5. Jalankan Aplikasi
Jalankan aplikasi di emulator Android/iOS atau Chrome:
```bash
flutter run
```

---

## 🤝 Panduan Kolaborasi (Workflow)

Untuk memastikan kode tidak rusak (*conflict*) saat bekerja sama, **DILARANG KERAS** mengedit dan melakukan *push* langsung ke branch `main`. Ikuti alur berikut:

**1. Tarik pembaruan terbaru dari GitHub (Selalu lakukan ini sebelum mulai *ngoding*)**
```bash
git checkout main
git pull origin main
```

**2. Buat Branch Baru untuk Fitur yang Anda Kerjakan**
Beri nama branch sesuai fitur yang dikerjakan, contoh: `fitur-statistik`, `fix-login`, atau `ui-dashboard`.
```bash
git checkout -b nama-fitur-anda
```

**3. Kerjakan dan Simpan (*Commit*)**
Setelah Anda selesai mengerjakan fitur tersebut:
```bash
git add .
git commit -m "Deskripsi singkat tentang apa yang Anda kerjakan"
```

**4. Push Branch Anda ke GitHub**
```bash
git push origin nama-fitur-anda
```

**5. Buat Pull Request (PR)**
- Buka repository di GitHub.
- Klik tombol **Compare & pull request** yang muncul.
- Berikan deskripsi singkat tentang fitur yang dibuat, lalu klik **Create pull request**.
- Tunggu *partner* Anda untuk me-review kode tersebut. Jika aman, kode akan di-*merge* ke `main`.

---

## 📂 Struktur Folder Utama
- `lib/features/`: Berisi berbagai fitur utama aplikasi (Home, Habits, Logs, Predictor, Statistics).
- `lib/core/`: Berisi konfigurasi konstan, tema, dan utilitas aplikasi.
- `lib/models/`: Berisi model data dan representasi tabel Supabase.

Selamat berkolaborasi! Jangan ragu untuk mendiskusikan *logic* atau *design* bersama tim sebelum melakukan *commit* besar-besaran. 🎯
