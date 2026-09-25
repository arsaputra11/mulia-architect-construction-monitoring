import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureText = true;
  bool _kunciGps = true;

  final String apiUrl = "http://10.0.2.2/api_konstruksi/login.php";
  final String apiLupaPasswordUrl =
      "http://10.0.2.2/api_konstruksi/lupa_password.php"; // API Baru

  void _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Isi Username dan Password!")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        body: {
          "username": _usernameController.text,
          "password": _passwordController.text,
        },
      );

      var data = json.decode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Berhasil Login!"),
            backgroundColor: Colors.green,
          ),
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              namaPengawas: data['nama_lengkap'] ?? 'Pengawas',
              idUser: data['id_user']?.toString() ?? '0',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error koneksi ke server: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- FUNGSI TAMPIL DIALOG LUPA PASSWORD ---
  void _tampilDialogLupaPassword() {
    TextEditingController resetUsernameCtrl = TextEditingController();
    bool isSubmitting = false;

    // Warna tema untuk pop-up agar senada dengan halaman login
    const Color bgDark = Color(0xFF091F14);
    const Color cardDark = Color(0xFF132A1C);
    const Color primaryGreen = Color(0xFF48BB78);
    const Color textMuted = Color(0xFF6B8A7A);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: cardDark, // Tema gelap
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: primaryGreen.withOpacity(0.3)),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_reset, color: primaryGreen),
                  SizedBox(width: 8),
                  Text(
                    "Lupa Password?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Masukkan ID pengguna (Username) Anda. Jika terdaftar, password akan direset menjadi default: 123456",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: resetUsernameCtrl,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: bgDark,
                      hintText: "Masukkan Username...",
                      hintStyle: TextStyle(
                        color: textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                      prefixIcon: Icon(Icons.person_outline, color: textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: Text("Batal", style: TextStyle(color: textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (resetUsernameCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Username tidak boleh kosong!"),
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
                              Uri.parse(apiLupaPasswordUrl),
                              body: {'username': resetUsernameCtrl.text},
                            );
                            var data = json.decode(res.body);

                            if (data['status'] == 'success') {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(data['message']),
                                  backgroundColor: Colors.green,
                                  duration: Duration(
                                    seconds: 5,
                                  ), // Notif agak lama biar mandor sempat baca
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
                          "Reset Password",
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

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF091F14);
    const Color cardDark = Color(0xFF132A1C);
    const Color primaryGreen = Color(0xFF48BB78);
    const Color textMuted = Color(0xFF6B8A7A);

    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- INI LOGO YANG SUDAH DIGANTI ---
              Image.asset(
                'assets/logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),

              // -----------------------------------
              SizedBox(height: 16),
              Text(
                "mulia architect",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "SISTEM PEMANTAUAN PROYEK",
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 40),

              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Masuk ke akun Anda",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 20),

                    TextField(
                      controller: _usernameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cardDark,
                        hintText: "Masukkan ID pengguna...",
                        hintStyle: TextStyle(
                          color: textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: textMuted,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cardDark,
                        hintText: "••••••••",
                        hintStyle: TextStyle(color: textMuted),
                        prefixIcon: Icon(Icons.lock_outline, color: textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: textMuted,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cardDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: textMuted),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Kunci GPS otomatis",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "Koordinat dikunci saat login",
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _kunciGps,
                            activeColor: Colors.white,
                            activeTrackColor: primaryGreen,
                            inactiveThumbColor: textMuted,
                            inactiveTrackColor: bgDark,
                            onChanged: (val) {
                              setState(() {
                                _kunciGps = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed:
                            _tampilDialogLupaPassword, // EKSEKUSI DI SINI
                        child: Text(
                          "Lupa password?",
                          style: TextStyle(color: primaryGreen),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "MASUK SEKARANG",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 32),

              Text(
                "Belum punya akun? Hubungi Admin",
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, color: textMuted, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "Dilindungi enkripsi end-to-end",
                    style: TextStyle(color: textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
