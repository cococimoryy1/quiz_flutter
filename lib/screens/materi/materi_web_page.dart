import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'detail_materi_page.dart';

class MateriWebPage extends StatefulWidget {
  final String token;
  final String categoryId;

  const MateriWebPage({
    Key? key,
    required this.token,
    required this.categoryId,
  }) : super(key: key);

  @override
  MateriWebPageState createState() => MateriWebPageState();
}

class MateriWebPageState extends State<MateriWebPage> {
  final pb = PocketBase('http://127.0.0.1:8090'); // Ganti dengan 10.0.2.2:8090 jika pakai emulator
  List<Map<String, dynamic>> subMateriList = [];
  bool isLoading = true;
  String categoryName = 'Loading...';

  @override
  void initState() {
    super.initState();
    print('Using token in MateriWebPage: ${widget.token}');
    print('Category ID: ${widget.categoryId}');
    pb.authStore.save(widget.token, null);
    fetchCategoryName();
    fetchSubMateri();
  }

  Future<void> fetchCategoryName() async {
    try {
      final response = await pb.collection('kategori').getOne(widget.categoryId);
      setState(() {
        categoryName = response.data['name'] ?? 'Kategori Tidak Diketahui';
        print('Fetched category name: $categoryName');
      });
    } catch (e) {
      print('Error fetching category name: $e');
      setState(() {
        categoryName = 'Kategori Tidak Diketahui';
      });
    }
  }

  Future<void> fetchSubMateri() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await pb.collection('sub_materi').getList(
        filter: 'category = "${widget.categoryId}"',
      );
      print('Response from PocketBase (sub_materi): ${response.items}');

      List<Map<String, dynamic>> tempSubMateriList = [];
      for (var subMateri in response.items) {
        // Cari materi yang memiliki relasi ke sub_materi ini
        String materiId = await findMateriIdForSubMateri(subMateri.id);
        tempSubMateriList.add({
          'subMateri': subMateri,
          'materiId': materiId,
        });
      }

      setState(() {
        subMateriList = tempSubMateriList;
        isLoading = false;
        print('Sub Materi length: ${subMateriList.length}');
      });
    } catch (e) {
      print('Error fetching sub_materi: $e');
      setState(() {
        subMateriList = [];
        isLoading = false;
      });
    }
  }

Future<String> findMateriIdForSubMateri(String subMateriId) async {
  try {
    final materiResponse = await pb.collection('materi').getList(
      filter: 'sub_materi = "$subMateriId"', // Pastikan field ini benar
      perPage: 1,
    );
    if (materiResponse.items.isNotEmpty) {
      String materiId = materiResponse.items[0].id;
      print('Found materiId $materiId for subMateriId $subMateriId');
      return materiId;
    } else {
      print('No materi found for subMateriId $subMateriId');
      return '';
    }
  } catch (e) {
    print('Error finding materi for subMateriId $subMateriId: $e');
    return '';
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
          categoryName.isNotEmpty ? categoryName : 'Loading...',
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
        ),
        backgroundColor: const Color(0xFF001A6E),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: subMateriList.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada sub materi untuk kategori ini.',
                        style: TextStyle(fontSize: 14, fontFamily: 'Inter', color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: subMateriList.length,
                      itemBuilder: (context, index) {
                        final subMateriData = subMateriList[index];
                        return _buildSubMateriCard(context, subMateriData['subMateri'], subMateriData['materiId']);
                      },
                    ),
            ),
    );
  }

  Widget _buildSubMateriCard(BuildContext context, dynamic subMateri, String materiId) {
    final imageUrl = subMateri.data['image'] != null
        ? pb.getFileUrl(subMateri, subMateri.data['image']).toString()
        : 'https://via.placeholder.com/150';

    return GestureDetector(
      onTap: () {
        if (materiId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Materi tidak ditemukan untuk sub-materi ini.')),
          );
          return;
        }
        print('Navigating with materiId: $materiId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailMateriPage(
              token: widget.token,
              materiId: materiId,
              categoryId: subMateri.data['category'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image from PocketBase: $error');
                  return Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subMateri.data['tittle'] ?? 'Judul Tidak Tersedia',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001A6E),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subMateri.data['konten'] ?? 'Deskripsi tidak tersedia',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  '📚 ${subMateri.data['sub_bab'] ?? 0} Bab | 🖥️ ${subMateri.data['latihan'] ?? 0} Latihan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pada materi ini akan dijelaskan mengenai bahasa pemrograman',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'Inter',
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF001A6E),
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}