import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'dart:convert';
import '../auth/login.dart'; // Pastikan jalur ini sesuai dengan struktur proyek Anda

class QuizPage extends StatefulWidget {
  final String token;
  final String subMateriId;
  final String latihanId;

  const QuizPage({
    Key? key,
    required this.token,
    required this.subMateriId,
    required this.latihanId,
  }) : super(key: key);

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with SingleTickerProviderStateMixin {
  final pb = PocketBase('http://127.0.0.1:8090');
  List<Map<String, dynamic>> soalKuis = [];
  Map<int, String> jawabanPengguna = {};
  bool isLoading = true;
  String errorMessage = '';
  int currentSoalIndex = 0;
  bool quizSelesai = false;
  double skor = 0;
  String? latihanNama;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    print('Using token: ${widget.token}');
    pb.authStore.save(widget.token, null);
    refreshAuth(); // Panggil refreshAuth saat inisialisasi
    fetchLatihanNama();
    fetchSoalKuis();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Metode untuk menyegarkan autentikasi
  Future<void> refreshAuth() async {
    try {
      final authData = await pb.collection('users').authRefresh();
      print('Autentikasi berhasil diperbarui: ${authData.record?.data}');
    } catch (e) {
      print('Gagal menyegarkan autentikasi: $e');
      setState(() {
        errorMessage = 'Autentikasi gagal. Silakan login kembali.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Autentikasi gagal. Silakan login kembali.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<void> fetchLatihanNama() async {
    try {
      final response = await pb.collection('latihan').getOne(widget.latihanId);
      print('Latihan Response: ${response.data}');
      setState(() {
        latihanNama = response.data['nama'] ?? 'Latihan';
      });
    } catch (e) {
      print('Gagal mengambil nama latihan: $e');
      setState(() {
        latihanNama = 'Latihan';
        errorMessage = 'Gagal mengambil nama latihan: $e';
      });
    }
  }

  Future<void> fetchSoalKuis() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final response = await pb.collection('soal_kuis').getList(
        filter: 'latihan = "${widget.latihanId}"',
        sort: 'nomor_soal',
      );
      print('Soal Kuis Response: ${response.items.map((item) => item.toJson())}');
      setState(() {
        soalKuis = response.items.map((item) => item.toJson()).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Gagal mengambil soal: $e');
      setState(() {
        errorMessage = 'Gagal mengambil soal: $e';
        isLoading = false;
      });
    }
  }

  void pilihJawaban(String jawaban) {
    setState(() {
      jawabanPengguna[currentSoalIndex + 1] = jawaban;
    });

    if (currentSoalIndex < soalKuis.length - 1) {
      setState(() {
        currentSoalIndex++;
      });
    } else {
      hitungSkorDanSimpan();
    }
  }

  Future<void> hitungSkorDanSimpan() async {
    int jumlahBenar = 0;
    for (int i = 0; i < soalKuis.length; i++) {
      if (jawabanPengguna[i + 1] == soalKuis[i]['jawaban_benar']) {
        jumlahBenar++;
      }
    }
    setState(() {
      skor = (jumlahBenar / soalKuis.length) * 100;
      quizSelesai = true;
    });

    try {
      // Pastikan autentikasi diperbarui sebelum menyimpan
      await refreshAuth();

      // Pengecekan ulang autentikasi
      if (!pb.authStore.isValid || pb.authStore.model?.id == null) {
        throw Exception('Pengguna tidak terautentikasi setelah refresh. Silakan login kembali.');
      }

      // Konversi jawabanPengguna ke Map<String, dynamic> untuk JSON
      final jawabanPenggunaJson = jawabanPengguna.map((key, value) => MapEntry(key.toString(), value));

      // Simpan hasil ke PocketBase
      final response = await pb.collection('hasil_kuis').create(
        body: {
          'user': pb.authStore.model!.id,
          'sub_materi': widget.subMateriId,
          'latihan': widget.latihanId,
          'skor': skor,
          'jawaban_pengguna': jsonEncode(jawabanPenggunaJson),
        },
      );

      print('Hasil kuis berhasil disimpan: ${response.toJson()}');
      _animationController.forward();
    } catch (e) {
      print('Gagal menyimpan hasil kuis: $e');
      setState(() {
        errorMessage = 'Gagal menyimpan hasil kuis: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan hasil kuis: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Arahkan ke login jika autentikasi gagal
      if (e.toString().contains('unauthorized') || e.toString().contains('autentikasi')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF0),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : soalKuis.isEmpty
                ? const Center(child: Text('Tidak ada soal tersedia', style: TextStyle(fontSize: 18)))
                : quizSelesai
                    ? Center(
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Latihan Selesai',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.green, width: 8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${skor.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Selamat!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Kamu mendapatkan ${skor.toStringAsFixed(0)}% jawaban benar',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  'Selesai',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (errorMessage.isNotEmpty)
                              Text(
                                'Error: $errorMessage',
                                style: const TextStyle(color: Colors.red, fontSize: 16),
                              ),
                            // Perbaikan: Letakkan nama latihan di atas nomor soal
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF001A6E),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                latihanNama ?? 'Latihan',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Indikator nomor soal di bawah nama latihan
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                  soalKuis.length,
                                  (index) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: index == currentSoalIndex
                                              ? Colors.green
                                              : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: index == currentSoalIndex
                                            ? Colors.green
                                            : jawabanPengguna.containsKey(index + 1)
                                                ? Colors.blue.withOpacity(0.7)
                                                : Colors.grey[300],
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Soal ${currentSoalIndex + 1}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              soalKuis[currentSoalIndex]['pertanyaan'] ?? 'Pertanyaan tidak tersedia',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: ListView.builder(
                                itemCount: (soalKuis[currentSoalIndex]['pilihan_jawaban'] as List).length,
                                itemBuilder: (context, index) {
                                  final jawaban = (soalKuis[currentSoalIndex]['pilihan_jawaban'] as List)[index];
                                  final isSelected = jawabanPengguna[currentSoalIndex + 1] == jawaban;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                                    child: Card(
                                      elevation: isSelected ? 5 : 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      color: isSelected ? Colors.blue.withOpacity(0.9) : Colors.white,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                        title: Text(
                                          jawaban,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: isSelected ? Colors.white : Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        onTap: () => pilihJawaban(jawaban),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: currentSoalIndex > 0
                                      ? () {
                                          setState(() {
                                            currentSoalIndex--;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
                                  label: const Text(
                                    'Kembali',
                                    style: TextStyle(fontSize: 18, color: Colors.black),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 5,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: jawabanPengguna[currentSoalIndex + 1] != null
                                      ? () {
                                          if (currentSoalIndex < soalKuis.length - 1) {
                                            setState(() {
                                              currentSoalIndex++;
                                            });
                                          } else {
                                            hitungSkorDanSimpan();
                                          }
                                        }
                                      : null,
                                  icon: Icon(
                                    currentSoalIndex < soalKuis.length - 1
                                        ? Icons.arrow_forward_ios
                                        : Icons.check,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    currentSoalIndex < soalKuis.length - 1 ? 'Lanjut' : 'Selesai',
                                    style: const TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
      ),
    ),
  );
}
}