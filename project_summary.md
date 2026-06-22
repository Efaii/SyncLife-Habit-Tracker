# 📱 SyncLife - Habits Tracker
> **Laporan Ringkasan Proyek & Buku Panduan Manual (Manual Book)**
> 
> *Dokumen ini berisi informasi arsitektur, fitur, model data, algoritma, serta panduan teknis operasional untuk aplikasi SyncLife.*

---

## 📂 1. Deskripsi Proyek

**SyncLife** adalah aplikasi pemantau kebiasaan (*Habit Tracker*) pintar berbasis mobile dan web yang dibangun menggunakan **Flutter** dan **Supabase**. Selain melacak kebiasaan sehari-hari, SyncLife menggunakan **Algoritma Naive Bayes** untuk memprediksi tingkat keberhasilan penyelesaian kebiasaan pengguna berdasarkan kondisi psikologis/fisik mereka (yaitu tingkat suasana hati/*Mood* dan tingkat kesibukan/*Busyness*).

---

## 🛠️ 2. Arsitektur & Teknologi (Tech Stack)

Aplikasi ini menggunakan arsitektur modern berorientasi fitur (*feature-first architecture*) dengan rincian teknologi sebagai berikut:

*   **Framework Utama:** Flutter (Dart) dengan dukungan multi-platform (Android, iOS, dan Web).
*   **State Management:** [Flutter Riverpod](https://riverpod.dev/) untuk pengelolaan state yang reaktif, bersih, dan mudah diuji.
*   **Backend & Database:** [Supabase](https://supabase.com/) untuk Autentikasi Pengguna (Email & Google OAuth), penyimpanan data real-time, dan fungsi database relasional.
*   **Algoritma Prediksi:** Engine kustom **Naive Bayes Classifier** dengan **Laplace Smoothing** untuk memprediksi probabilitas keberhasilan habit secara real-time.
*   **Visualisasi Data:** `fl_chart` untuk grafik statistik interaktif (analisis mingguan, bulanan, korelasi mood, dll.).
*   **Notifikasi:** `flutter_local_notifications` untuk pengingat kebiasaan harian secara lokal.
*   **CI/CD & Hosting:** GitHub Actions terintegrasi dengan Vercel untuk deployment otomatis versi Flutter Web.

---

## 🧠 3. Cara Kerja Algoritma Naive Bayes di SyncLife

SyncLife mengumpulkan data historis setiap kali pengguna menyelesaikan atau melewatkan suatu kebiasaan. Parameter yang dicatat meliputi:
1.  **Mood (Suasana Hati):** Skala 1 (Sangat Buruk) hingga 5 (Sangat Baik).
2.  **Busyness (Kesibukan):** Skala 1 (Senggang) hingga 3 (Sangat Sibuk).

### Formula Posterior Probability
Algoritma menghitung peluang keberhasilan kebiasaan menggunakan formula Bayes:

$$P(\text{Success} \mid \text{Mood}, \text{Busy}) \propto P(\text{Success}) \times P(\text{Mood} \mid \text{Success}) \times P(\text{Busy} \mid \text{Success})$$

### Laplace Smoothing (Pencegahan Zero-Frequency)
Untuk menghindari probabilitas bernilai 0% ketika data suatu parameter belum pernah terekam, diterapkan **Laplace Smoothing**:

*   **P(Mood | Class):** $\frac{\text{Count(Mood)} + 1}{\text{Total Class} + 5}$ (karena ada 5 tingkat skala Mood)
*   **P(Busy | Class):** $\frac{\text{Count(Busy)} + 1}{\text{Total Class} + 3}$ (karena ada 3 tingkat skala Busyness)

Jika data historis kurang dari 5 log, sistem akan mengembalikan default probabilitas aman sebesar **50.0%**.

---

## 🎨 4. Fitur Utama & Antarmuka Pengguna

1.  **Sistem Autentikasi Ganda:** Pengguna dapat masuk menggunakan Email & Password konvensional atau menggunakan Google Sign-In secara langsung.
2.  **Dashboard Utama:**
    *   *Active Streak:* Informasi streak harian aktif dengan ikon dinamis.
    *   *Forecast Card:* Menampilkan ramalan kesuksesan hari ini berbasis Naive Bayes.
    *   *Today's Focus:* Kapsul status interaktif yang merangkum persentase fokus hari ini.
3.  **Pengelolaan Kebiasaan (Habits):** 
    *   Form Tambah & Edit Habit yang responsif untuk Mobile, Tablet, dan Desktop (Lebar dibatasi maksimal `600px`).
    *   Pemilih ikon dan warna dinamis (`IconAndColorPicker`) dengan ukuran grid fleksibel.
4.  **Pencatatan Harian (Daily Logs):** Pengguna dapat mencentang habit sembari memasukkan data Mood dan Busyness saat itu untuk memperkaya dataset AI.
5.  **Statistik & Analitik:** Grafik interaktif perkembangan habit, persentase keberhasilan harian, dan ringkasan tren suasana hati.

---

## 🛡️ 5. Skema Database (Supabase Tables)

Secara garis besar, database Supabase terdiri dari tabel-tabel utama berikut:

### `habits`
Menyimpan daftar kebiasaan yang dibuat pengguna.
*   `id_habit` (UUID, Primary Key)
*   `user_id` (UUID, Foreign Key ke auth.users)
*   `nama_habit` (Text)
*   `ikon` (Text / CodePoint)
*   `target_waktu` (Time / HH:mm)
*   `warna_tag` (Text / Hex Color)
*   `created_at` (Timestamp)

### `habit_logs`
Menyimpan riwayat penyelesaian kebiasaan pengguna harian.
*   `id_log` (UUID, Primary Key)
*   `id_habit` (UUID, Foreign Key ke `habits`)
*   `tanggal` (Date)
*   `status` (Boolean - Selesai/Lewat)
*   `mood_level` (Integer, 1-5)
*   `busy_level` (Integer, 1-3)
*   `catatan` (Text, Opsional)

### `frequency_table`
Tabel agregasi frekuensi untuk mempercepat komputasi probabilitas Naive Bayes di sisi client.

---

## 🚀 6. Panduan Manual Pengoperasian (Manual Book)

### A. Prasyarat Sistem
*   Flutter SDK (Versi `>= 3.11.0`)
*   Java Development Kit (JDK 17) untuk Android build
*   Akun Supabase & Akun Vercel (untuk deploy web)

### B. Menjalankan Aplikasi secara Lokal
1.  Buka folder proyek `synclife`.
2.  Pastikan dependensi terinstal:
    ```bash
    flutter pub get
    ```
3.  Buat file `assets/.env` di folder `synclife/assets/` dan isi kredensial Supabase Anda:
    ```properties
    SUPABASE_URL=https://your-project-id.supabase.co
    SUPABASE_ANON_KEY=your-anon-key
    SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
    ```
4.  Jalankan aplikasi di emulator atau browser:
    ```bash
    flutter run
    ```

### C. Build APK / AAB Rilis untuk Android
Aplikasi sudah dikonfigurasi untuk ditandatangani secara otomatis menggunakan Keystore rilis melalui file `key.properties`.

1.  Buat file `android/key.properties` jika belum ada, isi dengan kredensial keystore Anda:
    ```properties
    storePassword=passwordKeystoreAnda
    keyPassword=passwordKunciAnda
    keyAlias=key
    storeFile=upload-keystore.jks
    ```
2.  Jalankan perintah build APK:
    ```bash
    flutter build apk --release --no-tree-shake-icons
    ```
    *File APK rilis akan dihasilkan di: `build/app/outputs/flutter-apk/app-release.apk`*

### D. Deploy Otomatis ke Vercel via GitHub Actions
Setiap kali Anda melakukan push ke branch `main`, `master`, atau `feature/ux-notification-polish`, GitHub Actions akan otomatis mem-build Flutter Web dan men-deploy-nya ke Vercel.

**Pengaturan Secrets di GitHub Repository (`Settings > Secrets > Actions`):**
*   `VERCEL_SYNCLIFE_TOKEN`: Token akses pribadi Vercel Anda.
*   `VERCEL_SYNCLIFE_ORG_ID`: ID Organisasi Vercel Anda.
*   `VERCEL_SYNCLIFE_PROJECT_ID`: ID Project Vercel Anda.
