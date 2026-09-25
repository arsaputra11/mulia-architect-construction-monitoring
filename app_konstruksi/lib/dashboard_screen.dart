import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'form_laporan_screen.dart';
import 'form_laporan_mingguan_screen.dart';
import 'login_screen.dart';
import 'detail_proyek_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String namaPengawas;
  final String idUser;

  DashboardScreen({required this.namaPengawas, required this.idUser});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List projects = [];
  bool isLoadingProjects = true;

  List riwayatLaporan = [];
  bool isLoadingLaporan = true;

  int _selectedIndex = 0;
  String _selectedFilter = 'Semua';

  final String apiUrl = "http://10.0.2.2/api_konstruksi/get_projects.php";
  final String apiLaporanUrl = "http://10.0.2.2/api_konstruksi/get_laporan.php";
  final String apiHapusDrafUrl =
      "http://10.0.2.2/api_konstruksi/hapus_laporan.php";
  final String apiUbahPasswordUrl =
      "http://10.0.2.2/api_konstruksi/ubah_password.php"; // API BARU

  final Color primaryGreen = Color(0xFF1B5E20);
  final Color lightGreen = Color(0xFFE8F5E9);
  final Color actionGreen = Color(0xFF43A047);
  final Color bgDark = Color(0xFF091F14);
  final Color cardDark = Color(0xFF132A1C);
  final Color greenAccent = Color(0xFF48BB78);
  final Color textMuted = Color(0xFF6B8A7A);
  final Color bgLight = Color(0xFFF4F7F5);

  @override
  void initState() {
    super.initState();
    fetchProjects();
    fetchRiwayatLaporan();
  }

  Future<void> fetchProjects() async {
    try {
      var response = await http.get(
        Uri.parse("$apiUrl?id_user=${widget.idUser}"),
      );
      var data = json.decode(response.body);

      if (data['status'] == 'success' && data['data'] != null) {
        if (!mounted) return;
        setState(() {
          projects = data['data'] is List ? data['data'] : [];
          isLoadingProjects = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoadingProjects = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingProjects = false;
      });
    }
  }

  Future<void> fetchRiwayatLaporan() async {
    try {
      var response = await http.get(
        Uri.parse("$apiLaporanUrl?id_user=${widget.idUser}"),
      );
      var data = json.decode(response.body);
      if (data['status'] == 'success' && data['data'] != null) {
        if (!mounted) return;
        setState(() {
          riwayatLaporan = data['data'] is List ? data['data'] : [];
          isLoadingLaporan = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoadingLaporan = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingLaporan = false;
      });
    }
  }

  Future<void> _konfirmasiHapusDraf(String idLaporan) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              "Hapus Draf?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          "Apakah kamu yakin ingin membuang draf ini? Data teks dan foto akan dihapus permanen dari server.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _eksekusiHapusDraf(idLaporan);
            },
            child: Text(
              "Hapus",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _eksekusiHapusDraf(String idLaporan) async {
    try {
      var response = await http.post(
        Uri.parse(apiHapusDrafUrl),
        body: {'id_laporan': idLaporan},
      );
      var result = json.decode(response.body);
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Draf berhasil dibersihkan!")));
        fetchRiwayatLaporan();
      }
    } catch (e) {
      print(e);
    }
  }

  void _showDetailLaporanPreview(
    Map laporan,
    String jenis,
    Color statusColor,
    IconData icon,
  ) {
    DateTime dateObj = DateTime.tryParse(laporan['tanggal']) ?? DateTime.now();
    String tglTampil = DateFormat('dd MMMM yyyy').format(dateObj);
    String statusSaatIni =
        laporan['status']?.toString().toUpperCase() ?? 'TERKIRIM';
    String idLaporan = laporan['id_laporan'].toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: statusColor, size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Laporan $jenis #$idLaporan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          statusSaatIni,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 32, color: Colors.grey[200], thickness: 1.5),
              Row(
                children: [
                  Icon(Icons.calendar_month, color: textMuted, size: 18),
                  SizedBox(width: 8),
                  Text(
                    tglTampil,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              if (jenis == 'HARIAN') ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.cloud_outlined, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Cuaca: ${laporan['cuaca'] ?? '-'}",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 24),
              Text(
                jenis == 'MINGGUAN'
                    ? "Rekap Progres Mingguan:"
                    : "Rincian Pekerjaan:",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  laporan['rincian']?.toString() ?? 'Tidak ada teks rincian.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return "AA";
    List<String> names = name.trim().split(' ');
    if (names.length == 1)
      return names[0].isNotEmpty ? names[0][0].toUpperCase() : "AA";
    return (names[0][0] + names[names.length - 1][0]).toUpperCase();
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // --- FUNGSI TAMPIL DIALOG UBAH PASSWORD ---
  void _tampilDialogUbahPassword() {
    TextEditingController oldPassCtrl = TextEditingController();
    TextEditingController newPassCtrl = TextEditingController();
    TextEditingController confirmPassCtrl = TextEditingController();
    bool isObscure = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: actionGreen),
                  SizedBox(width: 8),
                  Text(
                    "Ubah Password",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPassCtrl,
                      obscureText: isObscure,
                      decoration: InputDecoration(
                        labelText: "Password Lama",
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: isObscure,
                      decoration: InputDecoration(
                        labelText: "Password Baru",
                        prefixIcon: Icon(Icons.key, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: isObscure,
                      decoration: InputDecoration(
                        labelText: "Konfirmasi Password Baru",
                        prefixIcon: Icon(Icons.key, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Tampilkan Password",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Switch(
                          value: !isObscure,
                          activeColor: actionGreen,
                          onChanged: (val) {
                            setStateDialog(() {
                              isObscure = !val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (oldPassCtrl.text.isEmpty ||
                              newPassCtrl.text.isEmpty ||
                              confirmPassCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Semua kolom wajib diisi!"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (newPassCtrl.text != confirmPassCtrl.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Konfirmasi password baru tidak cocok!",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setStateDialog(() {
                            isSubmitting = true;
                          });

                          try {
                            var res = await http.post(
                              Uri.parse(apiUbahPasswordUrl),
                              body: {
                                'id_user': widget.idUser,
                                'password_lama': oldPassCtrl.text,
                                'password_baru': newPassCtrl.text,
                              },
                            );
                            var data = json.decode(res.body);

                            if (data['status'] == 'success') {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(data['message']),
                                  backgroundColor: actionGreen,
                                ),
                              );
                            } else {
                              setStateDialog(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(data['message']),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            setStateDialog(() {
                              isSubmitting = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Terjadi kesalahan jaringan"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Simpan",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterItem(String status, IconData icon, {Color? color}) {
    bool isSelected = _selectedFilter == status;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Image.asset(
        'assets/logo.png',
        width: 45,
        height: 45,
        fit: BoxFit.contain,
      ),
      title: Text(
        status == "Semua" ? "Tampilkan Semua" : "Proyek $status",
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? actionGreen : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: actionGreen)
          : null,
      onTap: () {
        setState(() {
          _selectedFilter = status;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildBeranda() {
    List filteredProjects = projects.where((p) {
      if (_selectedFilter == 'Semua') return true;
      return p['status']?.toString().toUpperCase() == _selectedFilter;
    }).toList();

    int jumlahMenungguReview = riwayatLaporan.where((l) {
      String st = l['status']?.toString().toUpperCase() ?? '';
      return st == 'TERKIRIM' || st == 'REVIEW';
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selamat datang kembali,",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                "${widget.namaPengawas}!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard(
                    projects.length.toString(),
                    "Total Proyek",
                    Colors.white24,
                    Colors.white,
                  ),
                  _buildStatCard(
                    riwayatLaporan.length.toString(),
                    "Total Laporan",
                    Colors.white24,
                    Colors.white,
                  ),
                  _buildStatCard(
                    jumlahMenungguReview.toString(),
                    "Menunggu Review",
                    Color(0xFFFBC02D).withOpacity(0.2),
                    Color(0xFFFBC02D),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daftar Proyek",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _selectedFilter == 'Semua'
                        ? "${filteredProjects.length} proyek ditemukan"
                        : "${filteredProjects.length} proyek dengan status $_selectedFilter",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: Text(
                                "FILTER PROYEK",
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            Divider(color: Colors.grey[200], thickness: 1),
                            _buildFilterItem("Semua", Icons.all_inclusive),
                            _buildFilterItem(
                              "AKTIF",
                              Icons.play_circle_outline,
                              color: actionGreen,
                            ),
                            _buildFilterItem(
                              "REVIEW",
                              Icons.access_time,
                              color: Colors.orange,
                            ),
                            _buildFilterItem(
                              "SELESAI",
                              Icons.check_circle_outline,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedFilter != 'Semua'
                        ? actionGreen
                        : lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune,
                        size: 16,
                        color: _selectedFilter != 'Semua'
                            ? Colors.white
                            : actionGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _selectedFilter != 'Semua' ? _selectedFilter : "Filter",
                        style: TextStyle(
                          color: _selectedFilter != 'Semua'
                              ? Colors.white
                              : actionGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoadingProjects
              ? Center(child: CircularProgressIndicator(color: actionGreen))
              : filteredProjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                      SizedBox(height: 12),
                      Text(
                        "Tidak ada proyek dengan status $_selectedFilter.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredProjects.length,
                  itemBuilder: (context, index) {
                    var project = filteredProjects[index];
                    String namaProyek =
                        project['nama_proyek']?.toString() ??
                        'Proyek Tanpa Nama';
                    String lokasi =
                        project['lokasi']?.toString() ??
                        'Lokasi tidak diketahui';
                    String status =
                        project['status']?.toString().toUpperCase() ?? 'AKTIF';
                    bool isReview = status == 'REVIEW';

                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailProyekScreen(
                                project: project,
                                idUser: widget.idUser,
                              ),
                            ),
                          );
                          fetchRiwayatLaporan();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isReview
                                  ? Colors.orange.withOpacity(0.5)
                                  : Colors.green.withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isReview
                                            ? Colors.orange[50]
                                            : lightGreen,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isReview
                                            ? Icons.maps_home_work_outlined
                                            : Icons.domain,
                                        color: isReview
                                            ? Colors.orange
                                            : actionGreen,
                                        size: 28,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            namaProyek,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  lokasi,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isReview
                                                  ? Colors.orange[50]
                                                  : lightGreen,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: isReview
                                                    ? Colors.orange
                                                    : actionGreen,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: actionGreen,
                                          side: BorderSide(color: actionGreen),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(Icons.today, size: 16),
                                        label: Text(
                                          "Harian",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FormLaporanScreen(
                                                    idProject:
                                                        project['id_project']
                                                            .toString(),
                                                    idUser: widget.idUser,
                                                    namaProyek: namaProyek,
                                                  ),
                                            ),
                                          );
                                          if (result != null) {
                                            fetchRiwayatLaporan();
                                            setState(() {
                                              _selectedIndex = 1;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: actionGreen,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(Icons.date_range, size: 16),
                                        label: Text(
                                          "Mingguan",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FormLaporanMingguanScreen(
                                                    idProject:
                                                        project['id_project']
                                                            .toString(),
                                                    idUser: widget.idUser,
                                                    namaProyek: namaProyek,
                                                  ),
                                            ),
                                          );
                                          if (result != null) {
                                            fetchRiwayatLaporan();
                                            setState(() {
                                              _selectedIndex = 1;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDaftarLaporan({required bool hanyaDraft}) {
    if (isLoadingLaporan)
      return Center(child: CircularProgressIndicator(color: actionGreen));

    List filteredLaporan = riwayatLaporan.where((laporan) {
      String status = laporan['status']?.toString().toUpperCase() ?? 'TERKIRIM';
      return hanyaDraft ? status == 'DRAFT' : status != 'DRAFT';
    }).toList();

    if (filteredLaporan.isEmpty) {
      return RefreshIndicator(
        color: actionGreen,
        onRefresh: fetchRiwayatLaporan,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 80, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  hanyaDraft
                      ? "Tidak ada draf laporan"
                      : "Belum ada riwayat aktivitas",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Tarik ke bawah untuk menyegarkan",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: actionGreen,
      onRefresh: fetchRiwayatLaporan,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        itemCount: filteredLaporan.length,
        itemBuilder: (context, index) {
          var laporan = filteredLaporan[index];
          String jenisLaporan =
              laporan['jenis_laporan']?.toString().toUpperCase() ?? 'HARIAN';
          DateTime dateObj =
              DateTime.tryParse(laporan['tanggal']) ?? DateTime.now();
          String tglTampil = DateFormat('dd MMM yyyy').format(dateObj);
          String rincian =
              laporan['rincian']?.toString() ?? 'Tidak ada rincian';
          if (rincian.isEmpty) rincian = "Draf baru...";
          String status =
              laporan['status']?.toString().toUpperCase() ?? 'TERKIRIM';
          String cuaca = laporan['cuaca']?.toString() ?? 'Cerah';

          Color statusColor = status == 'DRAFT'
              ? Colors.orange
              : (status == 'SELESAI' ? Colors.green : Colors.blue);
          IconData iconLaporan = jenisLaporan == 'MINGGUAN'
              ? Icons.view_week_rounded
              : Icons.assignment_turned_in;
          if (hanyaDraft) iconLaporan = Icons.edit_document;
          String titleLaporan = jenisLaporan == 'MINGGUAN'
              ? "Laporan Mingguan #${laporan['id_laporan']}"
              : "Laporan Harian #${laporan['id_laporan']}";

          return InkWell(
            onTap: () async {
              if (status == 'REVIEW') {
                if (jenisLaporan == 'HARIAN') {
                  // LEMPAR KE REVISI HARIAN
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormLaporanScreen(
                        idProject: laporan['id_project'].toString(),
                        idUser: widget.idUser,
                        namaProyek: "Revisi Harian",
                        isRevisi: true,
                        idLaporan: laporan['id_laporan'].toString(),
                        initialRincian: rincian,
                        initialCuaca: cuaca,
                      ),
                    ),
                  );
                  if (result != null) fetchRiwayatLaporan();
                } else if (jenisLaporan == 'MINGGUAN') {
                  // LEMPAR KE REVISI MINGGUAN
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormLaporanMingguanScreen(
                        idProject: laporan['id_project'].toString(),
                        idUser: widget.idUser,
                        namaProyek: "Revisi Mingguan",
                        isRevisi: true,
                        idLaporan: laporan['id_laporan'].toString(),
                        initialRincian: rincian,
                      ),
                    ),
                  );
                  if (result != null) fetchRiwayatLaporan();
                }
              } else if (!hanyaDraft) {
                // JIKA STATUS SELESAI / TERKIRIM, BUKA PREVIEW BIASA
                _showDetailLaporanPreview(
                  laporan,
                  jenisLaporan,
                  statusColor,
                  iconLaporan,
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: jenisLaporan == 'MINGGUAN'
                      ? actionGreen.withOpacity(0.3)
                      : Colors.grey[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: jenisLaporan == 'MINGGUAN'
                          ? actionGreen.withOpacity(0.1)
                          : statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconLaporan,
                      color: jenisLaporan == 'MINGGUAN'
                          ? actionGreen
                          : statusColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleLaporan,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: jenisLaporan == 'MINGGUAN'
                                ? actionGreen
                                : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          rincian,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 10,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              tglTampil,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                            if (jenisLaporan == 'HARIAN') ...[
                              SizedBox(width: 8),
                              Icon(
                                Icons.cloud_outlined,
                                size: 10,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Text(
                                cuaca,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hanyaDraft)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        width: 24,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                          onSelected: (value) async {
                            if (value == 'lanjutkan') {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FormLaporanScreen(
                                    idProject:
                                        laporan['id_project']?.toString() ??
                                        '1',
                                    idUser: widget.idUser,
                                    namaProyek: "Melanjutkan Draf...",
                                  ),
                                ),
                              );
                              if (result != null) fetchRiwayatLaporan();
                            } else if (value == 'hapus') {
                              _konfirmasiHapusDraf(
                                laporan['id_laporan'].toString(),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'lanjutkan',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    color: actionGreen,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Lanjutkan Draf",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'hapus',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Hapus Draf",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HALAMAN PROFIL YANG BARU & ELEGAN ---
  Widget _buildProfil() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 40, bottom: 40),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      getInitials(widget.namaPengawas),
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  widget.namaPengawas,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Pengawas Lapangan | ID: ${widget.idUser}",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PENGATURAN AKUN",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 12),

                _buildProfileMenuItem(
                  icon: Icons.lock_outline,
                  title: "Ubah Password",
                  onTap:
                      _tampilDialogUbahPassword, // MEMANGGIL FUNGSI UBAH PASSWORD
                ),
                _buildProfileMenuItem(
                  icon: Icons.help_outline,
                  title: "Bantuan & Panduan",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Hubungi Admin: 0812-XXXX-XXXX")),
                    );
                  },
                ),
                _buildProfileMenuItem(
                  icon: Icons.info_outline,
                  title: "Tentang Aplikasi",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Mulia Architect App v2.4.1")),
                    );
                  },
                ),

                SizedBox(height: 24),

                _buildProfileMenuItem(
                  icon: Icons.logout,
                  title: "Keluar Akun",
                  isDestructive: true,
                  onTap: _logout,
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BANTUAN UNTUK MENU PROFIL ---
  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDestructive ? Colors.red : actionGreen).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : actionGreen,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDestructive ? Colors.red : Colors.black87,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildBeranda();
      case 1:
        return _buildDaftarLaporan(hanyaDraft: true);
      case 2:
        return _buildDaftarLaporan(hanyaDraft: false);
      case 3:
        return _buildProfil();
      default:
        return _buildBeranda();
    }
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return "Beranda Proyek";
      case 1:
        return "Kotak Draf Laporan";
      case 2:
        return "Riwayat Aktivitas";
      case 3:
        return "Profil Akun";
      default:
        return "Dashboard";
    }
  }

  Widget _buildDrawerItem({
    required String title,
    required IconData icon,
    required int targetIndex,
    String? badge,
  }) {
    bool isActive = _selectedIndex == targetIndex;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = targetIndex;
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? cardDark : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: greenAccent.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? greenAccent : textMuted, size: 22),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : textMuted,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                getInitials(widget.namaPengawas),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: bgDark,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: greenAccent.withOpacity(0.3)),
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        width:
                            70, // Ukurannya saya sesuaikan biar pas dengan tinggi teks
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "mulia architect",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "V2.4.1",
                            style: TextStyle(color: textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: greenAccent, width: 2),
                          ),
                          child: CircleAvatar(
                            backgroundColor: bgDark,
                            radius: 20,
                            child: Text(
                              getInitials(widget.namaPengawas),
                              style: TextStyle(
                                color: greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.namaPengawas,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Pengawas Lapangan",
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(
                          projects.length.toString(),
                          "Proyek",
                          bgDark,
                          Colors.white,
                        ),
                        _buildStatCard(
                          riwayatLaporan.length.toString(),
                          "Laporan",
                          bgDark,
                          Colors.white,
                        ),
                        _buildStatCard(
                          riwayatLaporan
                              .where(
                                (l) =>
                                    l['status'].toString().toUpperCase() ==
                                        'TERKIRIM' ||
                                    l['status'].toString().toUpperCase() ==
                                        'REVIEW',
                              )
                              .length
                              .toString(),
                          "Review",
                          Color(0xFF3E3A24),
                          Color(0xFFFBC02D),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 8),
                child: Text(
                  "MENU UTAMA",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              _buildDrawerItem(
                title: "Beranda",
                icon: Icons.home_filled,
                targetIndex: 0,
              ),
              _buildDrawerItem(
                title: "Proyek Aktif",
                icon: Icons.domain,
                targetIndex: 0,
                badge: projects.length.toString(),
              ),
              _buildDrawerItem(
                title: "Riwayat Laporan",
                icon: Icons.history,
                targetIndex: 2,
                badge: riwayatLaporan.length.toString(),
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A1616),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent, size: 22),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Keluar",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(child: _buildCurrentPage()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: actionGreen,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Beranda",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              label: "Laporan",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "Riwayat",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profil",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String angka,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              angka,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
