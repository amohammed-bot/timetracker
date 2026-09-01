import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..load(),
      child: const TimeTrackerApp(),
    ),
  );
}

class TimeTrackerApp extends StatelessWidget {
  const TimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeTracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4F46E5),
        useMaterial3: true,
      ),
      home: const _Gate(),
    );
  }
}

// Decides whether to show the login screen or the main app.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return state.isLoggedIn ? const _MainShell() : const LoginScreen();
  }
}

// The bottom-navigation shell shown once logged in.
class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _index = 0;

  static const _titles = ['Track', 'Stats', 'History'];

  @override
  Widget build(BuildContext context) {
    final pages = const [HomeScreen(), StatsScreen(), HistoryScreen()];
    final isDemo = context.watch<AppState>().isDemo;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDemo ? '${_titles[_index]} · Demo' : _titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      // Keep each tab's state alive when switching.
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.timer_outlined), label: 'Track'),
          NavigationDestination(
              icon: Icon(Icons.pie_chart_outline), label: 'Stats'),
          NavigationDestination(
              icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
