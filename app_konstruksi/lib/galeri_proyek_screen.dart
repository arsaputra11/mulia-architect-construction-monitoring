import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // MAP UNTUK MENGELOMPOKKAN FOTO BERDASARKAN TANGGAL
  Map<String, List<Map<String, dynamic>>> _groupedPhotos = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGaleri();
  }

  // --- FUNGSI TARIK DATA FOTO DARI DATABASE ---
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
        _groupPhotos(); // Kelompokkan foto setelah data ditarik
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetch galeri: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- FUNGSI MENGELOMPOKKAN FOTO KE DALAM "ALBUM HARIAN" ---
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

      // Jika ada filter tanggal dari kalender, lewati yang tidak cocok
      if (_selectedDate != null) {
        String selectedDateStr = DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDate!);
        if (photo['date'] != selectedDateStr) continue;
      }

      // Format menjadi "Sabtu, 30 May 2026"
      String namaHari = namaHariList[dateObj.weekday - 1];
      String tglFormat =
          "$namaHari, ${DateFormat('dd MMM yyyy').format(dateObj)}";

      // Masukkan ke dalam grup/folder tanggal tersebut
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

  // --- FUNGSI LIHAT FOTO FULL SCREEN (ZOOM) ---
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
            tooltip: "Filter Tanggal",
            onPressed: () => _pilihTanggal(context),
          ),
          if (_selectedDate != null)
            IconButton(
              icon: Icon(Icons.filter_alt_off, color: Colors.white),
              tooltip: "Hapus Filter",
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
                              // Theme ini digunakan agar garis batas (border) saat ditekan tidak muncul
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  // Buka otomatis hanya untuk tanggal yang paling atas (paling baru)
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
                                        shrinkWrap:
                                            true, // Wajib ada agar tidak error di dalam ListView
                                        physics:
                                            NeverScrollableScrollPhysics(), // Scroll mengikuti ListView induk
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
