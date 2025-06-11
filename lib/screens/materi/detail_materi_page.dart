import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'materi_web_page.dart';

class DetailMateriPage extends StatefulWidget {
  final String token;
  final String materiId;
  final String categoryId;

  const DetailMateriPage({
    Key? key,
    required this.token,
    required this.materiId,
    required this.categoryId,
  }) : super(key: key);

  @override
  _DetailMateriPageState createState() => _DetailMateriPageState();
}

class _DetailMateriPageState extends State<DetailMateriPage> {
  final pb = PocketBase('http://127.0.0.1:8090'); // Sesuaikan dengan http://10.0.2.2:8090 jika pakai emulator
  Map<String, dynamic> materiDetail = {};
  String categoryName = 'Loading...';
  bool isLoading = true;
  String errorMessage = '';
  List<String> kontenSections = []; // Untuk menyimpan bagian konten

  @override
  void initState() {
    super.initState();
    print('Using token in DetailMateriPage: ${widget.token}');
    print('Materi ID: ${widget.materiId}, Category ID: ${widget.categoryId}');

    pb.authStore.save(widget.token, null);
    print('Auth Store isValid: ${pb.authStore.isValid}');
    print('Auth Token: ${pb.authStore.token}');

    fetchMateriDetail();
  }

  Future<void> fetchMateriDetail() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('Attempting to fetch materi with ID: ${widget.materiId}');
      final materiResponse = await pb.collection('materi').getOne(widget.materiId);
      print('Materi Response: $materiResponse');
      print('Materi Data: ${materiResponse.data}');

      if (!mounted) return;
      String materiCategoryId = materiResponse.data['category'] ?? widget.categoryId;
      await fetchCategoryName(materiCategoryId);

      // Proses konten menjadi bagian-bagian berdasarkan newline ganda
      String rawKonten = materiResponse.data['konten'] ?? materiResponse.data['sub_materi'] ?? 'Konten Tidak Tersedia';
      kontenSections = rawKonten.split('\n\n').map((section) => section.trim()).where((section) => section.isNotEmpty).toList();
      if (kontenSections.isEmpty) kontenSections = [rawKonten];

      setState(() {
        materiDetail = {
          'tittle': materiResponse.data['tittle'] ?? 'Judul Tidak Tersedia',
          'description': materiResponse.data['description'] ?? 'Deskripsi Tidak Tersedia',
          'konten': rawKonten,
        };
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching materi detail: $e');
      if (!mounted) return;
      setState(() {
        errorMessage = 'Gagal memuat detail materi: $e. Materi ID: ${widget.materiId}';
        materiDetail = {
          'tittle': 'Judul Tidak Tersedia',
          'description': 'Deskripsi Tidak Tersedia',
          'konten': 'Konten Tidak Tersedia',
        };
        kontenSections = ['Konten Tidak Tersedia'];
        isLoading = false;
      });
    }
  }

  Future<void> fetchCategoryName(String categoryId) async {
    if (!mounted) return;

    try {
      print('Attempting to fetch category with ID: $categoryId');
      final categoryResponse = await pb.collection('kategori').getOne(categoryId);
      print('Category Response: $categoryResponse');
      print('Category Data: ${categoryResponse.data}');

      if (!mounted) return;
      setState(() {
        categoryName = categoryResponse.data['name'] ?? 'Kategori Tidak Diketahui';
      });
    } catch (e) {
      print('Error fetching category name: $e');
      if (!mounted) return;
      setState(() {
        categoryName = 'Kategori Tidak Diketahui';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          materiDetail['tittle'] ?? 'Materi',
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
        ),
        backgroundColor: const Color(0xFF001A6E),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Text(
              'Materi',
              style: TextStyle(fontSize: 18, fontFamily: 'Inter', color: Colors.white),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF001A6E),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul
                        Text(
                          materiDetail['tittle'] ?? 'Judul Tidak Tersedia',
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Kategori
                        Row(
                          children: [
                            const Icon(
                              Icons.category,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Kategori: $categoryName',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Inter',
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Deskripsi
                        const Text(
                          'Deskripsi:',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          materiDetail['description'] ?? 'Deskripsi Tidak Tersedia',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Inter',
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Konten
                        const Text(
                          'Konten:',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...kontenSections.map((section) {
                          // Jika section adalah kode (dimulai dengan <!DOCTYPE html>)
                          if (section.startsWith('<!DOCTYPE html>')) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                color: Colors.black.withOpacity(0.2),
                                child: Text(
                                  section,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace', // Untuk tampilan kode
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            );
                          }
                          // Jika section adalah list (dimulai dengan "- ")
                          else if (section.contains('\n') && section.split('\n').any((line) => line.trim().startsWith('-'))) {
                            final items = section.split('\n').where((item) => item.trim().isNotEmpty).toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Judul section (jika ada sebelum list)
                                if (!items[0].startsWith('-'))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      items[0],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                // List items
                                ...items.skip(items[0].startsWith('-') ? 0 : 1).map((item) {
                                  if (!item.startsWith('-')) return const SizedBox.shrink();
                                  final cleanItem = item.replaceFirst('- ', '');
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '• ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            cleanItem,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Inter',
                                              color: Colors.white70,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          }
                          // Jika section adalah paragraf biasa
                          else {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text(
                                section,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                            );
                          }
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MateriWebPage(
                            token: widget.token,
                            categoryId: widget.categoryId,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      'Next >',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        color: Color(0xFF001A6E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}