import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'riwayat_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _proyekController = TextEditingController(
    text: "1",
  );
  final TextEditingController _persentaseController = TextEditingController();

  String _latitude = "Belum didapatkan";
  String _longitude = "Belum didapatkan";
  bool _isLoadingLokasi = false;
  bool _isSubmitting = false;

  XFile? _fotoProgres;
  final ImagePicker _picker = ImagePicker();

  // Warna Tema Emerald Precision
  final Color primaryEmerald = const Color(0xFF1A4D3E);
  final Color sageGreen = const Color(0xFF9DC183);
  final Color bgLight = const Color(0xFFF4F7F5);

  Future<void> _dapatkanLokasiAsli() async {
    setState(() => _isLoadingLokasi = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled)
        throw Exception('Layanan GPS tidak aktif pada perangkat.');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw Exception('Izin akses lokasi ditolak.');
      }
      if (permission == LocationPermission.deniedForever)
        throw Exception('Izin lokasi ditolak permanen.');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoadingLokasi = false);
    }
  }

  Future<void> _ambilFoto() async {
    final XFile? fotoPilihan = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 25,
    );
    if (fotoPilihan != null) setState(() => _fotoProgres = fotoPilihan);
  }

  Future<void> _kirimLaporan() async {
    if (_persentaseController.text.isEmpty ||
        _latitude == "Belum didapatkan" ||
        _fotoProgres == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Pastikan Progres Fisik, GPS, dan Foto sudah dilengkapi!",
          ),
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      var uri = Uri.parse('http://10.0.2.2/api_arsitek/submit_laporan.php');
      var request = http.MultipartRequest('POST', uri);
      request.fields['id_proyek'] = _proyekController.text;
      request.fields['id_user'] = widget.userData['id'].toString();
      request.fields['persentase_fisik'] = _persentaseController.text;
      request.fields['latitude'] = _latitude;
      request.fields['longitude'] = _longitude;
      var fotoBytes = await _fotoProgres!.readAsBytes();
      var multipartFile = http.MultipartFile.fromBytes(
        'foto',
        fotoBytes,
        filename: _fotoProgres!.name,
      );
      request.files.add(multipartFile);
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      if (responseData.startsWith('<'))
        throw Exception("Peladen error HTML. Periksa Debug Console!");
      var jsonResponse = json.decode(responseData);
      if (jsonResponse['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonResponse['pesan']),
            backgroundColor: primaryEmerald,
          ),
        );
        setState(() {
          _persentaseController.clear();
          _fotoProgres = null;
          _latitude = "Belum didapatkan";
          _longitude = "Belum didapatkan";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonResponse['pesan']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengirim: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text(
          "Form Laporan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryEmerald,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RiwayatScreen(idUser: widget.userData['id'].toString()),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Sambutan
            Text(
              "Selamat datang,",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            Text(
              widget.userData['nama'],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryEmerald,
              ),
            ),
            const SizedBox(height: 30),

            // Kartu Input Progres
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryEmerald.withOpacity(0.05),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Progres Fisik Lapangan",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryEmerald,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _persentaseController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Contoh: 75",
                      suffixText: "%",
                      suffixStyle: TextStyle(
                        color: primaryEmerald,
                        fontWeight: FontWeight.bold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryEmerald, width: 2),
                      ),
                      filled: true,
                      fillColor: bgLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kartu GPS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryEmerald.withOpacity(0.05),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sageGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: primaryEmerald,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lokasi GPS",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryEmerald,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Lat: $_latitude\nLon: $_longitude",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _isLoadingLokasi
                      ? const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(),
                        )
                      : ElevatedButton(
                          onPressed: _dapatkanLokasiAsli,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sageGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Ambil",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kartu Kamera
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _fotoProgres == null
                      ? Colors.grey.shade300
                      : sageGreen,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryEmerald.withOpacity(0.05),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 45,
                    color: _fotoProgres == null
                        ? Colors.grey.shade400
                        : primaryEmerald,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _fotoProgres == null
                        ? "Belum ada foto progres"
                        : "Visual Evidence Tersimpan",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _fotoProgres == null
                          ? Colors.grey.shade600
                          : primaryEmerald,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _ambilFoto,
                    icon: const Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      "Pilih Foto",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryEmerald,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Tombol Kirim Utama
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _kirimLaporan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryEmerald,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "KIRIM LAPORAN",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
