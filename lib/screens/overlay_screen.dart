import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../engine/signal_engine.dart';

enum OverlayState {
  icon,
  scanning,
  result,
}

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  OverlayState _state = OverlayState.icon;

  SignalResult? _result;

  Timer? _timer;

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  void _expand() {
    setState(() {
      _state = OverlayState.scanning;
    });

    FlutterOverlayWindow.resizeOverlay(
      MediaQuery.of(context).size.width.toInt(),
      MediaQuery.of(context).size.height.toInt(),
      true,
    );

    _startScan();
  }

  void _collapse() {
    _stopScan();

    FlutterOverlayWindow.resizeOverlay(
      72,
      72,
      true,
    );

    setState(() {
      _state = OverlayState.icon;
    });
  }

  void _startScan() {
    _stopScan();

    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        _generateSignal();
      },
    );

    _generateSignal();
  }

  void _stopScan() {
    _timer?.cancel();
    _timer = null;
  }

  void _generateSignal() {
    final engine = SignalEngine();

    final result = engine.generateSignal('1M');

    if (!mounted) return;

    setState(() {
      _result = result;
      _state = OverlayState.result;
    });
  }

  Color _signalColor() {
    if (_result?.direction == SignalDirection.buy) {
      return Colors.green;
    }

    if (_result?.direction == SignalDirection.sell) {
      return Colors.red;
    }

    return Colors.grey;
  }

  String _signalText() {
    if (_result == null) {
      return 'WAIT';
    }

    switch (_result!.direction) {
      case SignalDirection.buy:
        return 'BUY';
      case SignalDirection.sell:
        return 'SELL';
      case SignalDirection.none:
        return 'WAIT';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == OverlayState.icon) {
      return Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _expand,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black87,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: const Center(
              child: Text(
                'MR\nKOKO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'MR KOKO SIGNAL PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _collapse,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_state == OverlayState.scanning)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Scanning market...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              if (_state == OverlayState.result &&
                  _result != null)
                Column(
                  children: [
                    Text(
                      _signalText(),
                      style: TextStyle(
                        color: _signalColor(),
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Confidence: ${_result!.confidence}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result!.rule,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._result!.confirmations.map(
                      (confirmation) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          confirmation,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
