import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../database/database_helper.dart';
import '../engine/signal_engine.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final SignalEngine _engine = SignalEngine();

  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await _db.getHistory();

    if (mounted) {
      setState(() {
        _history = data;
      });
    }
  }

  Future<void> _launchOverlay() async {
    final isPermissionGranted =
        await FlutterOverlayWindow.isPermissionGranted();

    if (!isPermissionGranted) {
      await FlutterOverlayWindow.requestPermission();
    }

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      height: 72,
      width: 72,
      alignment: OverlayAlignment.centerRight,
      flag: OverlayFlag.defaultFlag,
      overlayTitle: 'MR KOKO',
      overlayContent: 'Tap to scan market',
    );
  }

  Future<void> _clearHistory() async {
    await _db.clearAll();
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MR KOKO Signal Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _history.isEmpty
                  ? const Center(
                      child: Text(
                        'No signal history yet',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];

                        return Card(
                          child: ListTile(
                            leading: Icon(
                              item['direction'] == 'buy'
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: item['direction'] == 'buy'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(
                              '${item['direction']?.toString().toUpperCase()} '
                              '${item['confidence']}%',
                            ),
                            subtitle: Text(
                              '${item['rule']}\n'
                              '${item['timeframe']}',
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchOverlay,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Launch Floating Icon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
