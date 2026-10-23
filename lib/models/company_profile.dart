class CompanyProfile {
  final String symbol;
  final String companyName;
  final String sector;
  final double ltp;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double previousClose;
  final double priceChange;
  final double percentageChange;
  final int volume;
  final double peRatio;
  final double pbRatio;
  final double eps;
  final double bookValue;
  final double fiftyTwoWeekHigh;
  final double fiftyTwoWeekLow;
  final List<double> recentPrices;
  final String marketCap; // in Crores
  final String description;

  const CompanyProfile({
    required this.symbol,
    required this.companyName,
    required this.sector,
    required this.ltp,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.previousClose,
    required this.priceChange,
    required this.percentageChange,
    required this.volume,
    required this.peRatio,
    required this.pbRatio,
    required this.eps,
    required this.bookValue,
    required this.fiftyTwoWeekHigh,
    required this.fiftyTwoWeekLow,
    required this.recentPrices,
    this.marketCap = '',
    this.description = '',
  });

  bool get isBullish => priceChange >= 0;

  // Circuit limits (+-10% in NEPSE)
  double get upperCircuitLimit => (previousClose * 1.10).floorToDouble();
  double get lowerCircuitLimit => (previousClose * 0.90).ceilToDouble();

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'companyName': companyName,
      'sector': sector,
      'ltp': ltp,
      'openPrice': openPrice,
      'highPrice': highPrice,
      'lowPrice': lowPrice,
      'previousClose': previousClose,
      'priceChange': priceChange,
      'percentageChange': percentageChange,
      'volume': volume,
      'peRatio': peRatio,
      'pbRatio': pbRatio,
      'eps': eps,
      'bookValue': bookValue,
      'fiftyTwoWeekHigh': fiftyTwoWeekHigh,
      'fiftyTwoWeekLow': fiftyTwoWeekLow,
      'recentPrices': recentPrices,
      'marketCap': marketCap,
      'description': description,
    };
  }

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      symbol: json['symbol'] as String,
      companyName: json['companyName'] as String,
      sector: json['sector'] as String,
      ltp: (json['ltp'] as num).toDouble(),
      openPrice: (json['openPrice'] as num).toDouble(),
      highPrice: (json['highPrice'] as num).toDouble(),
      lowPrice: (json['lowPrice'] as num).toDouble(),
      previousClose: (json['previousClose'] as num).toDouble(),
      priceChange: (json['priceChange'] as num).toDouble(),
      percentageChange: (json['percentageChange'] as num).toDouble(),
      volume: (json['volume'] as num).toInt(),
      peRatio: (json['peRatio'] as num).toDouble(),
      pbRatio: (json['pbRatio'] as num).toDouble(),
      eps: (json['eps'] as num).toDouble(),
      bookValue: (json['bookValue'] as num).toDouble(),
      fiftyTwoWeekHigh: (json['fiftyTwoWeekHigh'] as num).toDouble(),
      fiftyTwoWeekLow: (json['fiftyTwoWeekLow'] as num).toDouble(),
      recentPrices:
          (json['recentPrices'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      marketCap: json['marketCap'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}
