import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _period = 'week';
  Stats? _stats;
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
      final stats = await api.getStats(_period);
      setState(() => _stats = stats);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setPeriod(String period) {
    setState(() => _period = period);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'day', label: Text('Day')),
              ButtonSegment(value: 'week', label: Text('Week')),
              ButtonSegment(value: 'month', label: Text('Month')),
            ],
            selected: {_period},
            onSelectionChanged: (s) => _setPeriod(s.first),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Center(child: Text(_error!))
          else
            _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final stats = _stats!;
    final withTime =
        stats.categories.where((c) => c.totalSeconds > 0).toList();

    if (withTime.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('No time tracked yet for this period.',
              textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      children: [
        Text('Total: ${formatDuration(stats.totalSeconds)}',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: withTime.map((c) {
                final pct = stats.totalSeconds == 0
                    ? 0.0
                    : c.totalSeconds / stats.totalSeconds * 100;
                return PieChartSectionData(
                  value: c.totalSeconds.toDouble(),
                  color: colorFromHex(c.color),
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...withTime.map((c) => ListTile(
              leading: CircleAvatar(
                radius: 10,
                backgroundColor: colorFromHex(c.color),
              ),
              title: Text(c.name),
              trailing: Text(formatDuration(c.totalSeconds),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
      ],
    );
  }
}
