import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper();

  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await _db.getHistory();

    if (!mounted) return;

    setState(() {
      _history = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signal History'),
      ),
      body: _history.isEmpty
          ? const Center(
              child: Text(
                'No signal history yet',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];

                final direction =
                    item['direction']
                        ?.toString()
                        .toLowerCase();

                final isBuy = direction == 'buy';

                return Card(
                  child: ListTile(
                    leading: Icon(
                      isBuy
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: isBuy
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(
                      '${direction?.toUpperCase() ?? 'WAIT'} '
                      '${item['confidence'] ?? 0}%',
                    ),
                    subtitle: Text(
                      '${item['rule'] ?? ''}\n'
                      '${item['timeframe'] ?? ''}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
