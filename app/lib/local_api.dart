import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'models.dart';

// Stores everything on the phone itself - no server, no account.
// Data survives closing and reopening the app.
class LocalApi implements ApiClient {
  static const _kCategories = 'tt_categories';
  static const _kEntries = 'tt_entries';
  static const _kRunning = 'tt_running';
  static const _kNextId = 'tt_next_id';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // --- Auth is not needed locally; these exist to satisfy the interface. ---

  @override
  void setToken(String? token) {}

  @override
  Future<String> login(String email, String password) async => 'local';

  @override
  Future<String> register(String email, String password) async => 'local';

  // --- Internal helpers ---

  Future<int> _takeNextId(SharedPreferences p) async {
    final id = p.getInt(_kNextId) ?? 1;
    await p.setInt(_kNextId, id + 1);
    return id;
  }

  Future<List<Category>> _loadCategories(SharedPreferences p) async {
    final raw = p.getString(_kCategories);
    if (raw == null) {
      // First run (or after a reset): create the default categories.
      final defaults = [
        Category(id: await _takeNextId(p), name: 'Work', color: '#4F46E5'),
        Category(id: await _takeNextId(p), name: 'Study', color: '#059669'),
        Category(
            id: await _takeNextId(p),
            name: 'Entertainment',
            color: '#DB2777'),
      ];
      await _saveCategories(p, defaults);
      return defaults;
    }
    return (jsonDecode(raw) as List)
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveCategories(SharedPreferences p, List<Category> cats) =>
      p.setString(
          _kCategories, jsonEncode(cats.map((c) => c.toJson()).toList()));

  List<TimeEntry> _loadEntries(SharedPreferences p) {
    final raw = p.getString(_kEntries);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => TimeEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveEntries(SharedPreferences p, List<TimeEntry> entries) =>
      p.setString(
          _kEntries, jsonEncode(entries.map((e) => e.toJson()).toList()));

  // --- Categories ---

  @override
  Future<List<Category>> getCategories() async {
    final p = await _prefs;
    return _loadCategories(p);
  }

  @override
  Future<Category> createCategory(String name, String color) async {
    final p = await _prefs;
    final cats = await _loadCategories(p);
    final cat = Category(id: await _takeNextId(p), name: name, color: color);
    cats.add(cat);
    await _saveCategories(p, cats);
    return cat;
  }

  @override
  Future<void> deleteCategory(int id) async {
    final p = await _prefs;
    final cats = await _loadCategories(p);
    cats.removeWhere((c) => c.id == id);
    await _saveCategories(p, cats);
    final entries = _loadEntries(p);
    entries.removeWhere((e) => e.categoryId == id);
    await _saveEntries(p, entries);
  }

  // --- Timers ---

  @override
  Future<RunningTimer> startTimer(int categoryId) async {
    final p = await _prefs;
    final running = RunningTimer(
      id: await _takeNextId(p),
      categoryId: categoryId,
      startedAt: DateTime.now(),
    );
    await p.setString(_kRunning, jsonEncode(running.toJson()));
    return running;
  }

  @override
  Future<void> stopTimer(int entryId) async {
    final p = await _prefs;
    final raw = p.getString(_kRunning);
    if (raw == null) return;
    final running =
        RunningTimer.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (running.id != entryId) return;

    final now = DateTime.now();
    final seconds = now.difference(running.startedAt).inSeconds;

    final cats = await _loadCategories(p);
    Category? cat;
    for (final c in cats) {
      if (c.id == running.categoryId) {
        cat = c;
        break;
      }
    }

    final entries = _loadEntries(p);
    entries.insert(
      0,
      TimeEntry(
        id: running.id,
        categoryId: running.categoryId,
        categoryName: cat?.name ?? 'Unknown',
        color: cat?.color ?? '#4F46E5',
        startedAt: running.startedAt,
        endedAt: now,
        seconds: seconds,
      ),
    );
    await _saveEntries(p, entries);
    await p.remove(_kRunning);
  }

  @override
  Future<RunningTimer?> getRunningTimer() async {
    final p = await _prefs;
    final raw = p.getString(_kRunning);
    if (raw == null) return null;
    return RunningTimer.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<List<TimeEntry>> getHistory() async {
    final p = await _prefs;
    final entries = _loadEntries(p);
    entries.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return entries;
  }

  // --- Stats ---

  @override
  Future<Stats> getStats(String period) async {
    final p = await _prefs;
    final days = period == 'day' ? 1 : (period == 'month' ? 30 : 7);
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final totals = <int, int>{};
    for (final e in _loadEntries(p)) {
      if (e.endedAt != null && e.startedAt.isAfter(cutoff)) {
        totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.seconds;
      }
    }

    final cats = (await _loadCategories(p))
        .map((c) => CategoryStat(
              categoryId: c.id,
              name: c.name,
              color: c.color,
              totalSeconds: totals[c.id] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));

    final total = cats.fold<int>(0, (sum, c) => sum + c.totalSeconds);
    return Stats(period: period, totalSeconds: total, categories: cats);
  }

  // --- Reset ---

  // Wipes all tracked time and custom categories. The default categories
  // come back automatically the next time the app loads.
  Future<void> resetAllData() async {
    final p = await _prefs;
    await p.remove(_kCategories);
    await p.remove(_kEntries);
    await p.remove(_kRunning);
    await p.remove(_kNextId);
  }
}
