import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'demo_api.dart';

// Holds the logged-in state and shares one API client across the app.
// Supports a "demo mode" that works completely offline with fake data.
class AppState extends ChangeNotifier {
  ApiClient api = Api();
  String? _token;
  bool _loading = true;

  bool get isLoggedIn => _token != null;
  bool get loading => _loading;
  bool get isDemo => _token == 'demo';

  // Called once at startup to restore a saved session.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token == 'demo') {
      api = DemoApi();
    } else {
      api.setToken(_token);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _token = token;
    api.setToken(token);
    notifyListeners();
  }

  // Switches the whole app to offline demo mode.
  Future<void> enterDemo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', 'demo');
    _token = 'demo';
    api = DemoApi();
    notifyListeners();
  }

  bool _isDemoCredentials(String email, String password) =>
      email.trim().toLowerCase() == 'demo@demo.com' && password == 'demo123';

  Future<void> login(String email, String password) async {
    if (_isDemoCredentials(email, password)) return enterDemo();
    final token = await api.login(email, password);
    await _saveToken(token);
  }

  Future<void> register(String email, String password) async {
    if (_isDemoCredentials(email, password)) return enterDemo();
    final token = await api.register(email, password);
    await _saveToken(token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    api = Api();
    notifyListeners();
  }
}

// Turns a "#RRGGBB" string into a Flutter Color.
Color colorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse('FF$cleaned', radix: 16) ?? 0xFF4F46E5;
  return Color(value);
}

// Formats seconds as "2h 15m" or "45m" or "30s".
String formatDuration(int seconds) {
  if (seconds <= 0) return '0m';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  return '${s}s';
}
