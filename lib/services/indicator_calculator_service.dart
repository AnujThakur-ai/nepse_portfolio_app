import 'dart:math';

import '../models/technical_indicator_data.dart';

class IndicatorCalculatorService {
  /// Computes Simple Moving Average (SMA)
  static List<double> calculateSMA(List<double> prices, int period) {
    if (prices.isEmpty) return [];
    if (prices.length < period) return List.filled(prices.length, prices.last);

    final List<double> sma = [];
    for (int i = 0; i < prices.length; i++) {
      if (i < period - 1) {
        sma.add(prices[i]);
      } else {
        double sum = 0;
        for (int j = i - period + 1; j <= i; j++) {
          sum += prices[j];
        }
        sma.add(sum / period);
      }
    }
    return sma;
  }

  /// Computes Exponential Moving Average (EMA)
  static List<double> calculateEMA(List<double> prices, int period) {
    if (prices.isEmpty) return [];
    if (prices.length < period) return List.filled(prices.length, prices.last);

    final List<double> ema = List.filled(prices.length, 0.0);
    final multiplier = 2.0 / (period + 1);

    // Initial EMA is the SMA of first `period` elements
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += prices[i];
      ema[i] = prices[i];
    }
    ema[period - 1] = sum / period;

    for (int i = period; i < prices.length; i++) {
      ema[i] = (prices[i] - ema[i - 1]) * multiplier + ema[i - 1];
    }

    return ema;
  }

  /// Computes Relative Strength Index (RSI - 14 periods) using Wilder smoothing
  static double calculateRSI(List<double> prices, [int period = 14]) {
    if (prices.length <= period) return 50.0;

    double gains = 0.0;
    double losses = 0.0;

    for (int i = 1; i <= period; i++) {
      final change = prices[i] - prices[i - 1];
      if (change > 0) {
        gains += change;
      } else {
        losses += change.abs();
      }
    }

    double avgGain = gains / period;
    double avgLoss = losses / period;

    for (int i = period + 1; i < prices.length; i++) {
      final change = prices[i] - prices[i - 1];
      final currentGain = change > 0 ? change : 0.0;
      final currentLoss = change < 0 ? change.abs() : 0.0;

      avgGain = (avgGain * (period - 1) + currentGain) / period;
      avgLoss = (avgLoss * (period - 1) + currentLoss) / period;
    }

    if (avgLoss == 0) return avgGain == 0 ? 50.0 : 100.0;
    final rs = avgGain / avgLoss;
    return 100.0 - (100.0 / (1.0 + rs));
  }

  /// Computes MACD (Moving Average Convergence Divergence)
  /// Returns [macdLine, signalLine, histogram] for the latest bar
  static Map<String, double> calculateMACD(
    List<double> prices, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    if (prices.length < slowPeriod) {
      return {'macd': 0.0, 'signal': 0.0, 'histogram': 0.0};
    }

    final fastEMA = calculateEMA(prices, fastPeriod);
    final slowEMA = calculateEMA(prices, slowPeriod);

    final List<double> macdSeries = [];
    for (int i = 0; i < prices.length; i++) {
      macdSeries.add(fastEMA[i] - slowEMA[i]);
    }

    final signalEMA = calculateEMA(macdSeries, signalPeriod);

    final currentMacd = macdSeries.last;
    final currentSignal = signalEMA.last;
    final currentHist = currentMacd - currentSignal;

    return {
      'macd': currentMacd,
      'signal': currentSignal,
      'histogram': currentHist,
    };
  }

  /// Computes Bollinger Bands (20 periods, 2 standard deviations)
  static Map<String, double> calculateBollingerBands(
    List<double> prices, [
    int period = 20,
    double stdDevMultiplier = 2.0,
  ]) {
    if (prices.length < period) {
      final p = prices.isNotEmpty ? prices.last : 0.0;
      return {'upper': p * 1.05, 'middle': p, 'lower': p * 0.95};
    }

    final recentSlice = prices.sublist(prices.length - period);
    final middle = recentSlice.reduce((a, b) => a + b) / period;

    double varianceSum = 0;
    for (final price in recentSlice) {
      varianceSum += pow(price - middle, 2);
    }
    final stdDev = sqrt(varianceSum / period);

    return {
      'upper': middle + (stdDevMultiplier * stdDev),
      'middle': middle,
      'lower': middle - (stdDevMultiplier * stdDev),
    };
  }

  /// Aggregates all indicators for a symbol and computes composite sentiment score
  static TechnicalIndicatorData analyzeSymbol({
    required String symbol,
    required List<double> prices,
    required List<double> volumes,
  }) {
    if (prices.isEmpty) {
      return TechnicalIndicatorData(
        symbol: symbol,
        prices: const [],
        volumes: const [],
        currentPrice: 0,
        macdLine: 0,
        signalLine: 0,
        histogram: 0,
        rsi: 50,
        sma20: 0,
        sma50: 0,
        sma200: 0,
        upperBollinger: 0,
        middleBollinger: 0,
        lowerBollinger: 0,
        volumeTrendRatio: 1.0,
        sentimentScore: 50,
        trendSignal: 'NEUTRAL',
      );
    }

    final currentPrice = prices.last;
    final macd = calculateMACD(prices);
    final rsi = calculateRSI(prices);
    final sma20List = calculateSMA(prices, 20);
    final sma50List = calculateSMA(prices, 50);
    final sma200List = calculateSMA(prices, 200);
    final bollinger = calculateBollingerBands(prices);

    final sma20 = sma20List.last;
    final sma50 = sma50List.last;
    final sma200 = sma200List.last;

    // Volume trend ratio: last volume vs avg volume
    double volumeTrend = 1.0;
    if (volumes.isNotEmpty) {
      final avgVol = volumes.reduce((a, b) => a + b) / volumes.length;
      volumeTrend = avgVol > 0 ? (volumes.last / avgVol) : 1.0;
    }

    // Composite Sentiment Gauge (0 to 100)
    // 1. RSI contribution (30% weight): normalized around 50
    final rsiScore = rsi.clamp(0.0, 100.0);

    // 2. MACD contribution (30% weight): positive histogram is bullish
    final histScore = (50.0 + (macd['histogram']! * 5.0)).clamp(0.0, 100.0);

    // 3. Moving Average Trend (25% weight)
    double maScore = 50.0;
    if (currentPrice > sma20) maScore += 15.0;
    if (currentPrice > sma50) maScore += 15.0;
    if (currentPrice > sma200) maScore += 20.0;
    maScore = maScore.clamp(0.0, 100.0);

    // 4. Volume confirmation (15% weight)
    final volScore = (volumeTrend * 50.0).clamp(20.0, 100.0);

    final sentimentScore =
        (rsiScore * 0.30) +
        (histScore * 0.30) +
        (maScore * 0.25) +
        (volScore * 0.15);

    String trendSignal;
    if (sentimentScore >= 75) {
      trendSignal = 'STRONG_BUY';
    } else if (sentimentScore >= 58) {
      trendSignal = 'BUY';
    } else if (sentimentScore <= 30) {
      trendSignal = 'STRONG_SELL';
    } else if (sentimentScore <= 45) {
      trendSignal = 'SELL';
    } else {
      trendSignal = 'NEUTRAL';
    }

    return TechnicalIndicatorData(
      symbol: symbol,
      prices: prices,
      volumes: volumes,
      currentPrice: currentPrice,
      macdLine: macd['macd']!,
      signalLine: macd['signal']!,
      histogram: macd['histogram']!,
      rsi: rsi,
      sma20: sma20,
      sma50: sma50,
      sma200: sma200,
      upperBollinger: bollinger['upper']!,
      middleBollinger: bollinger['middle']!,
      lowerBollinger: bollinger['lower']!,
      volumeTrendRatio: volumeTrend,
      sentimentScore: sentimentScore.clamp(0.0, 100.0),
      trendSignal: trendSignal,
    );
  }
}
