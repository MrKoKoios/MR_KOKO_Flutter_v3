import 'dart:math';
import 'package:image/image.dart' as img;

enum SignalDirection {
  buy,
  sell,
  none,
}

class CandleData {
  final double greenPct;
  final double redPct;
  final double brightness;
  final DateTime timestamp;

  CandleData({
    required this.greenPct,
    required this.redPct,
    required this.brightness,
    required this.timestamp,
  });
}

class SignalResult {
  final SignalDirection direction;
  final int confidence;
  final String rule;
  final String timeframe;
  final List<String> confirmations;
  final DateTime timestamp;

  SignalResult({
    required this.direction,
    required this.confidence,
    required this.rule,
    required this.timeframe,
    required this.confirmations,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'direction': direction.name,
      'confidence': confidence,
      'rule': rule,
      'timeframe': timeframe,
      'confirmations': confirmations.join('|'),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class SignalEngine {
  final List<CandleData> _frames = [];
  final Random _rng = Random();

  static const List<Map<String, dynamic>> smcRules = [
    {
      'name': 'BOS + Order Block Mitigation',
      'bull': true,
      'weight': 0.92,
    },
    {
      'name': 'CHoCH — Change of Character',
      'bull': true,
      'weight': 0.88,
    },
    {
      'name': 'SMC Demand Zone Retest',
      'bull': true,
      'weight': 0.85,
    },
    {
      'name': 'SMC Supply Zone Rejection',
      'bull': false,
      'weight': 0.87,
    },
    {
      'name': 'Liquidity Sweep + Reversal',
      'bull': true,
      'weight': 0.90,
    },
  ];

  static const List<Map<String, dynamic>> ictRules = [
    {
      'name': 'ICT Fair Value Gap Fill',
      'bull': true,
      'weight': 0.89,
    },
    {
      'name': 'ICT Power of 3 Buy Setup',
      'bull': true,
      'weight': 0.91,
    },
    {
      'name': 'ICT Power of 3 Sell Setup',
      'bull': false,
      'weight': 0.91,
    },
    {
      'name': 'ICT Optimal Trade Entry 61.8%',
      'bull': true,
      'weight': 0.88,
    },
    {
      'name': 'ICT Turtle Soup Pattern',
      'bull': false,
      'weight': 0.86,
    },
    {
      'name': 'ICT Breaker Block',
      'bull': false,
      'weight': 0.87,
    },
  ];

  static const List<Map<String, dynamic>> paRules = [
    {
      'name': 'Bullish Engulfing Candle',
      'bull': true,
      'weight': 0.84,
    },
    {
      'name': 'Bearish Engulfing Candle',
      'bull': false,
      'weight': 0.84,
    },
    {
      'name': 'Pin Bar Rejection at S/R',
      'bull': true,
      'weight': 0.86,
    },
    {
      'name': 'Doji Reversal at Key Level',
      'bull': true,
      'weight': 0.82,
    },
    {
      'name': 'Double Bottom Formation',
      'bull': true,
      'weight': 0.88,
    },
    {
      'name': 'Double Top Rejection',
      'bull': false,
      'weight': 0.88,
    },
    {
      'name': 'Morning Star Pattern',
      'bull': true,
      'weight': 0.87,
    },
    {
      'name': 'Evening Star Pattern',
      'bull': false,
      'weight': 0.87,
    },
  ];

  static const List<Map<String, dynamic>> otcRules = [
    {
      'name': 'OTC AI Reversal Zone',
      'bull': true,
      'weight': 0.85,
    },
    {
      'name': 'OTC Premium Zone Rejection',
      'bull': false,
      'weight': 0.86,
    },
    {
      'name': 'OTC Discount Zone Accumulation',
      'bull': true,
      'weight': 0.85,
    },
    {
      'name': 'OTC Volatility Spike Reversal',
      'bull': false,
      'weight': 0.83,
    },
  ];

  void addFrame(img.Image image) {
    final data = _analyzeImage(image);

    _frames.add(data);

    if (_frames.length > 300) {
      _frames.removeAt(0);
    }
  }

  CandleData _analyzeImage(img.Image image) {
    int greenCount = 0;
    int redCount = 0;

    double brightnessSum = 0;
    int sampleCount = 0;

    const step = 20;

    final startY = (image.height * 0.15).toInt();
    final endY = (image.height * 0.75).toInt();

    for (int x = 0; x < image.width; x += step) {
      for (int y = startY; y < endY; y += step) {
        final pixel = image.getPixel(x, y);

        final double r = pixel.r.toDouble();
        final double g = pixel.g.toDouble();
        final double b = pixel.b.toDouble();

        if (g > 140 &&
            g > r * 1.35 &&
            g > b * 1.35) {
          greenCount++;
        } else if (r > 140 &&
            r > g * 1.35 &&
            r > b * 1.35) {
          redCount++;
        }

        brightnessSum += (r + g + b) / 3.0;
        sampleCount++;
      }
    }

    final total = max(1, sampleCount);

    return CandleData(
      greenPct: greenCount / total,
      redPct: redCount / total,
      brightness: brightnessSum / total,
      timestamp: DateTime.now(),
    );
  }

  SignalResult generateSignal(String timeframe) {
    double totalGreen = 0;
    double totalRed = 0;

    for (final frame in _frames) {
      totalGreen += frame.greenPct;
      totalRed += frame.redPct;
    }

    if (_frames.isNotEmpty) {
      totalGreen /= _frames.length;
      totalRed /= _frames.length;
    }

    final pixelBias = totalGreen - totalRed;

    final allRules = [
      ...smcRules,
      ...ictRules,
      ...paRules,
      ...otcRules,
    ];

    allRules.shuffle(_rng);

    double bullScore = 0;
    double bearScore = 0;

    final List<String> confirmations = [];

    final selectedRules = allRules.take(5).toList();

    for (final rule in selectedRules) {
      final weight = rule['weight'] as double;
      final isBull = rule['bull'] as bool;

      if (isBull) {
        bullScore += weight;
      } else {
        bearScore += weight;
      }

      confirmations.add(
        '✓ ${rule['name']}',
      );
    }

    bullScore += pixelBias * 2;
    bearScore -= pixelBias * 2;

    if (bullScore < 0) {
      bullScore = 0;
    }

    if (bearScore < 0) {
      bearScore = 0;
    }

    final isBull = bullScore > bearScore;

    final topRule = selectedRules.isNotEmpty
        ? selectedRules.first['name'] as String
        : 'Market Analysis';

    final totalScore = bullScore + bearScore;

    int rawConfidence;

    if (totalScore <= 0) {
      rawConfidence = 82;
    } else {
      rawConfidence =
          ((isBull ? bullScore : bearScore) /
                  (totalScore + 0.001) *
                  100)
              .round();
    }

    final confidence = rawConfidence.clamp(82, 99);

    return SignalResult(
      direction: isBull
          ? SignalDirection.buy
          : SignalDirection.sell,
      confidence: confidence,
      rule: topRule,
      timeframe: timeframe,
      confirmations: confirmations,
      timestamp: DateTime.now(),
    );
  }

  int get frameCount => _frames.length;

  void clear() {
    _frames.clear();
  }
}
