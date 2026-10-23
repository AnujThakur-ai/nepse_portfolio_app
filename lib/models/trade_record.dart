class TradeRecord {
  final String id;
  final String symbol;
  final String companyName;
  final String transactionType;
  final DateTime transactionDate;
  final int quantity;
  final double pricePerShare;
  final String sector;
  final double currentPrice;
  final double targetPrice;
  final int predictedHoldingDays;
  final String status;

  const TradeRecord({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.transactionType,
    required this.transactionDate,
    required this.quantity,
    required this.pricePerShare,
    required this.sector,
    required this.currentPrice,
    required this.targetPrice,
    required this.predictedHoldingDays,
    required this.status,
  });

  double get totalAmount => quantity * pricePerShare;
  double get currentValue => quantity * currentPrice;
  double get totalInvestment => totalAmount;
  double get profitOrLoss => currentValue - totalInvestment;
  double get profitOrLossPercentage =>
      totalInvestment == 0 ? 0 : (profitOrLoss / totalInvestment) * 100;

  TradeRecord copyWith({
    String? id,
    String? symbol,
    String? companyName,
    String? transactionType,
    DateTime? transactionDate,
    int? quantity,
    double? pricePerShare,
    String? sector,
    double? currentPrice,
    double? targetPrice,
    int? predictedHoldingDays,
    String? status,
  }) {
    return TradeRecord(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      companyName: companyName ?? this.companyName,
      transactionType: transactionType ?? this.transactionType,
      transactionDate: transactionDate ?? this.transactionDate,
      quantity: quantity ?? this.quantity,
      pricePerShare: pricePerShare ?? this.pricePerShare,
      sector: sector ?? this.sector,
      currentPrice: currentPrice ?? this.currentPrice,
      targetPrice: targetPrice ?? this.targetPrice,
      predictedHoldingDays: predictedHoldingDays ?? this.predictedHoldingDays,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'companyName': companyName,
        'transactionType': transactionType,
        'transactionDate': transactionDate.toIso8601String(),
        'quantity': quantity,
        'pricePerShare': pricePerShare,
        'sector': sector,
        'currentPrice': currentPrice,
        'targetPrice': targetPrice,
        'predictedHoldingDays': predictedHoldingDays,
        'status': status,
      };

  factory TradeRecord.fromJson(Map<String, dynamic> json) {
    return TradeRecord(
      id: json['id'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      transactionType: json['transactionType'] as String? ?? 'BUY',
      transactionDate: DateTime.tryParse(
                (json['transactionDate'] as String?) ?? DateTime.now().toIso8601String(),
              ) ??
              DateTime.now(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      pricePerShare: (json['pricePerShare'] as num?)?.toDouble() ?? 0,
      sector: json['sector'] as String? ?? 'Unknown',
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
      targetPrice: (json['targetPrice'] as num?)?.toDouble() ?? 0,
      predictedHoldingDays: (json['predictedHoldingDays'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}
