-- Buat database jika belum ada
CREATE DATABASE IF NOT EXISTS db_konstruksi;
USE db_konstruksi;

-- 1. Tabel Users (Tanpa Hash Password)
CREATE TABLE `tb_users` (
  `id_user` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL UNIQUE,
  `password` varchar(255) NOT NULL, -- Disimpan dalam bentuk plain text
  `role` enum('admin', 'pengawas') NOT NULL DEFAULT 'pengawas',
  `nama_lengkap` varchar(100) NOT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Tabel Projects (Menyimpan Denah Dasar)
CREATE TABLE `tb_projects` (
  `id_project` int(11) NOT NULL AUTO_INCREMENT,
  `nama_proyek` varchar(150) NOT NULL,
  `deskripsi` text,
  `lokasi` varchar(255) NOT NULL,
  `file_denah` varchar(255) NOT NULL, -- Path URL ke gambar denah asli
  `status` enum('aktif', 'selesai') NOT NULL DEFAULT 'aktif',
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_project`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Tabel Laporan Harian (Menyimpan Denah Coretan & GPS)
CREATE TABLE `tb_laporan_harian` (
  `id_laporan` int(11) NOT NULL AUTO_INCREMENT,
  `id_project` int(11) NOT NULL,
  `id_user` int(11) NOT NULL, -- Pengawas yang bertugas
  `tanggal` date NOT NULL,
  `cuaca` varchar(50) NOT NULL,
  `denah_ditandai` varchar(255) NOT NULL, -- Path URL ke gambar hasil coretan Canvas Flutter
  `foto_dokumentasi` varchar(255) NOT NULL, -- Path URL ke foto terkompresi
  `latitude` decimal(10,8) NOT NULL, -- Menampung tangkapan GPS riil
  `longitude` decimal(11,8) NOT NULL, -- Menampung tangkapan GPS riil
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_laporan`),
  FOREIGN KEY (`id_project`) REFERENCES `tb_projects`(`id_project`) ON DELETE CASCADE,
  FOREIGN KEY (`id_user`) REFERENCES `tb_users`(`id_user`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Tabel Laporan Detail (Rincian Pekerjaan & Volume)
CREATE TABLE `tb_laporan_detail` (
  `id_detail` int(11) NOT NULL AUTO_INCREMENT,
  `id_laporan` int(11) NOT NULL,
  `rincian_pekerjaan` text NOT NULL,
  `volume` varchar(100) NOT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_detail`),
  FOREIGN KEY (`id_laporan`) REFERENCES `tb_laporan_harian`(`id_laporan`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert data dummy untuk memudahkan pengetesan API nanti
INSERT INTO `tb_users` (`username`, `password`, `role`, `nama_lengkap`) VALUES
('admin_pusat', 'admin123', 'admin', 'Administrator'),
('mandor', '12345', 'pengawas', 'Arsa Andhika');
db_konstruksi
INSERT INTO `tb_projects` (`nama_proyek`, `deskripsi`, `db_konstruksilokasi`, `file_denah`, `status`) VALUES
('Pembangunan Gedung A', 'Gedung perkantoran 3 lantai', 'Jl. Sudirman No. 10', 'uploads/denah/gedung_a_base.jpg', 'aktif');