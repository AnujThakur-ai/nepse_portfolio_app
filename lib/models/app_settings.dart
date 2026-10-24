enum DataDisplayMode { telemetryCards, interactiveCharts, analogGauges }

class DashboardSectionConfig {
  final String id;
  final String title;
  final bool isVisible;
  final bool isPinned;
  final int order;

  const DashboardSectionConfig({
    required this.id,
    required this.title,
    this.isVisible = true,
    this.isPinned = false,
    required this.order,
  });

  DashboardSectionConfig copyWith({
    String? id,
    String? title,
    bool? isVisible,
    bool? isPinned,
    int? order,
  }) {
    return DashboardSectionConfig(
      id: id ?? this.id,
      title: title ?? this.title,
      isVisible: isVisible ?? this.isVisible,
      isPinned: isPinned ?? this.isPinned,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isVisible': isVisible,
    'isPinned': isPinned,
    'order': order,
  };

  factory DashboardSectionConfig.fromJson(Map<String, dynamic> json) {
    return DashboardSectionConfig(
      id: json['id'] as String,
      title: json['title'] as String,
      isVisible: json['isVisible'] as bool? ?? true,
      isPinned: json['isPinned'] as bool? ?? false,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppSettings {
  final int themeIndex; // 0 to 10
  final DataDisplayMode displayMode;
  final bool hasCompletedOnboarding;
  final bool isBiometricEnabled;
  final bool isPinSecurityEnabled;
  final String pinHash;
  final bool notifyPriceAlerts;
  final bool notifyMacdSignals;
  final bool notifySellDateReminders;
  final bool notifyPnlMilestones;
  final String displayName;
  final String emailAddress;
  final String phoneNumber;
  final String location;
  final String profileBio;
  final String
  investorType; // 'INDIVIDUAL_SHORT', 'INDIVIDUAL_LONG', 'INSTITUTIONAL'
  final List<String> activeShortcuts;
  final List<DashboardSectionConfig> dashboardSections;

  const AppSettings({
    this.themeIndex = 10,
    this.displayMode = DataDisplayMode.telemetryCards,
    this.hasCompletedOnboarding = false,
    this.isBiometricEnabled = false,
    this.isPinSecurityEnabled = false,
    this.pinHash = '',
    this.notifyPriceAlerts = true,
    this.notifyMacdSignals = true,
    this.notifySellDateReminders = true,
    this.notifyPnlMilestones = true,
    this.displayName = '',
    this.emailAddress = '',
    this.phoneNumber = '',
    this.location = '',
    this.profileBio = '',
    this.investorType = 'INDIVIDUAL_SHORT',
    this.activeShortcuts = const [
      'quick_buy',
      'macd_scan',
      'target_dates',
      'pnl_summary',
      'nepse_calc',
    ],
    this.dashboardSections = const [
      DashboardSectionConfig(
        id: 'telemetry_overview',
        title: 'Portfolio Telemetry',
        order: 0,
      ),
      DashboardSectionConfig(
        id: 'shortcut_ribbon',
        title: 'Action Ribbon',
        order: 1,
      ),
      DashboardSectionConfig(
        id: 'market_indices',
        title: 'NEPSE Indices & Market Status',
        order: 2,
      ),
      DashboardSectionConfig(
        id: 'holding_targets',
        title: 'ML Target Sell Deadlines',
        order: 3,
      ),
      DashboardSectionConfig(
        id: 'active_holdings',
        title: 'Active Stock Holdings',
        order: 4,
      ),
      DashboardSectionConfig(
        id: 'technical_radar',
        title: 'MACD / RSI Radar Scanner',
        order: 5,
      ),
      DashboardSectionConfig(
        id: 'sector_pie',
        title: 'Sector Allocation Breakdown',
        order: 6,
      ),
    ],
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
    String? displayName,
    String? emailAddress,
    String? phoneNumber,
    String? location,
    String? profileBio,
    String? investorType,
    List<String>? activeShortcuts,
    List<DashboardSectionConfig>? dashboardSections,
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
      displayName: displayName ?? this.displayName,
      emailAddress: emailAddress ?? this.emailAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      profileBio: profileBio ?? this.profileBio,
      investorType: investorType ?? this.investorType,
      activeShortcuts: activeShortcuts ?? this.activeShortcuts,
      dashboardSections: dashboardSections ?? this.dashboardSections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      'displayName': displayName,
      'emailAddress': emailAddress,
      'phoneNumber': phoneNumber,
      'location': location,
      'profileBio': profileBio,
      'investorType': investorType,
      'activeShortcuts': activeShortcuts,
      'dashboardSections': dashboardSections.map((s) => s.toJson()).toList(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawMode = json['displayMode'];
    final requestedModeIndex = rawMode is num ? rawMode.toInt() : 0;
    final modeIndex =
        requestedModeIndex >= 0 &&
            requestedModeIndex < DataDisplayMode.values.length
        ? requestedModeIndex
        : 0;
    final rawSections = json['dashboardSections'];
    return AppSettings(
      themeIndex:
          (json['themeIndex'] is num ? (json['themeIndex'] as num).toInt() : 0)
              .clamp(0, 10),
      displayMode: DataDisplayMode.values[modeIndex],
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      isBiometricEnabled: json['isBiometricEnabled'] as bool? ?? false,
      isPinSecurityEnabled: json['isPinSecurityEnabled'] as bool? ?? false,
      pinHash: json['pinHash'] as String? ?? '',
      notifyPriceAlerts: json['notifyPriceAlerts'] as bool? ?? true,
      notifyMacdSignals: json['notifyMacdSignals'] as bool? ?? true,
      notifySellDateReminders: json['notifySellDateReminders'] as bool? ?? true,
      notifyPnlMilestones: json['notifyPnlMilestones'] as bool? ?? true,
      displayName: json['displayName'] as String? ?? '',
      emailAddress: json['emailAddress'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      location: json['location'] as String? ?? '',
      profileBio: json['profileBio'] as String? ?? '',
      investorType: json['investorType'] as String? ?? 'INDIVIDUAL_SHORT',
      activeShortcuts:
          (json['activeShortcuts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'quick_buy',
            'macd_scan',
            'target_dates',
            'pnl_summary',
            'nepse_calc',
          ],
      dashboardSections:
          (rawSections is List ? rawSections : null)
              ?.whereType<Map>()
              .map(
                (e) => DashboardSectionConfig.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList() ??
          const [
            DashboardSectionConfig(
              id: 'telemetry_overview',
              title: 'Portfolio Telemetry',
              order: 0,
            ),
            DashboardSectionConfig(
              id: 'shortcut_ribbon',
              title: 'Action Ribbon',
              order: 1,
            ),
            DashboardSectionConfig(
              id: 'market_indices',
              title: 'NEPSE Indices & Market Status',
              order: 2,
            ),
            DashboardSectionConfig(
              id: 'holding_targets',
              title: 'ML Target Sell Deadlines',
              order: 3,
            ),
            DashboardSectionConfig(
              id: 'active_holdings',
              title: 'Active Stock Holdings',
              order: 4,
            ),
            DashboardSectionConfig(
              id: 'technical_radar',
              title: 'MACD / RSI Radar Scanner',
              order: 5,
            ),
            DashboardSectionConfig(
              id: 'sector_pie',
              title: 'Sector Allocation Breakdown',
              order: 6,
            ),
          ],
    );
  }
}
