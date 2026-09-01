import 'package:flutter/material.dart';
import 'local_api.dart';

// Holds the app-wide state. Everything is stored locally on the phone.
class AppState extends ChangeNotifier {
  final LocalApi api = LocalApi();

  // Bumped after a reset so all screens reload from scratch.
  int resetCount = 0;

  Future<void> resetAll() async {
    await api.resetAllData();
    resetCount++;
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
