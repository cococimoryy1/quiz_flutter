import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'EditProfilePage.dart';
import '../../utils/pb_instance.dart';
import '../dashboard.dart';
import '../auth/login.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  final String token;
  const ProfilePage({Key? key, required this.token}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      pb.authStore.save(widget.token, null);
      print('ProfilePage - Token: ${widget.token}');
      
      if (authProvider.token.isEmpty) {
        authProvider.login(widget.token, null);
      }
      
      // Refresh authentication to populate pb.authStore.model
      try {
        final authData = await pb.collection('users').authRefresh();
        print('Auth refresh successful: ${authData.record?.data}');
        authProvider.updateUserData(authData.record?.data ?? {});
      } catch (e) {
        print('Auth refresh failed: $e');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      }
      
      print('ProfilePage - AuthStore: isValid=${pb.authStore.isValid}, model=${pb.authStore.model}');
      fetchUserData();
    });
  }

  Future<void> fetchUserData() async {
    try {
      if (pb.authStore.isValid && pb.authStore.model != null) {
        final userId = pb.authStore.model.id;
        print('User ID: $userId');
        final record = await pb.collection('users').getOne(userId);
        print('User data: ${record.data}');
        setState(() {
          userData = record.data;
          isLoading = false;
        });
        
        final authProvider = context.read<AuthProvider>();
        authProvider.updateUserData(record.data);
      } else {
        print('AuthStore is not valid or model is null');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        isLoading = false;
      });
      
      if (e.toString().contains('401') || e.toString().contains('403')) {
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 247),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Failed to load profile data'),
                      SizedBox(height: 8),
                      Text('Please try logging in again'),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Akun',
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(thickness: 1, height: 20),
                    ListTile(
                      title: const Text(
                        'Edit Profile',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 15),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfilePage()),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text(
                        'Logout',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: Colors.red),
                      ),
                      trailing: const Icon(Icons.logout, size: 16, color: Colors.red),
                      onTap: () {
                        _logout();
                      },
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Color(0xFF003366)),
            label: '',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            final authProvider = context.read<AuthProvider>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardPage(token: authProvider.token),
              ),
            );
          }
        },
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final authProvider = context.read<AuthProvider>();
                authProvider.logout();
                pb.authStore.clear();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF001A6E),
            Color(0xFF0047BA),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData?['name'] ?? 'Unknown Name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userData?['email'] ?? 'Unknown Email',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
                ),
                if (userData?['gender'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Gender: ${userData!['gender']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      color: Colors.white70,
                    ),
                  ),
                ],
                if (userData?['tanggal_lahir'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Born: ${userData!['tanggal_lahir']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: userData?['avatar'] != null
                ? ClipOval(
                    child: Image.network(
                      pb.getFileUrl(pb.authStore.model, userData!['avatar']).toString(),
                      width: 44,
                      height: 44,
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
}