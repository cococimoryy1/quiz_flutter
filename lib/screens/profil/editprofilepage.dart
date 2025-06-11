import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../../utils/pb_instance.dart';
import '../../providers/auth_provider.dart';
import '../auth/login.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  String gender = 'Female';
  int selectedDay = 1;
  String selectedMonth = 'January';
  int selectedYear = 2005;
  XFile? _imageFile; // Gambar yang dipilih pengguna
  String? currentAvatarUrl; // URL avatar yang ada dari PocketBase
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;

  final List<int> days = List.generate(31, (index) => index + 1);
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<int> years = List.generate(100, (index) => 2025 - index);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token.isNotEmpty) {
        pb.authStore.save(authProvider.token, null);
        print('Token yang digunakan: ${authProvider.token}');
        try {
          final authData = await pb.collection('users').authRefresh();
          print('Autentikasi berhasil: ${authData.record?.data}');
          authProvider.updateUserData(authData.record?.data ?? {});
        } catch (e) {
          print('Gagal menyegarkan autentikasi: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Autentikasi gagal. Silakan login kembali.')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
          return;
        }
      } else {
        print('Token tidak tersedia, mengarahkan ke login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silakan login terlebih dahulu.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      }
      await fetchUserData();
    });
  }

  Future<void> fetchUserData() async {
    try {
      if (pb.authStore.isValid && pb.authStore.model != null) {
        final userId = pb.authStore.model.id;
        print('Mengambil data pengguna dengan ID: $userId');
        final record = await pb.collection('users').getOne(userId);
        print('Data pengguna diterima: ${record.data}');

        setState(() {
          nameController.text = record.data['name']?.toString() ?? 'Nama Tidak Diketahui';
          emailController.text = record.data['email']?.toString() ?? 'Email Tidak Diketahui';
          gender = record.data['gender']?.toString() ?? 'Female';

          if (record.data['tanggal_lahir'] != null) {
            try {
              final dateStr = record.data['tanggal_lahir'].toString().split(' ')[0]; // Ambil hanya bagian tanggal (YYYY-MM-DD)
              final dateParts = dateStr.split('-');
              if (dateParts.length == 3) {
                selectedYear = int.parse(dateParts[0]);
                selectedMonth = months[int.parse(dateParts[1]) - 1];
                selectedDay = int.parse(dateParts[2]);
              } else {
                print('Format tanggal_lahir tidak sesuai: $dateStr');
              }
            } catch (e) {
              print('Kesalahan parsing tanggal_lahir: $e');
            }
          } else {
            print('Field tanggal_lahir tidak ada di data pengguna');
          }

          // Ambil URL avatar dari PocketBase jika ada
          if (record.data['avatar'] != null && record.data['avatar'].toString().isNotEmpty) {
            currentAvatarUrl = pb.getFileUrl(pb.authStore.model, record.data['avatar']).toString();
          } else {
            currentAvatarUrl = null;
          }

          isLoading = false;
        });

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.updateUserData(record.data);
      } else {
        print('AuthStore tidak valid atau model null');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Autentikasi gagal. Silakan login kembali.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      print('Kesalahan mengambil data pengguna: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data profil: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }

    if (pb.authStore.isValid && pb.authStore.model != null) {
      try {
        final monthNumber = months.indexOf(selectedMonth) + 1;
        final tanggalLahir = '$selectedYear-${monthNumber.toString().padLeft(2, '0')}-${selectedDay.toString().padLeft(2, '0')}';

        final updatedData = {
          'name': nameController.text,
          'gender': gender,
          'tanggal_lahir': tanggalLahir,
        };

        if (_imageFile != null) {
          final bytes = await _imageFile!.readAsBytes();
          final mimeType = lookupMimeType(_imageFile!.path) ?? 'application/octet-stream';
          print('Tipe MIME gambar: $mimeType');
          final multipartFile = http.MultipartFile.fromBytes(
            'avatar',
            bytes,
            filename: _imageFile!.name,
            contentType: MediaType.parse(mimeType),
          );

          await pb.collection('users').update(
            pb.authStore.model.id,
            body: updatedData,
            files: [multipartFile],
          );
        } else {
          await pb.collection('users').update(
            pb.authStore.model.id,
            body: updatedData,
          );
        }

        // Segarkan data setelah pembaruan
        await fetchUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Kesalahan memperbarui profil: $e');
        String pesanKesalahan = 'Gagal memperbarui profil';
        if (e.toString().contains('401') || e.toString().contains('403')) {
          pesanKesalahan = 'Autentikasi gagal. Silakan login kembali.';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else if (e.toString().contains('validation')) {
          pesanKesalahan = 'Data masukan tidak valid. Periksa masukan Anda.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pesanKesalahan)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Autentikasi gagal. Silakan login kembali.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 247),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: BackButton(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Edit Profil',
                style: TextStyle(
                  color: Color(0xFF003366),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _imageFile != null
                            ? FileImage(File(_imageFile!.path)) // Tampilkan gambar yang dipilih
                            : currentAvatarUrl != null
                                ? NetworkImage(currentAvatarUrl!) // Tampilkan avatar dari PocketBase
                                : null,
                        child: (_imageFile == null && currentAvatarUrl == null)
                            ? Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: IconButton(
                          icon: Icon(Icons.edit, size: 20, color: Colors.blue[900]),
                          onPressed: _pickImage,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    nameController.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    emailController.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Nama',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Jenis Kelamin', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 20),
                      Row(
                        children: [
                          Checkbox(value: gender == 'Male', onChanged: (val) => setState(() => gender = 'Male')),
                          Text('Laki-laki'),
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(value: gender == 'Female', onChanged: (val) => setState(() => gender = 'Female')),
                          Text('Perempuan'),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<int>(
                        value: selectedDay,
                        items: days.map((day) => DropdownMenuItem(value: day, child: Text(day.toString()))).toList(),
                        onChanged: (val) => setState(() => selectedDay = val!),
                      ),
                      DropdownButton<String>(
                        value: selectedMonth,
                        items: months.map((month) => DropdownMenuItem(value: month, child: Text(month))).toList(),
                        onChanged: (val) => setState(() => selectedMonth = val!),
                      ),
                      DropdownButton<int>(
                        value: selectedYear,
                        items: years.map((year) => DropdownMenuItem(value: year, child: Text(year.toString()))).toList(),
                        onChanged: (val) => setState(() => selectedYear = val!),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF003366),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Simpan',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}