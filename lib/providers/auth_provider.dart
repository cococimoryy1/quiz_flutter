import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String _token = '';
  Map<String, dynamic>? _userData;
  bool _isLoggedIn = false;

  String get token => _token;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoggedIn => _isLoggedIn;

  void login(String token, Map<String, dynamic>? userData) {
    _token = token;
    _userData = userData;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _token = '';
    _userData = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  void updateUserData(Map<String, dynamic> userData) {
    _userData = userData;
    notifyListeners();
  }
}