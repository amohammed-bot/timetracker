import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

// Change this to your server's address.
//  - Android emulator reaching your computer: http://10.0.2.2:3000
//  - A real phone / production server: https://your-domain.com
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path) => Uri.parse('$kApiBaseUrl$path');

  dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    final message = (body is Map && body['error'] != null)
        ? body['error'] as String
        : 'Request failed (${res.statusCode})';
    throw ApiException(message);
  }

  // --- Auth ---

  Future<String> register(String email, String password) async {
    final res = await http.post(_uri('/auth/register'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}));
    return _decode(res)['token'] as String;
  }

  Future<String> login(String email, String password) async {
    final res = await http.post(_uri('/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}));
    return _decode(res)['token'] as String;
  }

  // --- Categories ---

  Future<List<Category>> getCategories() async {
    final res = await http.get(_uri('/categories'), headers: _headers);
    return (_decode(res) as List)
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<Category> createCategory(String name, String color) async {
    final res = await http.post(_uri('/categories'),
        headers: _headers,
        body: jsonEncode({'name': name, 'color': color}));
    return Category.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    final res = await http.delete(_uri('/categories/$id'), headers: _headers);
    _decode(res);
  }

  // --- Timers ---

  Future<RunningTimer> startTimer(int categoryId) async {
    final res = await http.post(_uri('/entries/start'),
        headers: _headers,
        body: jsonEncode({'category_id': categoryId}));
    return RunningTimer.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<void> stopTimer(int entryId) async {
    final res =
        await http.post(_uri('/entries/$entryId/stop'), headers: _headers);
    _decode(res);
  }

  Future<RunningTimer?> getRunningTimer() async {
    final res = await http.get(_uri('/entries/running'), headers: _headers);
    final data = _decode(res);
    if (data == null) return null;
    return RunningTimer.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TimeEntry>> getHistory() async {
    final res = await http.get(_uri('/entries'), headers: _headers);
    return (_decode(res) as List)
        .map((e) => TimeEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- Stats ---

  Future<Stats> getStats(String period) async {
    final res =
        await http.get(_uri('/stats?period=$period'), headers: _headers);
    return Stats.fromJson(_decode(res) as Map<String, dynamic>);
  }
}
