import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'quizpage.dart'; // Impor QuizPage

class LatihanPage extends StatefulWidget {
  final String token;

  const LatihanPage({Key? key, required this.token}) : super(key: key);

  @override
  _LatihanPageState createState() => _LatihanPageState();
}

class _LatihanPageState extends State<LatihanPage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  Map<String, List<Map<String, dynamic>>> latihanByCategory = {};
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    print('Using token: ${widget.token}');
    pb.authStore.save(widget.token, null);
    fetchLatihan();
  }

  Future<void> fetchLatihan() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      print('Fetching latihan from PocketBase...');
      final response = await pb.collection('latihan').getList();
      print('Response from PocketBase (latihan): ${response.items}');

      // Filter dan kelompokkan latihan berdasarkan kategori
      final allLatihan = response.items.map((item) => item.toJson()).toList();
      final Map<String, List<Map<String, dynamic>>> groupedLatihan = {};
      for (var latihan in allLatihan) {
        final category = latihan['category'] ?? 'Lainnya';
        if (!groupedLatihan.containsKey(category)) {
          groupedLatihan[category] = [];
        }
        groupedLatihan[category]!.add(latihan);
      }

      setState(() {
        latihanByCategory = groupedLatihan;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching latihan: $e');
      setState(() {
        latihanByCategory = {};
        errorMessage = 'Gagal mengambil latihan: $e';
        isLoading = false;
      });
    }
  }

  void _startQuiz(String latihanId, String subMateriId, String latihanNama) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPage(
          token: widget.token,
          subMateriId: subMateriId, // Ganti dengan ID sub_materi yang sesuai
          latihanId: latihanId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Latihan',
          style: TextStyle(
            color: Colors.white, // Mengatur warna teks menjadi putih
          ),
        ),
        backgroundColor: const Color(0xFF001A6E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
              : latihanByCategory.isEmpty
                  ? const Center(child: Text('Tidak ada latihan tersedia'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: latihanByCategory.entries.map((entry) {
                          final category = entry.key;
                          final latihanList = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 255, 255, 255),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...latihanList.map((latihan) {
                                final latihanId = latihan['id'];
                                final latihanNama = latihan['nama'] ?? 'Nama Tidak Tersedia';
                                final jumlahSoal = latihan['jumlah_soal'] ?? 0;
                                // Misalnya, ambil sub_materi_id dari latihan (pastikan ada di data)
                                final subMateriId = latihan['sub_materi'] ?? ''; // Ganti dengan field yang sesuai
                                return Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        blurRadius: 5,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            latihanNama,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '$jumlahSoal Pertanyaan',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'Inter',
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  category,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontFamily: 'Inter',
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.play_circle_fill,
                                          color: Color(0xFF001A6E),
                                          size: 32,
                                        ),
                                        onPressed: () => _startQuiz(latihanId, subMateriId, latihanNama),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 10),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
    );
  }
}