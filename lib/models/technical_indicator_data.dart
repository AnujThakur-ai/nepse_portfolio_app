class TechnicalIndicatorData {
  final String symbol;
  final List<double> prices;
  final List<double> volumes;
  final double currentPrice;
  final double macdLine;
  final double signalLine;
  final double histogram;
  final double rsi;
  final double sma20;
  final double sma50;
  final double sma200;
  final double upperBollinger;
  final double middleBollinger;
  final double lowerBollinger;
  final double volumeTrendRatio; // e.g. today's volume vs 20-day avg
  final double
  sentimentScore; // 0 to 100 gauge (0=Extreme Fear, 100=Extreme Greed)
  final String
  trendSignal; // 'STRONG_BUY', 'BUY', 'NEUTRAL', 'SELL', 'STRONG_SELL'

  const TechnicalIndicatorData({
    required this.symbol,
    required this.prices,
    required this.volumes,
    required this.currentPrice,
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
    required this.rsi,
    required this.sma20,
    required this.sma50,
    required this.sma200,
    required this.upperBollinger,
    required this.middleBollinger,
    required this.lowerBollinger,
    required this.volumeTrendRatio,
    required this.sentimentScore,
    required this.trendSignal,
  });

  bool get isMacdBullish => histogram > 0;
  bool get isRsiOversold => rsi < 30;
  bool get isRsiOverbought => rsi > 70;
  bool get isAboveSma20 => currentPrice > sma20;
  bool get isAboveSma200 => currentPrice > sma200;
}
