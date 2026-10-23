class TradeRecord {
  final String id;
  final String symbol;
  final String companyName;
  final String sector;
  final String transactionType; // 'BUY' or 'SELL'
  final DateTime transactionDate;
  final String bsDate;
  final int quantity;
  final double pricePerShare;
  final double totalAmount;
  final double brokerCommission;
  final double sebonFee;
  final double dpCharge;
  final double effectiveCost;
  final double capitalGainsTax;
  final DateTime targetSellDate;
  final String targetSellDateBS;
  final int predictedHoldingDays;
  final String status; // 'HOLDING', 'SOLD', 'TARGET_REACHED'
  final String? receiptImagePath;
  final String notes;
  final double? currentLtp;

  TradeRecord({
    required this.id,
    required this.symbol,
    required this.companyName,
    required this.sector,
    required this.transactionType,
    required this.transactionDate,
    required this.bsDate,
    required this.quantity,
    required this.pricePerShare,
    required this.totalAmount,
    required this.brokerCommission,
    required this.sebonFee,
    required this.dpCharge,
    required this.effectiveCost,
    this.capitalGainsTax = 0.0,
    required this.targetSellDate,
    required this.targetSellDateBS,
    required this.predictedHoldingDays,
    this.status = 'HOLDING',
    this.receiptImagePath,
    this.notes = '',
    this.currentLtp,
  });

  double get currentValue => (currentLtp ?? pricePerShare) * quantity;
  double get profitOrLoss => currentValue - effectiveCost;
  double get profitOrLossPercentage =>
      effectiveCost > 0 ? (profitOrLoss / effectiveCost) * 100 : 0.0;
  bool get isProfitable => profitOrLoss >= 0;

  int get daysHeld {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final tx = DateTime.utc(
      transactionDate.year,
      transactionDate.month,
      transactionDate.day,
    );
    return today.difference(tx).inDays;
  }

  int get daysRemainingToTarget {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final target = DateTime.utc(
      targetSellDate.year,
      targetSellDate.month,
      targetSellDate.day,
    );
    return target.difference(today).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'companyName': companyName,
      'sector': sector,
      'transactionType': transactionType,
      'transactionDate': transactionDate.toIso8601String(),
      'bsDate': bsDate,
      'quantity': quantity,
      'pricePerShare': pricePerShare,
      'totalAmount': totalAmount,
      'brokerCommission': brokerCommission,
      'sebonFee': sebonFee,
      'dpCharge': dpCharge,
      'effectiveCost': effectiveCost,
      'capitalGainsTax': capitalGainsTax,
      'targetSellDate': targetSellDate.toIso8601String(),
      'targetSellDateBS': targetSellDateBS,
      'predictedHoldingDays': predictedHoldingDays,
      'status': status,
      'receiptImagePath': receiptImagePath,
      'notes': notes,
      'currentLtp': currentLtp,
    };
  }

  factory TradeRecord.fromJson(Map<String, dynamic> json) {
    return TradeRecord(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      companyName: json['companyName'] as String? ?? json['symbol'] as String,
      sector: json['sector'] as String? ?? 'General',
      transactionType: json['transactionType'] as String? ?? 'BUY',
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      bsDate: json['bsDate'] as String? ?? '',
      quantity: (json['quantity'] as num).toInt(),
      pricePerShare: (json['pricePerShare'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      brokerCommission: (json['brokerCommission'] as num).toDouble(),
      sebonFee: (json['sebonFee'] as num).toDouble(),
      dpCharge: (json['dpCharge'] as num).toDouble(),
      effectiveCost: (json['effectiveCost'] as num).toDouble(),
      capitalGainsTax: (json['capitalGainsTax'] as num?)?.toDouble() ?? 0.0,
      targetSellDate: DateTime.parse(json['targetSellDate'] as String),
      targetSellDateBS: json['targetSellDateBS'] as String? ?? '',
      predictedHoldingDays: (json['predictedHoldingDays'] as num).toInt(),
      status: json['status'] as String? ?? 'HOLDING',
      receiptImagePath: json['receiptImagePath'] as String?,
      notes: json['notes'] as String? ?? '',
      currentLtp: (json['currentLtp'] as num?)?.toDouble(),
    );
  }

  TradeRecord copyWith({
    String? id,
    String? symbol,
    String? companyName,
    String? sector,
    String? transactionType,
    DateTime? transactionDate,
    String? bsDate,
    int? quantity,
    double? pricePerShare,
    double? totalAmount,
    double? brokerCommission,
    double? sebonFee,
    double? dpCharge,
    double? effectiveCost,
    double? capitalGainsTax,
    DateTime? targetSellDate,
    String? targetSellDateBS,
    int? predictedHoldingDays,
    String? status,
    String? receiptImagePath,
    String? notes,
    double? currentLtp,
  }) {
    return TradeRecord(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      companyName: companyName ?? this.companyName,
      sector: sector ?? this.sector,
      transactionType: transactionType ?? this.transactionType,
      transactionDate: transactionDate ?? this.transactionDate,
      bsDate: bsDate ?? this.bsDate,
      quantity: quantity ?? this.quantity,
      pricePerShare: pricePerShare ?? this.pricePerShare,
      totalAmount: totalAmount ?? this.totalAmount,
      brokerCommission: brokerCommission ?? this.brokerCommission,
      sebonFee: sebonFee ?? this.sebonFee,
      dpCharge: dpCharge ?? this.dpCharge,
      effectiveCost: effectiveCost ?? this.effectiveCost,
      capitalGainsTax: capitalGainsTax ?? this.capitalGainsTax,
      targetSellDate: targetSellDate ?? this.targetSellDate,
      targetSellDateBS: targetSellDateBS ?? this.targetSellDateBS,
      predictedHoldingDays: predictedHoldingDays ?? this.predictedHoldingDays,
      status: status ?? this.status,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      notes: notes ?? this.notes,
      currentLtp: currentLtp ?? this.currentLtp,
    );
  }
}
