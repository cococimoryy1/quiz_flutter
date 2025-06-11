import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:quiz_flutter/screens/auth/login.dart';
import 'materi/materipage.dart';
import 'materi/materi_web_page.dart';
import 'profil/profilepage.dart';
import 'quiz/latihan_page.dart';
import 'quiz/quizpage.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends StatefulWidget {
  final String token;

  DashboardPage({Key? key, required this.token}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final pb = PocketBase('http://127.0.0.1:8090');
  List<dynamic> subMateriList = [];
  Map<String, List<Map<String, dynamic>>> latihanByCategory = {};
  bool isLoadingMateri = true;
  bool isLoadingLatihan = true;
  String errorMessageMateri = '';
  String errorMessageLatihan = '';

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    print('Using token: ${widget.token}');
    pb.authStore.save(widget.token, null);
    _refreshAuthAndFetchData();
  }

  Future<void> _refreshAuthAndFetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      // Segarkan autentikasi untuk mengisi pb.authStore.model
      final authData = await pb.collection('users').authRefresh();
      print('Auth refresh successful: ${authData.record?.data}');
      authProvider.updateUserData(authData.record?.data ?? {});
    } catch (e) {
      print('Auth refresh failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Autentikasi gagal. Silakan login kembali.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }
    fetchSubMateri();
    fetchLatihan();
  }

  Future<void> fetchSubMateri() async {
    setState(() {
      isLoadingMateri = true;
      errorMessageMateri = '';
    });
    try {
      final response = await pb.collection('sub_materi').getList();
      print('Response from PocketBase (sub_materi): ${response.items}');
      setState(() {
        subMateriList = response.items;
        print('Sub Materi length: ${subMateriList.length}');
        isLoadingMateri = false;
      });
    } catch (e) {
      print('Error fetching sub_materi: $e');
      setState(() {
        subMateriList = [];
        errorMessageMateri = 'Gagal mengambil materi: $e';
        isLoadingMateri = false;
      });
    }
  }

  Future<void> fetchLatihan() async {
    setState(() {
      isLoadingLatihan = true;
      errorMessageLatihan = '';
    });
    try {
      print('Fetching latihan from PocketBase...');
      final response = await pb.collection('latihan').getList();
      print('Response from PocketBase (latihan): ${response.items}');
      setState(() {
        latihanByCategory = {'Semua': response.items.map((item) => item.toJson()).toList()};
        print('Latihan length: ${latihanByCategory['Semua']?.length ?? 0}');
        isLoadingLatihan = false;
      });
    } catch (e) {
      print('Error fetching latihan: $e');
      setState(() {
        latihanByCategory = {};
        errorMessageLatihan = 'Gagal mengambil latihan: $e';
        isLoadingLatihan = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (widget.token.isEmpty || authProvider.token.isEmpty) {
        print('No valid token, redirecting to login');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      }
      
      if (authProvider.token != widget.token) {
        authProvider.login(widget.token, null);
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage(token: widget.token)),
      );
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSectionHeader('Materi', context),
              isLoadingMateri
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : errorMessageMateri.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              errorMessageMateri,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  color: Colors.red),
                            ),
                          ),
                        )
                      : subMateriList.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Tidak ada data materi atau sedang memuat...',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                      color: Colors.grey),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: subMateriList.map((subMateri) {
                                  print('Rendering sub_materi: ${subMateri.data}');
                                  return _buildMateriCard(context, subMateri);
                                }).toList(),
                              ),
                            ),
              const SizedBox(height: 20),
              _buildSectionHeader('Latihan', context),
              isLoadingLatihan
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : errorMessageLatihan.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              errorMessageLatihan,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  color: Colors.red),
                            ),
                          ),
                        )
                      : latihanByCategory.isEmpty || latihanByCategory['Semua']!.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Tidak ada data latihan',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                      color: Colors.grey),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: latihanByCategory.entries.length,
                              itemBuilder: (context, index) {
                                final kategori = latihanByCategory.entries.elementAt(index).key;
                                final latihanList = latihanByCategory.entries.elementAt(index).value;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      kategori.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...latihanList.map((latihan) {
                                      return _buildLatihanCard(latihan, kategori);
                                    }).toList(),
                                    const SizedBox(height: 10),
                                  ],
                                );
                              },
                            ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF001A6E),
        onTap: _onItemTapped,
      ),
    );
  }

Widget _buildHeader() {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userName = pb.authStore.model?.data['name'] ?? 
                   authProvider.userData?['name'] ?? 
                   'Pengguna';
  return Container(
    padding: const EdgeInsets.all(18.0),
    decoration: BoxDecoration(
      color: const Color(0xFF001A6E),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang',
              style: TextStyle(fontSize: 15, fontFamily: 'Inter', color: Colors.white),
            ),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 17,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.withOpacity(0.2),
          child: pb.authStore.model != null && pb.authStore.model.data['avatar'] != null
              ? ClipOval(
                  child: Image.network(
                    pb.getFileUrl(pb.authStore.model, pb.authStore.model.data['avatar']).toString(),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Colors.white);
                    },
                  ),
                )
              : const Icon(Icons.person, color: Colors.white),
        ),
      ],
    ),
  );
}
  Widget _buildSectionHeader(String title, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 17, fontFamily: 'Inter', fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: () {
            if (title == "Materi") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MateriPage(token: widget.token),
                ),
              );
            } else if (title == "Latihan") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LatihanPage(token: widget.token),
                ),
              );
            }
          },
          child: const Text(
            'lihat semua',
            style: TextStyle(fontSize: 12, fontFamily: 'Inter', color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildMateriCard(BuildContext context, dynamic subMateri) {
    final imageUrl = subMateri.data['image'] != null
        ? pb.getFileUrl(subMateri, subMateri.data['image']).toString()
        : 'https://via.placeholder.com/150';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MateriWebPage(
              token: widget.token,
              categoryId: subMateri.data['category'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: _boxDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image from PocketBase: $error');
                  return Container(
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subMateri.data['tittle'] ?? 'Judul Tidak Tersedia',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                color: Color(0xFF001A6E),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              subMateri.data['konten'] ?? 'Deskripsi tidak tersedia',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'Inter',
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              '📚 ${subMateri.data['sub_bab'] ?? 0} Bab | 🖥 ${subMateri.data['latihan'] ?? 0} Latihan',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'Inter',
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Pada materi ini akan dijelaskan mengenai bahasa pemrograman',
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'Inter',
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF001A6E),
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildLatihanCard(Map<String, dynamic> latihan, String kategori) {
  return Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: _boxDecoration(),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              latihan['nama'] ?? 'Nama Tidak Tersedia',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  '${latihan['jumlah_soal'] ?? 0} Pertanyaan',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'Inter',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kategori,
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LatihanPage(token: widget.token),
              ),
            );
          },
        ),
      ],
    ),
  );
}

// Future<void> fetchLatihan() async {
//   // Menggunakan data statis, jadi fungsi ini tidak perlu melakukan panggilan ke PocketBase
//   final List<Map<String, String>> latihanList = [
//     {'title': 'Percabangan If Else', 'count': '15 Pertanyaan', 'language': 'Java'},
//     {'title': 'Perulangan For', 'count': '15 Pertanyaan', 'language': 'Java'},
//     {'title': 'Perulangan While', 'count': '15 Pertanyaan', 'language': 'Java'},
//   ];
//   setState(() {
//     // Simulasi setState untuk memastikan UI diperbarui dengan data statis
//     // Catatan: Anda perlu menyimpan latihanList ke state jika ingin digunakan di UI
//   });
// }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 5,
          spreadRadius: 2,
        ),
      ],
    );
  }
}