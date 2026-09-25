import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pemantauan Konstruksi',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Langsung arahkan ke halaman Login saat aplikasi dibuka
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
