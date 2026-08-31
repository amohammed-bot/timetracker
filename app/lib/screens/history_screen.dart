import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TimeEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<AppState>().api;
    try {
      final entries = await api.getHistory();
      setState(() => _entries = entries);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_entries.isEmpty) {
      return const Center(child: Text('No history yet.'));
    }

    final dateFormat = DateFormat('EEE d MMM, HH:mm');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _entries.length,
        itemBuilder: (context, i) {
          final e = _entries[i];
          return ListTile(
            leading: CircleAvatar(
              radius: 10,
              backgroundColor: colorFromHex(e.color),
            ),
            title: Text(e.categoryName),
            subtitle: Text(dateFormat.format(e.startedAt)),
            trailing: Text(formatDuration(e.seconds),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
    );
  }
}
