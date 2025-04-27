import 'package:capstone/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Navigasi Flutter',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class HalamanUtama extends StatelessWidget {
  const HalamanUtama({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman Utama')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Ke Halaman Kedua'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HalamanKedua()),
            );
          },
        ),
      ),
    );
  }
}



class HalamanKedua extends StatelessWidget {
  const HalamanKedua({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman Kedua')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Kembali'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
