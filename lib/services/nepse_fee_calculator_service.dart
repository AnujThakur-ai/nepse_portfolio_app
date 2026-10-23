class NepseCalculationResult {
  final double grossAmount;
  final double brokerCommission;
  final double sebonFee;
  final double dpFee;
  final double effectiveCost; // For buy: gross + fees; For sell: gross - fees
  final double capitalGainsTax;
  final double netReceivable; // For sell
  final double profitOrLoss;
  final double profitPercentage;
  final double breakevenPrice;

  const NepseCalculationResult({
    required this.grossAmount,
    required this.brokerCommission,
    required this.sebonFee,
    required this.dpFee,
    required this.effectiveCost,
    this.capitalGainsTax = 0.0,
    this.netReceivable = 0.0,
    this.profitOrLoss = 0.0,
    this.profitPercentage = 0.0,
    this.breakevenPrice = 0.0,
  });
}

class NepseFeeCalculatorService {
  static const double sebonFeeRate = 0.00015; // 0.015%
  static const double dpFeeStandard = 25.0; // Rs 25 flat per trade

  /// Calculates slab-based broker commission according to NEPSE guidelines
  static double calculateBrokerCommission(double amount) {
    if (amount <= 0) return 0.0;

    double commission = 0.0;
    if (amount <= 50000) {
      commission = amount * 0.0040; // 0.40%
    } else if (amount <= 500000) {
      commission = amount * 0.0037; // 0.37%
    } else if (amount <= 2000000) {
      commission = amount * 0.0034; // 0.34%
    } else if (amount <= 10000000) {
      commission = amount * 0.0030; // 0.30%
    } else {
      commission = amount * 0.0027; // 0.27%
    }

    // Minimum broker commission is Rs 10
    return commission < 10.0 ? 10.0 : commission;
  }

  /// Calculates SEBON regulatory fee (0.015%)
  static double calculateSebonFee(double amount) {
    return amount * sebonFeeRate;
  }

  /// Calculates the complete buy transaction breakdown
  static NepseCalculationResult calculateBuy({
    required int quantity,
    required double pricePerShare,
  }) {
    final grossAmount = quantity * pricePerShare;
    final brokerCommission = calculateBrokerCommission(grossAmount);
    final sebonFee = calculateSebonFee(grossAmount);
    const dpFee = dpFeeStandard;

    final totalFees = brokerCommission + sebonFee + dpFee;
    final effectiveCost = grossAmount + totalFees;

    // Estimate breakeven selling price
    final breakevenPrice = _calculateBreakevenPrice(quantity, effectiveCost);

    return NepseCalculationResult(
      grossAmount: grossAmount,
      brokerCommission: brokerCommission,
      sebonFee: sebonFee,
      dpFee: dpFee,
      effectiveCost: effectiveCost,
      breakevenPrice: breakevenPrice,
    );
  }

  /// Calculates the complete sell transaction breakdown with CGT
  static NepseCalculationResult calculateSell({
    required int quantity,
    required double sellPrice,
    required double originalPurchaseCost,
    required int holdingDays,
    String investorType = 'INDIVIDUAL_SHORT', // 'INDIVIDUAL_SHORT', 'INDIVIDUAL_LONG', 'INSTITUTIONAL'
  }) {
    final grossAmount = quantity * sellPrice;
    final brokerCommission = calculateBrokerCommission(grossAmount);
    final sebonFee = calculateSebonFee(grossAmount);
    const dpFee = dpFeeStandard;

    final totalSellingFees = brokerCommission + sebonFee + dpFee;
    final netSellBeforeTax = grossAmount - totalSellingFees;

    // Capital gains: Net Selling Before Tax - Effective Purchase Cost
    final rawCapitalGain = netSellBeforeTax - originalPurchaseCost;
    double cgt = 0.0;

    if (rawCapitalGain > 0) {
      double cgtRate = 0.075; // Default 7.5% individual short-term (< 365 days)
      if (investorType == 'INDIVIDUAL_LONG' || holdingDays >= 365) {
        cgtRate = 0.05; // 5.0% for long-term (>= 365 days)
      } else if (investorType == 'INSTITUTIONAL') {
        cgtRate = 0.10; // 10.0% institutional
      }
      cgt = rawCapitalGain * cgtRate;
    }

    final netReceivable = netSellBeforeTax - cgt;
    final profitOrLoss = netReceivable - originalPurchaseCost;
    final profitPercentage = originalPurchaseCost > 0
        ? (profitOrLoss / originalPurchaseCost) * 100
        : 0.0;

    return NepseCalculationResult(
      grossAmount: grossAmount,
      brokerCommission: brokerCommission,
      sebonFee: sebonFee,
      dpFee: dpFee,
      effectiveCost: originalPurchaseCost,
      capitalGainsTax: cgt,
      netReceivable: netReceivable,
      profitOrLoss: profitOrLoss,
      profitPercentage: profitPercentage,
    );
  }

  static double _calculateBreakevenPrice(int quantity, double totalBuyCost) {
    if (quantity <= 0) return 0.0;
    // Iteratively or analytically solve for sell price where netReceivable == totalBuyCost
    // SellNet = P*Q - Comm(P*Q) - Sebon(P*Q) - 25 == totalBuyCost
    // Approx Comm rate is ~0.37% + 0.015% = 0.385%
    double approxRate = 0.0037 + sebonFeeRate;
    double targetGross = (totalBuyCost + dpFeeStandard) / (1.0 - approxRate);
    return double.parse((targetGross / quantity).toStringAsFixed(2));
  }
}
