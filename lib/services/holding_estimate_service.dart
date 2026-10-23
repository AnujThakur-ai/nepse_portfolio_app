import 'dart:math';

import '../models/holding_prediction.dart';
import '../models/technical_indicator_data.dart';
import 'bikram_sambat_service.dart';

class HoldingEstimateService {
  static const String estimateVersion = 'Rule-based-v1';

  // Heuristic weights for an indicative NEPSE swing holding period estimate:
  // Features: [bias, normalized_price, log_quantity, rsi_norm, macd_hist, sma_ratio, vol_ratio]
  static const double _bias = 28.5; // Baseline swing duration: ~28 trading days
  static const double _wPrice = -0.002;
  static const double _wQty = 0.85;
  static const double _wRsi =
      -18.2; // High RSI -> shorter remaining holding days (near peak)
  static const double _wMacd = 4.6; // Positive MACD momentum -> sustained hold
  static const double _wSma = 12.4; // Bullish SMA trend -> longer runway
  static const double _wVol = 3.2; // Volume accumulation -> extends cycle

  /// Estimates a holding period from trade parameters and technical indicators.
  /// This is a heuristic, not a trained or statistically validated model.
  static Future<HoldingPrediction> predictOptimalHolding({
    required double buyPrice,
    required int quantity,
    required TechnicalIndicatorData indicators,
    DateTime? tradeDate,
  }) async {
    final baseDate = tradeDate ?? DateTime.now();

    // 1. Feature normalization
    final normPrice = buyPrice.clamp(50.0, 5000.0) / 1000.0;
    final logQty =
        log(max(10, quantity)) / log(10); // Logarithmic position scale
    final rsiNorm =
        (indicators.rsi.clamp(10.0, 90.0) - 50.0) / 40.0; // [-1.0, 1.0]
    final macdHistNorm = indicators.histogram.clamp(-20.0, 20.0) / 10.0;
    final smaRatio = indicators.sma20 > 0
        ? ((indicators.currentPrice / indicators.sma20) - 1.0).clamp(
            -0.25,
            0.25,
          )
        : 0.0;
    final volRatio = (indicators.volumeTrendRatio - 1.0).clamp(-1.0, 3.0);

    // Apply the weighted rules to produce an indicative duration.
    double rawDays =
        _bias +
        (_wPrice * normPrice) +
        (_wQty * logQty) +
        (_wRsi * rsiNorm) +
        (_wMacd * macdHistNorm) +
        (_wSma * smaRatio) +
        (_wVol * volRatio);

    // 3. Post-processing & constraints (NEPSE typical swing range: 7 to 90 days)
    int optimalDays = rawDays.round().clamp(7, 90);

    // Confidence metric (based on indicator confluence)
    double confluence = 0.5;
    if (indicators.isMacdBullish && indicators.isAboveSma20) confluence += 0.25;
    if (indicators.rsi >= 40 && indicators.rsi <= 65) confluence += 0.15;
    if (indicators.volumeTrendRatio >= 1.1) confluence += 0.10;
    final confidence = confluence.clamp(0.40, 0.98);

    // Projected target sell date (adjusting for NEPSE weekends: Friday & Saturday)
    DateTime targetDate = _calculateTradingDaysForward(baseDate, optimalDays);
    final targetDateBS = BikramSambatService.adToBs(targetDate).formatBs();

    // Projected return percentage based on momentum and holding window
    final projectedReturn =
        (3.5 + (optimalDays * 0.28) + (indicators.histogram * 0.4)).clamp(
          4.0,
          35.0,
        );
    final projectedExitPrice = double.parse(
      (buyPrice * (1.0 + (projectedReturn / 100.0))).toStringAsFixed(1),
    );

    // Recommendation strategy
    String recommendation;
    if (indicators.rsi < 35 && indicators.isMacdBullish) {
      recommendation = 'Strong Hold & Accumulate';
    } else if (indicators.rsi > 70) {
      recommendation = 'Take Profit Soon (Overbought)';
    } else if (optimalDays <= 12) {
      recommendation = 'Tight Stop-Loss / Near Target';
    } else if (indicators.trendSignal == 'STRONG_BUY') {
      recommendation = 'Strong Hold (Riding Bull Momentum)';
    } else {
      recommendation = 'Standard Swing Hold';
    }

    final featureContributions = {
      'RSI Dynamic': (_wRsi * rsiNorm).abs(),
      'MACD Momentum': (_wMacd * macdHistNorm).abs(),
      'SMA Trend': (_wSma * smaRatio).abs(),
      'Volume Surge': (_wVol * volRatio).abs(),
      'Position Scale': (_wQty * logQty).abs(),
    };

    return HoldingPrediction(
      predictedDays: optimalDays,
      confidence: confidence,
      targetSellDate: targetDate,
      targetSellDateBS: targetDateBS,
      recommendation: recommendation,
      projectedExitPrice: projectedExitPrice,
      projectedReturnPercentage: projectedReturn,
      featureContributions: featureContributions,
      modelVersion: estimateVersion,
    );
  }

  /// Calculates future date skipping Friday and Saturday (NEPSE market closed)
  static DateTime _calculateTradingDaysForward(
    DateTime start,
    int tradingDays,
  ) {
    DateTime current = start;
    int addedDays = 0;

    while (addedDays < tradingDays) {
      current = current.add(const Duration(days: 1));
      // In Dart, Friday=5, Saturday=6
      if (current.weekday != DateTime.friday &&
          current.weekday != DateTime.saturday) {
        addedDays++;
      }
    }

    return current;
  }
}
