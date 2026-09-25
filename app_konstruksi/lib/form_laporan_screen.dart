import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart'; // ImageSource otomatis ikut ter-import dari sini
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'canvas_screen.dart';

class FormLaporanScreen extends StatefulWidget {
  final String idProject;
  final String idUser;
  final String namaProyek;

  final bool isRevisi;
  final String? idLaporan;
  final String? initialRincian;
  final String? initialCuaca;

  FormLaporanScreen({
    required this.idProject,
    required this.idUser,
    this.namaProyek = "Detail Proyek",
    this.isRevisi = false,
    this.idLaporan,
    this.initialRincian,
    this.initialCuaca,
  });

  @override
  _FormLaporanScreenState createState() => _FormLaporanScreenState();
}

class _FormLaporanScreenState extends State<FormLaporanScreen> {
  final TextEditingController _rincianController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  final TextEditingController _jmlTukangController = TextEditingController();
  final TextEditingController _namaTukangController = TextEditingController();
  final TextEditingController _jmlTenagaController = TextEditingController();
  final TextEditingController _namaTenagaController = TextEditingController();

  String _selectedCuaca = 'Cerah';
  String _selectedUnit = 'm²';
  List<File> _fotoList = [];

  Position? _currentPosition;
  bool _isLoadingGps = true;
  bool _isSubmitting = false;
  bool _isPickingFoto = false;

  Map<String, Uint8List> _coretanSemuaDenah = {};
  String? _namaDenahTerpilih;

  List<Map<String, dynamic>> _pilihanDenah = [];
  Map<String, String> _masterDenahUrls = {};
  bool _isLoadingDenah = true;

  final Color primaryGreen = Color(0xFF1B5E20);
  final Color actionGreen = Color(0xFF43A047);
  final Color bgLight = Color(0xFFF4F7F5);
  final Color darkCard = Color(0xFF0A2316);
  final Color textMuted = Color(0xFF6B8A7A);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchMasterDenah();

    if (widget.isRevisi) {
      _rincianController.text = widget.initialRincian ?? '';
      _selectedCuaca = widget.initialCuaca ?? 'Cerah';
    } else {
      _muatDraf();
    }
  }

  Future<void> _fetchMasterDenah() async {
    try {
      var response = await http.get(
        Uri.parse(
          "http://10.0.2.2/api_konstruksi/get_master_denah.php?id_project=${widget.idProject}",
        ),
      );
      var data = json.decode(response.body);
      if (data['status'] == 'success') {
        List<dynamic> denahList = data['data'];
        setState(() {
          _pilihanDenah = denahList
              .map(
                (e) => {
                  "id": e["id_denah"].toString(),
                  "nama": e["nama_lantai"].toString(),
                },
              )
              .toList();
          for (var d in denahList) {
            _masterDenahUrls[d["nama_lantai"]] = d["url"];
          }
          _isLoadingDenah = false;
        });
      }
    } catch (e) {
      print("Error fetch master denah: $e");
      setState(() {
        _isLoadingDenah = false;
      });
    }
  }

  Future<void> _muatDraf() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://10.0.2.2/api_konstruksi/get_draft.php?id_user=${widget.idUser}&id_project=${widget.idProject}",
        ),
      );

      var data = json.decode(response.body);
      if (data['status'] == 'success') {
        var draf = data['data'];
        setState(() {
          _rincianController.text = draf['rincian'] ?? "";
          _volumeController.text =
              (draf['volume'] != null && draf['volume'].toString() != "0")
              ? draf['volume'].toString()
              : "";
          _catatanController.text = draf['catatan'] ?? "";
          _selectedCuaca = draf['cuaca'] ?? 'Cerah';
          _selectedUnit = draf['satuan_volume'] ?? 'm²';

          _jmlTukangController.text =
              (draf['jml_tukang'] != null &&
                  draf['jml_tukang'].toString() != "0")
              ? draf['jml_tukang'].toString()
              : "";
          _namaTukangController.text = draf['nama_tukang'] ?? "";
          _jmlTenagaController.text =
              (draf['jml_tenaga'] != null &&
                  draf['jml_tenaga'].toString() != "0")
              ? draf['jml_tenaga'].toString()
              : "";
          _namaTenagaController.text = draf['nama_tenaga'] ?? "";
        });

        if (draf['denah'] != null) {
          List<dynamic> listDenah = draf['denah'];
          for (var d in listDenah) {
            String namaLantai = d['nama_lantai'];
            String pathServer = d['foto_denah_path'];
            String imageUrl = "http://10.0.2.2/api_konstruksi/$pathServer";
            try {
              var picResponse = await http.get(Uri.parse(imageUrl));
              if (picResponse.statusCode == 200) {
                setState(() {
                  _coretanSemuaDenah[namaLantai] = picResponse.bodyBytes;
                  _namaDenahTerpilih = namaLantai;
                });
              }
            } catch (e) {}
          }
        }

        if (draf['foto'] != null) {
          List<dynamic> listFoto = draf['foto'];
          Directory tempDir = Directory.systemTemp;
          for (int i = 0; i < listFoto.length; i++) {
            String pathServer = listFoto[i]['foto_path'];
            String imageUrl = "http://10.0.2.2/api_konstruksi/$pathServer";
            try {
              var picResponse = await http.get(Uri.parse(imageUrl));
              if (picResponse.statusCode == 200) {
                File tempFile = File(
                  '${tempDir.path}/img_lapangan_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
                );
                await tempFile.writeAsBytes(picResponse.bodyBytes);
                setState(() {
                  _fotoList.add(tempFile);
                });
              }
            } catch (e) {}
          }
        }
        _tampilkanPesan("Melanjutkan draf laporan hari ini...");
      }
    } catch (e) {}
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _tampilkanPesan("Layanan GPS tidak aktif.");
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
      _isLoadingGps = false;
    });
  }

  // --- MODIFIKASI: MENERIMA PARAMETER IMAGE SOURCE (CAMERA / GALLERY) ---
  Future<void> _ambilFoto(ImageSource source) async {
    if (_isPickingFoto) return;
    setState(() {
      _isPickingFoto = true;
    });
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 40,
        maxWidth: 1024,
      );
      if (photo != null) {
        if (!mounted) return;
        setState(() {
          _fotoList.add(File(photo.path));
        });
      }
    } catch (e) {
      _tampilkanPesan("Gagal mengambil foto: $e");
    } finally {
      if (mounted)
        setState(() {
          _isPickingFoto = false;
        });
    }
  }

  // --- FITUR BARU: BOTTOM SHEET PILILIHAN SUMBER FOTO ---
  void _tampilkanPilihanSumberFoto() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  "PILIH SUMBER FOTO",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Divider(color: Colors.grey[200], thickness: 1),
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(
                  "Kamera (Ambil Foto Langsung)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _ambilFoto(ImageSource.camera); // Buka Kamera
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                title: Text(
                  "Galeri (Pilih dari Handphone)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _ambilFoto(ImageSource.gallery); // Buka Galeri
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _hapusFoto(int index) {
    setState(() {
      _fotoList.removeAt(index);
    });
  }

  void _tampilkanPesan(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _bukaEditorDenah() async {
    if (_namaDenahTerpilih == null) return;

    Uint8List? dataCoretan;

    if (_coretanSemuaDenah.containsKey(_namaDenahTerpilih)) {
      dataCoretan = _coretanSemuaDenah[_namaDenahTerpilih];
    } else if (_masterDenahUrls.containsKey(_namaDenahTerpilih)) {
      _tampilkanPesan("Mengunduh denah master...");
      try {
        var response = await http.get(
          Uri.parse(_masterDenahUrls[_namaDenahTerpilih]!),
        );
        if (response.statusCode == 200) {
          dataCoretan = response.bodyBytes;
        }
      } catch (e) {
        _tampilkanPesan("Gagal mengunduh denah!");
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CanvasScreen(imageData: dataCoretan),
      ),
    );
    if (result != null) {
      if (!mounted) return;
      setState(() {
        _coretanSemuaDenah[_namaDenahTerpilih!] = result;
      });
    }
  }

  void _showPilihDenah() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  "PILIH DENAH PROYEK",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Divider(color: Colors.grey[200], thickness: 1),

              if (_isLoadingDenah)
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: actionGreen),
                  ),
                )
              else if (_pilihanDenah.isEmpty)
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "Belum ada master denah yang diunggah Admin untuk proyek ini.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ..._pilihanDenah.map((denah) {
                  bool sudahDicoret = _coretanSemuaDenah.containsKey(
                    denah['nama'],
                  );
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: actionGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.layers_outlined,
                        color: actionGreen,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      denah['nama']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sudahDicoret)
                          Icon(
                            Icons.check_circle,
                            color: actionGreen,
                            size: 18,
                          ),
                        if (sudahDicoret) SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _namaDenahTerpilih = denah['nama'];
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      _rincianController.clear();
      _volumeController.clear();
      _catatanController.clear();
      _jmlTukangController.clear();
      _namaTukangController.clear();
      _jmlTenagaController.clear();
      _namaTenagaController.clear();
      _selectedCuaca = 'Cerah';
      _selectedUnit = 'm²';
      _fotoList.clear();
      _coretanSemuaDenah.clear();
      _namaDenahTerpilih = null;
    });
    _tampilkanPesan("Form berhasil dikosongkan");
  }

  Future<void> _kirimRevisi() async {
    if (_rincianController.text.isEmpty) {
      _tampilkanPesan("Rincian pekerjaan tidak boleh kosong!");
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
          'jenis_laporan': 'HARIAN',
          'rincian': _rincianController.text,
          'cuaca': _selectedCuaca,
        },
      );

      var data = json.decode(response.body);
      if (data['status'] == 'success') {
        _tampilkanPesan("Revisi berhasil dikirim ulang ke Admin!");
        Navigator.pop(context, true);
      } else {
        _tampilkanPesan("Gagal revisi: ${data['message']}");
      }
    } catch (e) {
      _tampilkanPesan("Gagal terhubung ke server PHP.");
    } finally {
      if (mounted)
        setState(() {
          _isSubmitting = false;
        });
    }
  }

  Future<void> _simpanKeServer(String statusLaporan) async {
    if (statusLaporan == 'TERKIRIM' && _rincianController.text.isEmpty) {
      _tampilkanPesan("Rincian pekerjaan harus diisi sebelum dikirim!");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://10.0.2.2/api_konstruksi/submit_laporan.php"),
      );
      request.fields['id_project'] = widget.idProject;
      request.fields['id_user'] = widget.idUser;
      request.fields['cuaca'] = _selectedCuaca;
      request.fields['rincian'] = _rincianController.text;
      request.fields['volume'] = _volumeController.text.isEmpty
          ? "0"
          : _volumeController.text;
      request.fields['satuan'] = _selectedUnit;
      request.fields['catatan'] = _catatanController.text;
      request.fields['status'] = statusLaporan;

      request.fields['jml_tukang'] = _jmlTukangController.text.isEmpty
          ? "0"
          : _jmlTukangController.text;
      request.fields['nama_tukang'] = _namaTukangController.text;
      request.fields['jml_tenaga'] = _jmlTenagaController.text.isEmpty
          ? "0"
          : _jmlTenagaController.text;
      request.fields['nama_tenaga'] = _namaTenagaController.text;

      request.fields['latitude'] = _currentPosition?.latitude.toString() ?? "";
      request.fields['longitude'] =
          _currentPosition?.longitude.toString() ?? "";

      for (int i = 0; i < _fotoList.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto_lapangan[]',
            _fotoList[i].path,
          ),
        );
      }

      int denahIndex = 0;
      for (var entry in _coretanSemuaDenah.entries) {
        request.fields['nama_lantai[$denahIndex]'] = entry.key;
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_denah[]',
            entry.value,
            filename: 'denah_${denahIndex}.jpg',
          ),
        );
        denahIndex++;
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      try {
        var result = json.decode(responseData);
        if (result['status'] == 'success') {
          _tampilkanPesan(
            statusLaporan == 'DRAFT'
                ? "Draf disimpan!"
                : "Laporan berhasil dikirim!",
          );
          Navigator.pop(context, true);
        } else {
          _tampilkanPesan("Gagal menyimpan: ${result['message']}");
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Koneksi Error"),
          content: SingleChildScrollView(child: Text(e.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tutup"),
            ),
          ],
        ),
      );
    } finally {
      if (mounted)
        setState(() {
          _isSubmitting = false;
        });
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  "OPSI LAPORAN",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Divider(color: Colors.grey[200], thickness: 1),

              if (!widget.isRevisi)
                _buildOptionItem(
                  icon: Icons.save_outlined,
                  color: Colors.teal,
                  title: "Simpan Draft",
                  subtitle: "Lanjutkan nanti",
                  onTap: () {
                    Navigator.pop(context);
                    _simpanKeServer('DRAFT');
                  },
                ),

              _buildOptionItem(
                icon: Icons.refresh,
                color: Colors.orange,
                title: "Reset Form",
                subtitle: "Kosongkan semua isian",
                onTap: () {
                  Navigator.pop(context);
                  _resetForm();
                },
              ),
              _buildOptionItem(
                icon: Icons.delete_outline,
                color: Colors.redAccent,
                title: "Batalkan Laporan",
                subtitle: "Keluar tanpa menyimpan",
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: isDestructive ? Colors.redAccent : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDestructive
              ? Colors.redAccent.withOpacity(0.7)
              : Colors.grey,
        ),
      ),
      onTap: onTap,
    );
  }

  InputDecoration _inputDeco(String label, String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      labelStyle: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> namaHariList = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    DateTime now = DateTime.now();
    String tanggalFormatBaru =
        "${namaHariList[now.weekday - 1]}, ${DateFormat('dd MMM yyyy').format(now)}";
    bool adaCoretanSaatIni =
        _namaDenahTerpilih != null &&
        _coretanSemuaDenah.containsKey(_namaDenahTerpilih);
    String? urlMaster = _namaDenahTerpilih != null
        ? _masterDenahUrls[_namaDenahTerpilih]
        : null;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: widget.isRevisi ? Colors.orange[800] : primaryGreen,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isRevisi ? "Revisi Laporan Harian" : "Form Laporan Harian",
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
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                        "Mode Revisi: Silakan perbaiki teks rincian pekerjaan dan kondisi cuaca di bawah ini.",
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: textMuted,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "TANGGAL",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                tanggalFormatBaru,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: actionGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "GPS",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: actionGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _isLoadingGps ? "Mencari..." : "Terkunci ✓",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: actionGreen,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
            SizedBox(height: 24),

            if (!widget.isRevisi) ...[
              _buildSectionTitle(
                Icons.dashboard_customize_outlined,
                "Denah Pekerjaan",
                "",
              ),
              SizedBox(height: 8),
              InkWell(
                onTap: _showPilihDenah,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _namaDenahTerpilih == null
                          ? Colors.orange
                          : actionGreen,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.layers,
                        color: _namaDenahTerpilih == null
                            ? Colors.orange
                            : actionGreen,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _namaDenahTerpilih ?? "Pilih Denah Lantai...",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _namaDenahTerpilih == null
                                ? Colors.orange[700]
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_circle_outlined,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              if (_namaDenahTerpilih != null) ...[
                SizedBox(height: 12),
                InkWell(
                  onTap: _bukaEditorDenah,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: actionGreen.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: adaCoretanSaatIni
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _coretanSemuaDenah[_namaDenahTerpilih!]!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (urlMaster != null
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        urlMaster,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white54,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 32,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Ketuk untuk Coret ${_namaDenahTerpilih}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    "Gambar master tidak ditemukan",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )),
                  ),
                ),
              ],
              SizedBox(height: 24),
            ],

            _buildSectionTitle(Icons.cloud_outlined, "Cuaca", ""),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWeatherOption(
                  'Cerah',
                  Icons.wb_sunny_outlined,
                  Colors.orange,
                ),
                _buildWeatherOption('Berawan', Icons.cloud_queue, textMuted),
                _buildWeatherOption(
                  'Hujan',
                  Icons.water_drop_outlined,
                  Colors.blue,
                ),
                _buildWeatherOption(
                  'Badai',
                  Icons.thunderstorm_outlined,
                  Colors.indigo,
                ),
              ],
            ),
            SizedBox(height: 24),

            if (!widget.isRevisi) ...[
              _buildSectionTitle(
                Icons.people_alt_outlined,
                "Tenaga Kerja",
                "(Tukang & Tenaga)",
              ),
              SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _jmlTukangController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco("Jml Tukang", "Misal: 2"),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _namaTukangController,
                      decoration: _inputDeco(
                        "Nama Tukang",
                        "Misal: Budi, Anto...",
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _jmlTenagaController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco("Jml Tenaga", "Misal: 5"),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _namaTenagaController,
                      decoration: _inputDeco(
                        "Nama Tenaga",
                        "Misal: Joko, Andi, dkk...",
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],

            _buildSectionTitle(Icons.list_alt, "Langkah Pengerjaan", ""),
            SizedBox(height: 8),
            TextField(
              controller: _rincianController,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Pengecoran lantai 3 zona B sudah selesai...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
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

            if (!widget.isRevisi) ...[
              _buildSectionTitle(
                Icons.square_foot_outlined,
                "Volume Pekerjaan",
                "",
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _volumeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Misal: 10",
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
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 55,
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          _buildUnitOption('m²'),
                          _buildUnitOption('m³'),
                          _buildUnitOption('unit'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              _buildSectionTitle(
                Icons.camera_alt_outlined,
                "Foto Dokumentasi",
                "",
              ),
              SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...List.generate(_fotoList.length, (index) {
                      return Container(
                        margin: EdgeInsets.only(right: 12),
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: actionGreen, width: 2),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _fotoList[index],
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _hapusFoto(index),
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.red,
                                  child: Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // --- MODIFIKASI: ONTAP SEKARANG MEMANGGIL PILIHAN SUMBER FOTO ---
                    InkWell(
                      onTap: _tampilkanPilihanSumberFoto,
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: actionGreen.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              color: actionGreen,
                              size: 28,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Tambah foto",
                              style: TextStyle(
                                color: actionGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],

            _buildSectionTitle(Icons.notes, "Catatan Tambahan", "(opsional)"),
            SizedBox(height: 8),
            TextField(
              controller: _catatanController,
              maxLines: 2,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Tambahkan catatan lapangan jika ada...",
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
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
                          : _simpanKeServer('TERKIRIM'),
                icon: _isSubmitting
                    ? SizedBox.shrink()
                    : Icon(Icons.send, color: Colors.white, size: 20),
                label: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.isRevisi ? "KIRIM REVISI" : "KIRIM LAPORAN",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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

  Widget _buildWeatherOption(String cuaca, IconData icon, Color iconColor) {
    bool isSelected = _selectedCuaca == cuaca;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCuaca = cuaca;
          });
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.orange : textMuted,
                size: 24,
              ),
              SizedBox(height: 8),
              Text(
                cuaca,
                style: TextStyle(
                  color: isSelected ? Colors.orange : textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitOption(String unit) {
    bool isSelected = _selectedUnit == unit;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUnit = unit;
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? actionGreen.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: actionGreen) : null,
          ),
          child: Text(
            unit,
            style: TextStyle(
              color: isSelected ? actionGreen : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
