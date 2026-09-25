import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'form_laporan_screen.dart';

// ==========================================
// 1. HALAMAN DETAIL PROYEK
// ==========================================
class DetailProyekScreen extends StatefulWidget {
  final dynamic project;
  final String idUser;

  DetailProyekScreen({required this.project, required this.idUser});

  @override
  _DetailProyekScreenState createState() => _DetailProyekScreenState();
}

class _DetailProyekScreenState extends State<DetailProyekScreen> {
  final Color primaryGreen = Color(0xFF1B5E20);
  final Color actionGreen = Color(0xFF43A047);
  final Color bgLight = Color(0xFFF4F7F5);

  Future<void> _bukaMaps(String lokasi) async {
    final query = Uri.encodeComponent(lokasi);
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$query",
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Tidak dapat membuka Maps. Pastikan ada browser/aplikasi Maps.",
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String namaProyek =
        widget.project['nama_proyek']?.toString() ?? 'Pembangunan Gedung A';
    String lokasi =
        widget.project['lokasi']?.toString() ?? 'Jl. Sudirman No. 10';
    String status =
        widget.project['status']?.toString().toUpperCase() ?? 'AKTIF';
    String idProyek = widget.project['id_project']?.toString() ?? 'PRJ-2024-1';

    String kontraktor = "PT. Bangun Jaya Abadi";
    String pengawas = "Arsa Andhika";
    String tglMulai = "01 Januari 2024";
    String tglSelesai = "31 Desember 2024";
    String luas = "2.400 m²";

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Detail Proyek",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: primaryGreen,
              padding: EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "ID: $idProyek",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    namaProyek,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          lokasi,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildActionCard(
                      icon: Icons.post_add,
                      label: "Buat\nLaporan",
                      color: actionGreen,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FormLaporanScreen(
                              idProject: idProyek,
                              idUser: widget.idUser,
                              namaProyek: namaProyek,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 12),
                    _buildActionCard(
                      icon: Icons.location_on_outlined,
                      label: "Cek\nLokasi",
                      color: Colors.white,
                      textColor: Colors.black87,
                      onTap: () => _bukaMaps(lokasi),
                    ),
                    SizedBox(width: 12),
                    _buildActionCard(
                      icon: Icons.photo_library_outlined,
                      label: "Galeri\nProyek",
                      color: Colors.white,
                      textColor: Colors.black87,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GaleriProyekScreen(
                              idProject: idProyek,
                              namaProyek: namaProyek,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: primaryGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Informasi Proyek",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildInfoRow(Icons.domain, "Kontraktor", kontraktor),
                    _buildInfoRow(Icons.person_outline, "Pengawas", pengawas),
                    _buildInfoRow(
                      Icons.calendar_today_outlined,
                      "Mulai",
                      tglMulai,
                    ),
                    _buildInfoRow(
                      Icons.flag_outlined,
                      "Target Selesai",
                      tglSelesai,
                    ),
                    _buildInfoRow(Icons.architecture, "Luas Bangunan", luas),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: bgLight),
        child: SafeArea(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionGreen,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: Icon(Icons.post_add, color: Colors.white, size: 20),
            label: Text(
              "Buat Laporan Hari Ini",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormLaporanScreen(
                    idProject: idProyek,
                    idUser: widget.idUser,
                    namaProyek: namaProyek,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: textColor, size: 28),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 18),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. HALAMAN GALERI PROYEK (VERSI ACCORDION / BUKA-TUTUP)
// ==========================================
class GaleriProyekScreen extends StatefulWidget {
  final String idProject;
  final String namaProyek;

  GaleriProyekScreen({required this.idProject, required this.namaProyek});

  @override
  _GaleriProyekScreenState createState() => _GaleriProyekScreenState();
}

class _GaleriProyekScreenState extends State<GaleriProyekScreen> {
  final Color primaryGreen = Color(0xFF1B5E20);
  final Color actionGreen = Color(0xFF43A047);
  final Color bgLight = Color(0xFFF4F7F5);

  DateTime? _selectedDate;
  List<Map<String, dynamic>> _allPhotos = [];
  Map<String, List<Map<String, dynamic>>> _groupedPhotos = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGaleri();
  }

  Future<void> _fetchGaleri() async {
    try {
      var response = await http.get(
        Uri.parse(
          "http://10.0.2.2/api_konstruksi/get_galeri_proyek.php?id_project=${widget.idProject}",
        ),
      );
      var data = json.decode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          _allPhotos = List<Map<String, dynamic>>.from(data['data']);
        });
        _groupPhotos();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _groupPhotos() {
    _groupedPhotos.clear();
    List<String> namaHariList = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    for (var photo in _allPhotos) {
      DateTime dateObj = DateFormat('yyyy-MM-dd').parse(photo['date']);

      if (_selectedDate != null) {
        String selectedDateStr = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDate!);
        if (photo['date'] != selectedDateStr) continue;
      }

      String namaHari = namaHariList[dateObj.weekday - 1];
      String tglFormat =
          "$namaHari, ${DateFormat('dd MMM yyyy').format(dateObj)}";

      if (!_groupedPhotos.containsKey(tglFormat)) {
        _groupedPhotos[tglFormat] = [];
      }
      _groupedPhotos[tglFormat]!.add(photo);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pilihTanggal(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: actionGreen,
              onPrimary: Colors.white,
              onSurface: primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });
      _groupPhotos();
    }
  }

  void _lihatFotoFull(String imageUrl, String note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: IconThemeData(color: Colors.white),
              title: Text(
                "Preview Foto",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 100,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  color: Colors.black87,
                  child: Text(
                    note,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Galeri Proyek",
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month,
              color: _selectedDate != null ? Colors.orange : Colors.white,
            ),
            onPressed: () => _pilihTanggal(context),
          ),
          if (_selectedDate != null)
            IconButton(
              icon: Icon(Icons.filter_alt_off, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                  _isLoading = true;
                });
                _groupPhotos();
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: actionGreen))
          : Column(
              children: [
                if (_selectedDate != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.orange.withOpacity(0.2),
                    child: Text(
                      "Menampilkan foto tanggal: ${DateFormat('dd MMMM yyyy').format(_selectedDate!)}",
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: _groupedPhotos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Belum ada dokumentasi foto.",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _groupedPhotos.keys.length,
                          itemBuilder: (context, index) {
                            String tglKey = _groupedPhotos.keys.elementAt(
                              index,
                            );
                            List<Map<String, dynamic>> fotosDiHariItu =
                                _groupedPhotos[tglKey]!;

                            return Card(
                              margin: EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  initiallyExpanded: index == 0,
                                  leading: Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: actionGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.calendar_month_rounded,
                                      color: actionGreen,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    tglKey,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${fotosDiHariItu.length} Foto Dokumentasi",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 0.85,
                                            ),
                                        itemCount: fotosDiHariItu.length,
                                        itemBuilder: (context, gridIndex) {
                                          var data = fotosDiHariItu[gridIndex];
                                          return InkWell(
                                            onTap: () => _lihatFotoFull(
                                              data['url'],
                                              data['note'],
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.grey[200]!,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  15,
                                                                ),
                                                          ),
                                                      child: Image.network(
                                                        data['url'],
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => Container(
                                                              color: Colors
                                                                  .grey[200],
                                                              child: Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10.0,
                                                        ),
                                                    child: Text(
                                                      data['note'],
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color: Colors.black87,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
