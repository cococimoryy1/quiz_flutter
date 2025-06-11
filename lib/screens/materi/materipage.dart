import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'materi_web_page.dart';

class MateriPage extends StatefulWidget {
  final String token;

  MateriPage({Key? key, required this.token}) : super(key: key);

  @override
  _MateriPageState createState() => _MateriPageState();
}

class _MateriPageState extends State<MateriPage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  List<Map<String, dynamic>> categoriesWithContent = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print('Using token in MateriPage: ${widget.token}');
    pb.authStore.save(widget.token, null);
    fetchCategoriesWithContent();
  }

  Future<void> fetchCategoriesWithContent() async {
    setState(() {
      isLoading = true;
    });
    try {
      final categoriesResponse = await pb.collection('kategori').getList();
      print('Response from PocketBase (kategori): ${categoriesResponse.items}');

      List<Map<String, dynamic>> tempCategories = [];
      for (var category in categoriesResponse.items) {
        // Ambil satu sub-materi pertama dari kategori ini sebagai contoh konten
        final subMateriResponse = await pb.collection('sub_materi').getList(
          filter: 'category = "${category.id}"',
          perPage: 1, // Mengambil satu sub-materi pertama
        );
        final subMateri = subMateriResponse.items.isNotEmpty ? subMateriResponse.items[0] : null;
        tempCategories.add({
          'id': category.id,
          'name': category.data['name'] ?? 'Nama Tidak Tersedia',
          'content': subMateri != null ? subMateri.data['konten'] ?? 'Konten tidak tersedia' : 'Konten tidak tersedia',
        });
      }

      setState(() {
        categoriesWithContent = tempCategories;
        isLoading = false;
        print('Categories with content length: ${categoriesWithContent.length}');
      });
    } catch (e) {
      print('Error fetching kategori or sub_materi: $e');
      setState(() {
        categoriesWithContent = [];
        isLoading = false;
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
  title: const Text(
    'Materi',
    style: TextStyle(color: Colors.white),
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
              child: categoriesWithContent.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada kategori materi atau sedang memuat...',
                        style: TextStyle(fontSize: 14, fontFamily: 'Inter', color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: categoriesWithContent.length,
                      itemBuilder: (context, index) {
                        final category = categoriesWithContent[index];
                        return _buildCategoryCard(context, category);
                      },
                    ),
            ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MateriWebPage(
              token: widget.token,
              categoryId: category['id'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${category['name']} Pemrograman Dasar', // Subjudul statis berdasarkan contoh gambar
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category['content'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      color: Colors.white70,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MateriWebPage(
                      token: widget.token,
                      categoryId: category['id'],
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