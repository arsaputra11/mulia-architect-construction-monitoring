import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FormLaporanMingguanScreen extends StatefulWidget {
  final String idProject;
  final String idUser;
  final String namaProyek;

  final bool isRevisi;
  final String? idLaporan;
  final String? initialRincian;

  FormLaporanMingguanScreen({
    required this.idProject,
    required this.idUser,
    required this.namaProyek,
    this.isRevisi = false,
    this.idLaporan,
    this.initialRincian,
  });

  @override
  _FormLaporanMingguanScreenState createState() =>
      _FormLaporanMingguanScreenState();
}

class _FormLaporanMingguanScreenState extends State<FormLaporanMingguanScreen> {
  final TextEditingController _progressController = TextEditingController();
  final TextEditingController _kelebihanController = TextEditingController();
  final TextEditingController _kendalaController = TextEditingController();

  int _selectedHariIndex = 0;
  final List<String> _hariList = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  Map<String, String> _rekapHarian = {
    'Senin': 'Memuat data...',
    'Selasa': 'Memuat data...',
    'Rabu': 'Memuat data...',
    'Kamis': 'Memuat data...',
    'Jumat': 'Memuat data...',
    'Sabtu': 'Memuat data...',
  };

  Map<String, Map<String, dynamic>> _rekapTenaga = {};

  bool _isSubmitting = false;
  bool _isLoadingRekap = true;

  final Color primaryGreen = Color(0xFF1B5E20);
  final Color actionGreen = Color(0xFF43A047);
  final Color bgLight = Color(0xFFF4F7F5);
  final Color textMuted = Color(0xFF6B8A7A);

  @override
  void initState() {
    super.initState();

    if (widget.isRevisi && widget.initialRincian != null) {
      String r = widget.initialRincian!;
      try {
        if (r.contains('Progres:')) {
          var parts = r.split('|');
          for (var p in parts) {
            if (p.contains('Progres:'))
              _progressController.text = p.replaceAll('Progres:', '').trim();
            if (p.contains('Kelebihan:'))
              _kelebihanController.text = p.replaceAll('Kelebihan:', '').trim();
            if (p.contains('Kendala:'))
              _kendalaController.text = p.replaceAll('Kendala:', '').trim();
          }
        } else {
          _progressController.text = r;
        }
      } catch (e) {
        _progressController.text = r;
      }
      _isLoadingRekap = false;
    } else {
      _fetchRekapMingguan();
    }
  }

  Future<void> _fetchRekapMingguan() async {
    try {
      var response = await http.get(
        Uri.parse(
          "http://10.0.2.2/api_konstruksi/get_rekap_mingguan.php?id_project=${widget.idProject}",
        ),
      );
      var data = json.decode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          if (data['data'] != null) {
            _rekapHarian = Map<String, String>.from(data['data']);
          }

          if (data['tenaga'] != null) {
            Map<String, dynamic> rawTenaga = data['tenaga'];
            rawTenaga.forEach((key, value) {
              // PERBAIKAN BUG: Cek null sebelum di-convert agar tidak error "Type Null is not a subtype"
              if (value != null) {
                _rekapTenaga[key] = Map<String, dynamic>.from(value);
              }
            });
          }
          _isLoadingRekap = false;
        });
      } else {
        setState(() {
          _isLoadingRekap = false;
        });
      }
    } catch (e) {
      print("Error ambil rekap: $e");
      setState(() {
        _isLoadingRekap = false;
      });
    }
  }

  Future<void> _kirimRevisi() async {
    if (_progressController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Mohon isi persentase progres!")));
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    try {
      var response = await http.post(
        Uri.parse("http://10.0.2.2/api_konstruksi/revisi_laporan.php"),
        body: {
          'id_laporan': widget.idLaporan ?? '',
          'jenis_laporan': 'MINGGUAN',
          'progress_fisik': _progressController.text,
          'kelebihan': _kelebihanController.text,
          'kendala': _kendalaController.text,
        },
      );

      var data = json.decode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Revisi mingguan berhasil dikirim ulang!"),
            backgroundColor: actionGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal revisi: ${data['message']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan sistem"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted)
        setState(() {
          _isSubmitting = false;
        });
    }
  }

  Future<void> _kirimLaporanMingguan() async {
    if (_progressController.text.isEmpty ||
        _kelebihanController.text.isEmpty ||
        _kendalaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Mohon isi persentase progres, kelebihan, dan kendala!",
          ),
        ),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    String rekapTenagaJson = json.encode(_rekapTenaga);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://10.0.2.2/api_konstruksi/submit_laporan_mingguan.php"),
      );
      request.fields['id_project'] = widget.idProject;
      request.fields['id_user'] = widget.idUser;
      request.fields['minggu_ke'] = "Minggu Ini";
      request.fields['progress_fisik'] = _progressController.text;
      request.fields['kelebihan'] = _kelebihanController.text;
      request.fields['kendala'] = _kendalaController.text;
      request.fields['rekap_tenaga'] = rekapTenagaJson;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      try {
        var result = json.decode(responseData);
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Laporan Mingguan berhasil dikirim!"),
              backgroundColor: actionGreen,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal: ${result['message']}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Pesan Error PHP"),
            content: SingleChildScrollView(child: Text(responseData)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Tutup"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan sistem"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted)
        setState(() {
          _isSubmitting = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    String hariTerpilih = _hariList[_selectedHariIndex];
    String rincianHariIni =
        _rekapHarian[hariTerpilih] ?? 'Belum ada laporan untuk hari ini.';
    bool isKosong = rincianHariIni.contains("Belum ada");

    Map<String, dynamic>? infoTenaga = _rekapTenaga[hariTerpilih];

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: widget.isRevisi ? Colors.orange[800] : primaryGreen,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isRevisi
                  ? "Revisi Laporan Mingguan"
                  : "Form Laporan Mingguan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              widget.namaProyek,
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingRekap
          ? Center(child: CircularProgressIndicator(color: actionGreen))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isRevisi)
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[800]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Mode Revisi: Silakan perbaiki progres dan laporan Anda di kolom yang tersedia.",
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!widget.isRevisi) ...[
                    // REKAP HARIAN (SENIN - SABTU)
                    _buildSectionTitle(
                      Icons.history_edu,
                      "Rekap Laporan Harian",
                      "(Pilih Hari)",
                    ),
                    SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_hariList.length, (index) {
                          bool isSelected = _selectedHariIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                _hariList[index],
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: actionGreen,
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: isSelected
                                    ? actionGreen
                                    : Colors.grey[300]!,
                              ),
                              onSelected: (selected) {
                                if (selected)
                                  setState(() {
                                    _selectedHariIndex = index;
                                  });
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 8),

                    // KOTAK RINCIAN & TENAGA KERJA
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rincian Hari $hariTerpilih:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textMuted,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            rincianHariIni,
                            style: TextStyle(
                              fontSize: 14,
                              color: isKosong
                                  ? Colors.red[300]
                                  : Colors.black87,
                              fontStyle: isKosong
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),

                          // Jika hari tsb tidak kosong dan ada data tenaga, tampilkan box khusus
                          if (!isKosong && infoTenaga != null) ...[
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFFF4F7F5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: actionGreen.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people_alt,
                                        size: 16,
                                        color: actionGreen,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "Tenaga Kerja Lapangan",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(color: Colors.grey[300]),
                                  // Tukang
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          "${infoTenaga['jml_tukang']} Tukang",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[800],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          infoTenaga['nama_tukang']
                                                  .toString()
                                                  .isNotEmpty
                                              ? infoTenaga['nama_tukang']
                                              : "-",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  // Tenaga
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          "${infoTenaga['jml_tenaga']} Tenaga",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          infoTenaga['nama_tenaga']
                                                  .toString()
                                                  .isNotEmpty
                                              ? infoTenaga['nama_tenaga']
                                              : "-",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // PROGRESS FISIK
                  _buildSectionTitle(
                    Icons.trending_up,
                    "Progress Fisik Minggu Ini",
                    "",
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _progressController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Misal: 105% (Deviasi +5%)",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      suffixIcon: Icon(
                        Icons.percent,
                        color: textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // KELEBIHAN
                  _buildSectionTitle(
                    Icons.thumb_up_alt_outlined,
                    "Kelebihan / Pencapaian",
                    "",
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _kelebihanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText:
                          "Jelaskan hal positif yang dicapai minggu ini...",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // KENDALA
                  _buildSectionTitle(
                    Icons.warning_amber_rounded,
                    "Kendala Lapangan",
                    "",
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _kendalaController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText:
                          "Jelaskan hambatan atau masalah yang terjadi...",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // TOMBOL KIRIM
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isRevisi
                            ? Colors.orange[700]
                            : primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () => widget.isRevisi
                                ? _kirimRevisi()
                                : _kirimLaporanMingguan(),
                      icon: _isSubmitting
                          ? SizedBox.shrink()
                          : Icon(Icons.send, color: Colors.white, size: 20),
                      label: _isSubmitting
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.isRevisi
                                  ? "KIRIM REVISI MINGGUAN"
                                  : "KIRIM LAPORAN MINGGUAN",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textMuted),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        if (subtitle.isNotEmpty) ...[
          SizedBox(width: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ],
    );
  }
}
