enum DataDisplayMode {
  telemetry,
  charts,
  gauges,
}

class AppSettings {
  final int themeIndex;
  final DataDisplayMode displayMode;
  final bool hasCompletedOnboarding;
  final bool isBiometricEnabled;
  final bool isPinSecurityEnabled;
  final String pinHash;
  final bool notifyPriceAlerts;
  final bool notifyMacdSignals;
  final bool notifySellDateReminders;
  final bool notifyPnlMilestones;
  final String investorType;

  const AppSettings({
    this.themeIndex = 0,
    this.displayMode = DataDisplayMode.telemetry,
    this.hasCompletedOnboarding = false,
    this.isBiometricEnabled = false,
    this.isPinSecurityEnabled = false,
    this.pinHash = '',
    this.notifyPriceAlerts = true,
    this.notifyMacdSignals = true,
    this.notifySellDateReminders = true,
    this.notifyPnlMilestones = true,
    this.investorType = 'INDIVIDUAL_SHORT',
  });

  AppSettings copyWith({
    int? themeIndex,
    DataDisplayMode? displayMode,
    bool? hasCompletedOnboarding,
    bool? isBiometricEnabled,
    bool? isPinSecurityEnabled,
    String? pinHash,
    bool? notifyPriceAlerts,
    bool? notifyMacdSignals,
    bool? notifySellDateReminders,
    bool? notifyPnlMilestones,
    String? investorType,
  }) {
    return AppSettings(
      themeIndex: themeIndex ?? this.themeIndex,
      displayMode: displayMode ?? this.displayMode,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isPinSecurityEnabled: isPinSecurityEnabled ?? this.isPinSecurityEnabled,
      pinHash: pinHash ?? this.pinHash,
      notifyPriceAlerts: notifyPriceAlerts ?? this.notifyPriceAlerts,
      notifyMacdSignals: notifyMacdSignals ?? this.notifyMacdSignals,
      notifySellDateReminders:
          notifySellDateReminders ?? this.notifySellDateReminders,
      notifyPnlMilestones: notifyPnlMilestones ?? this.notifyPnlMilestones,
      investorType: investorType ?? this.investorType,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeIndex': themeIndex,
        'displayMode': displayMode.index,
        'hasCompletedOnboarding': hasCompletedOnboarding,
        'isBiometricEnabled': isBiometricEnabled,
        'isPinSecurityEnabled': isPinSecurityEnabled,
        'pinHash': pinHash,
        'notifyPriceAlerts': notifyPriceAlerts,
        'notifyMacdSignals': notifyMacdSignals,
        'notifySellDateReminders': notifySellDateReminders,
        'notifyPnlMilestones': notifyPnlMilestones,
        'investorType': investorType,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final displayModeIndex = json['displayMode'];
    return AppSettings(
      themeIndex: (json['themeIndex'] as num?)?.toInt() ?? 0,
      displayMode: displayModeIndex is int
          ? DataDisplayMode.values[displayModeIndex.clamp(
              0,
              DataDisplayMode.values.length - 1,
            )]
          : DataDisplayMode.telemetry,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      isBiometricEnabled: json['isBiometricEnabled'] as bool? ?? false,
      isPinSecurityEnabled: json['isPinSecurityEnabled'] as bool? ?? false,
      pinHash: json['pinHash'] as String? ?? '',
      notifyPriceAlerts: json['notifyPriceAlerts'] as bool? ?? true,
      notifyMacdSignals: json['notifyMacdSignals'] as bool? ?? true,
      notifySellDateReminders:
          json['notifySellDateReminders'] as bool? ?? true,
      notifyPnlMilestones: json['notifyPnlMilestones'] as bool? ?? true,
      investorType: json['investorType'] as String? ?? 'INDIVIDUAL_SHORT',
    );
  }
}
