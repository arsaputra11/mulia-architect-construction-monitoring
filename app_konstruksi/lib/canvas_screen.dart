import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';
import 'dart:typed_data';

class CanvasScreen extends StatefulWidget {
  final Uint8List? imageData;

  CanvasScreen({this.imageData});

  @override
  _CanvasScreenState createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  // PERBAIKAN ERROR: Menggunakan freeStyle agar cocok dengan versi package-mu
  final ImagePainterController _controller = ImagePainterController(
    color: Color(0xFF48BB78),
    strokeWidth: 4.0,
    mode: PaintMode.freeStyle,
  );

  Color _selectedColor = Color(0xFF48BB78);
  double _selectedThickness = 4.0;

  final String dummyUrl =
      "https://t3.ftcdn.net/jpg/04/86/60/44/360_F_486604473_eRAszFmbx8GvU4gG16Tms9r3gT1m6Z9p.jpg";

  // Warna Tema (Persis gambar pertama yang elegan)
  final Color bgDark = Color(0xFF091F14);
  final Color cardDark = Color(0xFF132A1C);
  final Color greenAccent = Color(0xFF48BB78);
  final Color textMuted = Color(0xFF6B8A7A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,

      // --- APP BAR PREMIUM ---
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Tandai Area Denah",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: greenAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: greenAccent, size: 24),
            ),
            tooltip: "Simpan Coretan",
            onPressed: () async {
              Uint8List? imageBytes = await _controller.exportImage();
              if (!mounted) return;
              Navigator.pop(context, imageBytes);
            },
          ),
          SizedBox(width: 8),
        ],
      ),

      body: Stack(
        children: [
          // --- KANVAS GAMBAR ---
          Positioned.fill(
            child: widget.imageData != null
                ? ImagePainter.memory(
                    widget.imageData!,
                    controller: _controller,
                    scalable: true,
                    showControls: false, // Mematikan toolbar bawaan
                  )
                : ImagePainter.network(
                    dummyUrl,
                    controller: _controller,
                    scalable: true,
                    showControls: false,
                  ),
          ),

          // --- TOOLBAR MELAYANG (FLOATING PILL Sesuai Desain) ---
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Undo
                  _buildToolbarIcon(Icons.undo_rounded, () {
                    _controller.undo();
                  }),

                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white10,
                  ), // Garis Pembatas
                  // Pencil (Aktif dengan titik hijau)
                  _buildPencilTool(),

                  // Warna
                  _buildColorPickerTool(),

                  // Ketebalan
                  _buildThicknessTool(),

                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white10,
                  ), // Garis Pembatas
                  // Hapus Semua
                  _buildToolbarIcon(Icons.delete_outline_rounded, () {
                    _controller.clear();
                  }, color: Colors.red[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BANTUAN UI TOOLBAR ---

  Widget _buildToolbarIcon(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Icon(icon, color: color ?? textMuted, size: 24),
      ),
    );
  }

  Widget _buildPencilTool() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.edit, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: greenAccent, shape: BoxShape.circle),
        ), // Indikator aktif
      ],
    );
  }

  Widget _buildColorPickerTool() {
    return InkWell(
      onTap: _showColorPickerDialog,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Container(
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 1),
          ),
          child: CircleAvatar(radius: 10, backgroundColor: _selectedColor),
        ),
      ),
    );
  }

  Widget _buildThicknessTool() {
    return InkWell(
      onTap: _showThicknessModal,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Icon(Icons.line_weight_rounded, color: Colors.white70, size: 24),
      ),
    );
  }

  // --- MODAL & DIALOG ---

  void _showColorPickerDialog() {
    List<Color> pickColors = [
      Color(0xFF48BB78),
      Colors.red,
      Colors.blue,
      Colors.yellow,
      Colors.black,
      Colors.white,
    ];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Pilih Warna Tinta",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: pickColors.map((color) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                  _controller.setColor(color);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color == Colors.white
                          ? Colors.black26
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (color == _selectedColor)
                        BoxShadow(
                          color: greenAccent.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: color == _selectedColor
                      ? Icon(
                          Icons.check,
                          color: color == Colors.white
                              ? Colors.black
                              : Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showThicknessModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Atur Ketebalan Garis",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.circle, color: textMuted, size: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: greenAccent,
                            inactiveTrackColor: Colors.white10,
                            thumbColor: Colors.white,
                            overlayColor: greenAccent.withOpacity(0.2),
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value: _selectedThickness,
                            min: 1,
                            max: 20,
                            divisions: 19,
                            onChanged: (val) {
                              setModalState(() {
                                _selectedThickness = val;
                              });
                              setState(() {
                                _selectedThickness = val;
                              });
                              _controller.setStrokeWidth(val);
                            },
                          ),
                        ),
                      ),
                      Icon(Icons.circle, color: textMuted, size: 24),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
