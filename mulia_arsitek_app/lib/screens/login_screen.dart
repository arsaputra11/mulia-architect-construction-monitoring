import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // PALET WARNA EMERALD PRECISION (DARK MODE)
  final Color primaryDarkEmerald = const Color(0xFF1A4D3E); // Hijau Tua Utama
  final Color accentSage = const Color(0xFF9DC183); // Hijau Sage Aksen
  final Color darkCanvas = const Color(0xFF0A211A); // Background Sangat Tua

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Harap isi User ID dan Password", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      var url = Uri.parse('http://10.0.2.2/api_arsitek/login.php');
      var response = await http.post(
        url,
        body: {
          'username': _usernameController.text,
          'password': _passwordController.text,
        },
      );

      var data = json.decode(response.body);

      if (data['status'] == 'success') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(userData: data['data']),
          ),
        );
      } else {
        _showSnackBar(data['pesan'], Colors.red);
      }
    } catch (e) {
      _showSnackBar(
        "Gagal terhubung ke server. Pastikan Laragon aktif.",
        Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: const TextStyle(color: Colors.white)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkCanvas, // Latar belakang gelap sesuai referensi
      body: Stack(
        children: [
          // Dekorasi Lingkaran Abstrak di Background (Agar tidak kaku)
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: accentSage.withOpacity(0.05),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO BAGIAN ATAS ---
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/images/logo_mulia.png',
                      height:
                          180, // Ukuran logo sedikit lebih besar agar menonjol
                      fit: BoxFit.contain,
                      // Jika file belum ada, tampilkan icon pengganti agar tidak error
                      errorBuilder: (context, error, stackTrace) => Column(
                        children: [
                          Icon(
                            Icons.architecture,
                            size: 100,
                            color: accentSage,
                          ),
                          const Text(
                            "Logo Belum Terpasang",
                            style: TextStyle(color: Colors.white24),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "DESIGNING PROSPERITY",
                    style: TextStyle(
                      color: accentSage.withOpacity(0.7),
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // --- FORM LOGIN ---
                  // Input User ID
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      hintText: "User ID",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: Icon(Icons.person_outline, color: accentSage),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: accentSage, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Password
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      hintText: "Password",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: Icon(Icons.lock_outline, color: accentSage),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: accentSage, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- TOMBOL LOGIN ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            accentSage, // Tombol hijau sage sesuai gambar
                        foregroundColor: primaryDarkEmerald,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        shadowColor: accentSage.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFF1A4D3E),
                            )
                          : const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text(
                    "© 2024 Mulia Architect Group",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
