-- 1. Tabel Utama Laporan Harian
CREATE TABLE IF NOT EXISTS tb_laporan_harian (
    id_laporan INT AUTO_INCREMENT PRIMARY KEY,
    id_project INT NOT NULL,
    id_user INT NOT NULL,
    tanggal DATE NOT NULL,
    cuaca VARCHAR(50),
    rincian TEXT,
    volume FLOAT,
    satuan_volume VARCHAR(20),
    progress INT,
    catatan TEXT,
    latitude VARCHAR(50),
    longitude VARCHAR(50),
    status ENUM('DRAFT', 'TERKIRIM', 'REVIEW', 'SELESAI') DEFAULT 'TERKIRIM',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabel Penyimpanan Foto Dokumentasi (Bisa lebih dari 1 per laporan)
CREATE TABLE IF NOT EXISTS tb_laporan_foto (
    id_foto INT AUTO_INCREMENT PRIMARY KEY,
    id_laporan INT NOT NULL,
    foto_path VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_laporan) REFERENCES tb_laporan_harian(id_laporan) ON DELETE CASCADE
);

-- 3. Tabel Penyimpanan Coretan Denah (Bisa lebih dari 1 per laporan)
CREATE TABLE IF NOT EXISTS tb_laporan_denah (
    id_denah INT AUTO_INCREMENT PRIMARY KEY,
    id_laporan INT NOT NULL,
    nama_lantai VARCHAR(100) NOT NULL,
    foto_denah_path VARCHAR(255) NOT NULL,
    FOREIGN KEY (id_laporan) REFERENCES tb_laporan_harian(id_laporan) ON DELETE CASCADE
);db_konstruksidb_konstruksitb_laporan_harian