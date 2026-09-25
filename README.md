# 🏗️ Multi-Platform Construction Progress Monitoring System
> **Studi Kasus:** Digitalisasi Alur Pelaporan Progres Konstruksi & Validasi Lapangan pada **Mulia Architect**.

---

## 📌 Executive Summary & Problem Statement
Sebelum sistem ini dikembangkan, **Mulia Architect** mengandalkan pencatatan manual berbasis spreadsheet (Microsoft Excel) dan grup pesan singkat untuk pelaporan dari lokasi proyek.

### ⚠️ Kendala Utama:
* **Risk of Invalid Data:** Risiko ketidaksesuaian data opname/kehadiran pengawas di lokasi proyek.
* **Inefisiensi Redudansi Data:** Kesulitan admin pusat merangkum laporan harian menjadi rekapitulasi harian/mingguan secara manual.
* **Visualisasi Terbatas:** Komunikasi mengenai detail area teknis bangunan yang dikerjakan kurang presisi jika hanya menggunakan pesan teks atau foto biasa.

---

## 💡 Solusi & Inovasi Sistem
Membangun ekosistem **Multi-Platform** yang mendigitalisasi Standar Operasional Prosedur (SOP) pelaporan dari lapangan hingga ke manajemen pusat.

### 📱 A. Mobile Application (Field Inspector / Pengawas Lapangan)
* **Kunci GPS Otomatis (Spatial Validation):** Validasi kehadiran dan lokasi riil pengawas saat membuat laporan menggunakan penguncian koordinat GPS secara otomatis.
* **Anotasi Canvas Denah Digital:** Fitur interaktif untuk menggambar / mencoret langsung area kerja di atas gambar denah dasar (*blueprint*) proyek via layar sentuh seluler.
* **Formulir Laporan Terstruktur:** Input terintegrasi untuk parameter cuaca, rincian pekerjaan, volume kerja harian, serta foto proyek yang otomatis terkompresi.

### 💻 B. Web Dashboard (Project Manager & Admin Center)
* **Centralized Project Management:** Pengelolaan status proyek (aktif/selesai), alokasi penugasan mandor, dan arsip terpusat.
* **Auto-Generate Weekly Report:** Modul rekapitulasi dinamis yang otomatis merangkum data laporan harian menjadi laporan mingguan utuh.
* **Real-time Validation (ACC):** Verifikasi dan persetujuan (*approval*) dokumen laporan harian & mingguan secara *real-time* oleh manajemen pusat.

---

## 🛠️ Tech Stack & Architecture

| Komponen | Teknologi / Tool |
| :--- | :--- |
| **Mobile App** | Flutter (Dart) |
| **Web Dashboard** | PHP Native, CSS |
| **Database** | MySQL |
| **API / Backend** | RESTful API |
| **Key Features** | Geolocation (GPS Tracking), Interactive Touch Canvas, Image Compression |

---

## 📈 Key Results & Impact
* 🚀 **Peningkatan Akurasi Data:** Menghilangkan data pelaporan fiktif berkat penguncian koordinat GPS.
* ⏱️ **Efisiensi Waktu:** Memangkas waktu rekapitulasi data dari hitungan jam menjadi serba otomatis.
* 🤝 **Transparansi Operasional:** Menjembatani koordinasi antara tim teknis lapangan dan pihak perencana/manajemen pusat secara terpusat.