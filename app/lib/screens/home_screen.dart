import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> _categories = [];
  RunningTimer? _running;
  bool _loading = true;
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh the elapsed-time display every second while a timer runs.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_running != null && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<AppState>().api;
    try {
      final categories = await api.getCategories();
      final running = await api.getRunningTimer();
      setState(() {
        _categories = categories;
        _running = running;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start(Category category) async {
    final api = context.read<AppState>().api;
    try {
      // Stop any timer already running before starting a new one.
      if (_running != null) {
        await api.stopTimer(_running!.id);
      }
      final running = await api.startTimer(category.id);
      setState(() => _running = running);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _stop() async {
    final api = context.read<AppState>().api;
    final running = _running;
    if (running == null) return;
    try {
      await api.stopTimer(running.id);
      setState(() => _running = null);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Reading'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final api = context.read<AppState>().api;
    try {
      await api.createCategory(name, '#4F46E5');
      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  int get _elapsedSeconds {
    if (_running == null) return 0;
    return DateTime.now().difference(_running!.startedAt).inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    Category? runningCategory;
    if (_running != null) {
      for (final c in _categories) {
        if (c.id == _running!.categoryId) {
          runningCategory = c;
          break;
        }
      }
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_running != null && runningCategory != null)
            _RunningCard(
              category: runningCategory,
              elapsedSeconds: _elapsedSeconds,
              onStop: _stop,
            ),
          const SizedBox(height: 8),
          Text('Tap a category to start tracking',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ..._categories.map((c) {
            final isRunning = _running?.categoryId == c.id;
            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: colorFromHex(c.color)),
                title: Text(c.name),
                trailing: isRunning
                    ? const Icon(Icons.stop_circle, color: Colors.red)
                    : const Icon(Icons.play_circle_outline),
                onTap: () => isRunning ? _stop() : _start(c),
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addCategory,
            icon: const Icon(Icons.add),
            label: const Text('Add category'),
          ),
        ],
      ),
    );
  }
}

class _RunningCard extends StatelessWidget {
  final Category category;
  final int elapsedSeconds;
  final VoidCallback onStop;

  const _RunningCard({
    required this.category,
    required this.elapsedSeconds,
    required this.onStop,
  });

  String get _clock {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorFromHex(category.color).withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Tracking: ${category.name}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_clock,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontFeatures: const [])),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: onStop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}
