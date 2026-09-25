import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MuliaArsitekApp());
}

class MuliaArsitekApp extends StatelessWidget {
  const MuliaArsitekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mulia Arsitek',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
