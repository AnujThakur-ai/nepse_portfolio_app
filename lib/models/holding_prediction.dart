class HoldingPrediction {
  final int predictedDays;
  final double confidence; // 0.0 to 1.0
  final DateTime targetSellDate;
  final String targetSellDateBS;
  final String recommendation; // 'Strong Hold', 'Accumulate', 'Take Profit Soon', 'Scale Out'
  final double projectedExitPrice;
  final double projectedReturnPercentage;
  final Map<String, double>
  featureContributions; // feature name -> weight/importance
  final String modelVersion;

  const HoldingPrediction({
    required this.predictedDays,
    required this.confidence,
    required this.targetSellDate,
    required this.targetSellDateBS,
    required this.recommendation,
    required this.projectedExitPrice,
    required this.projectedReturnPercentage,
    required this.featureContributions,
    this.modelVersion = 'Rule-based-v1',
  });

  Map<String, dynamic> toJson() {
    return {
      'predictedDays': predictedDays,
      'confidence': confidence,
      'targetSellDate': targetSellDate.toIso8601String(),
      'targetSellDateBS': targetSellDateBS,
      'recommendation': recommendation,
      'projectedExitPrice': projectedExitPrice,
      'projectedReturnPercentage': projectedReturnPercentage,
      'featureContributions': featureContributions,
      'modelVersion': modelVersion,
    };
  }

  factory HoldingPrediction.fromJson(Map<String, dynamic> json) {
    return HoldingPrediction(
      predictedDays: (json['predictedDays'] as num).toInt(),
      confidence: (json['confidence'] as num).toDouble(),
      targetSellDate: DateTime.parse(json['targetSellDate'] as String),
      targetSellDateBS: json['targetSellDateBS'] as String? ?? '',
      recommendation: json['recommendation'] as String,
      projectedExitPrice: (json['projectedExitPrice'] as num).toDouble(),
      projectedReturnPercentage: (json['projectedReturnPercentage'] as num)
          .toDouble(),
      featureContributions: Map<String, double>.from(
        json['featureContributions'] as Map,
      ),
      modelVersion: json['modelVersion'] as String? ?? 'Rule-based-v1',
    );
  }
}
