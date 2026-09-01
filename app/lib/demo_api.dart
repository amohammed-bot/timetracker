import 'dart:math';
import 'api.dart';
import 'models.dart';

// A fully offline stand-in for the real API. Used by demo mode so the whole
// app can be explored without a server or an account. Comes pre-loaded with
// a month of realistic-looking data; timers genuinely work in memory.
class DemoApi implements ApiClient {
  final List<Category> _categories = [
    Category(id: 1, name: 'Work', color: '#4F46E5'),
    Category(id: 2, name: 'Study', color: '#059669'),
    Category(id: 3, name: 'Entertainment', color: '#DB2777'),
  ];

  final List<TimeEntry> _entries = [];
  RunningTimer? _running;
  int _nextId = 100;

  DemoApi() {
    _seedFakeMonth();
  }

  // Generates ~30 days of plausible sessions so charts and history look real.
  void _seedFakeMonth() {
    final rand = Random(42);
    final now = DateTime.now();
    for (int day = 0; day < 30; day++) {
      final date = now.subtract(Duration(days: day));
      _seedSession(now, date, 9, 1,
          (3 + rand.nextInt(3)) * 3600 + rand.nextInt(1800)); // Work
      _seedSession(now, date, 17, 2,
          (1 + rand.nextInt(2)) * 3600 + rand.nextInt(1800)); // Study
      _seedSession(now, date, 20, 3,
          (1 + rand.nextInt(2)) * 3600 + rand.nextInt(1200)); // Entertainment
    }
    _entries.sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  void _seedSession(
      DateTime now, DateTime date, int hour, int categoryId, int seconds) {
    final start = DateTime(date.year, date.month, date.day, hour);
    // Don't create sessions that would start "in the future" today.
    if (start.isAfter(now)) return;
    final cat = _categories.firstWhere((c) => c.id == categoryId);
    _entries.add(TimeEntry(
      id: _nextId++,
      categoryId: categoryId,
      categoryName: cat.name,
      color: cat.color,
      startedAt: start,
      endedAt: start.add(Duration(seconds: seconds)),
      seconds: seconds,
    ));
  }

  // --- Auth (accepts anything) ---

  @override
  void setToken(String? token) {}

  @override
  Future<String> login(String email, String password) async => 'demo';

  @override
  Future<String> register(String email, String password) async => 'demo';

  // --- Categories ---

  @override
  Future<List<Category>> getCategories() async => List.of(_categories);

  @override
  Future<Category> createCategory(String name, String color) async {
    final cat = Category(id: _nextId++, name: name, color: color);
    _categories.add(cat);
    return cat;
  }

  @override
  Future<void> deleteCategory(int id) async {
    _categories.removeWhere((c) => c.id == id);
    _entries.removeWhere((e) => e.categoryId == id);
  }

  // --- Timers ---

  @override
  Future<RunningTimer> startTimer(int categoryId) async {
    _running = RunningTimer(
      id: _nextId++,
      categoryId: categoryId,
      startedAt: DateTime.now(),
    );
    return _running!;
  }

  @override
  Future<void> stopTimer(int entryId) async {
    final running = _running;
    if (running == null || running.id != entryId) return;
    final now = DateTime.now();
    final seconds = now.difference(running.startedAt).inSeconds;
    final cat = _categories.firstWhere(
      (c) => c.id == running.categoryId,
      orElse: () => _categories.first,
    );
    _entries.insert(
      0,
      TimeEntry(
        id: running.id,
        categoryId: cat.id,
        categoryName: cat.name,
        color: cat.color,
        startedAt: running.startedAt,
        endedAt: now,
        seconds: seconds,
      ),
    );
    _running = null;
  }

  @override
  Future<RunningTimer?> getRunningTimer() async => _running;

  @override
  Future<List<TimeEntry>> getHistory() async => List.of(_entries);

  // --- Stats ---

  @override
  Future<Stats> getStats(String period) async {
    final days = period == 'day' ? 1 : (period == 'month' ? 30 : 7);
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final totals = <int, int>{};
    for (final e in _entries) {
      if (e.endedAt != null && e.startedAt.isAfter(cutoff)) {
        totals[e.categoryId] = (totals[e.categoryId] ?? 0) + e.seconds;
      }
    }

    final cats = _categories
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
}
