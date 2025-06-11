import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 253, 234),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Image.asset(
            'assets/image1.png',
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading image1.png: $error'); // Log error
              print('Stack trace: $stackTrace'); // Log stack trace
              return const Icon(Icons.error, color: Colors.red, size: 120);
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (frame == null) {
                print('Loading image1.png...'); // Log saat gambar sedang dimuat
                return const CircularProgressIndicator();
              }
              print('image1.png loaded successfully!'); // Log saat gambar selesai dimuat
              return child;
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'QuizCode',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Aplikasi untuk mempelajari implementasi coding dalam bentuk quiz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 280,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Masuk',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 280,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 35, 91),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Daftar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}