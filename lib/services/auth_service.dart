import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://your-api-url/api'; // Ganti dengan URL API kamu

  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      // Parse token from the response
      final data = json.decode(response.body);
      return data['access_token'];  // Mengambil token dari response
    } else {
      print('Login failed: ${response.body}');
      return null;
    }
  }
}
