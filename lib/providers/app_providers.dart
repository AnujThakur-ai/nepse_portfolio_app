import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/app_settings.dart';
import '../models/calendar_reminder.dart';
import '../models/technical_indicator_data.dart';
import '../models/trade_record.dart';
import '../services/company_repository.dart';
import '../services/indicator_calculator_service.dart';
import '../services/storage_service.dart';
import '../theme/app_themes.dart';

// --- Theme State & Notifier ---
class ThemeNotifier extends StateNotifier<int> {
  ThemeNotifier(this._ref) : super(10);

  final Ref _ref;

  void initialize(int index) {
    if (index >= 0 && index < AppThemes.allThemes.length) state = index;
  }

  void setTheme(int index) {
    if (index >= 0 && index < AppThemes.allThemes.length) {
      state = index;
      final settings = _ref.read(settingsProvider);
      _ref
          .read(settingsProvider.notifier)
          .updateSettings(settings.copyWith(themeIndex: index));
    }
  }
}

final themeIndexProvider = StateNotifierProvider<ThemeNotifier, int>((ref) {
  return ThemeNotifier(ref);
});

final currentThemeProvider = Provider<ThemeConfig>((ref) {
  final index = ref.watch(themeIndexProvider);
  return AppThemes.getTheme(index);
});

// --- App Settings Notifier ---
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  Future<void> load() async {
    state = await StorageService.loadSettings();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    await StorageService.saveSettings(newSettings);
  }

  Future<void> setDisplayMode(DataDisplayMode mode) async {
    final updated = state.copyWith(displayMode: mode);
    await updateSettings(updated);
  }

  Future<void> setPin(String pinHash) async {
    final updated = state.copyWith(
      pinHash: pinHash,
      isPinSecurityEnabled: pinHash.isNotEmpty,
    );
    await updateSettings(updated);
  }

  Future<void> toggleBiometrics(bool enabled) async {
    final updated = state.copyWith(isBiometricEnabled: enabled);
    await updateSettings(updated);
  }

  Future<void> completeOnboarding() async {
    final updated = state.copyWith(hasCompletedOnboarding: true);
    await updateSettings(updated);
  }

  Future<void> updateNotificationPref({
    bool? priceAlerts,
    bool? macdSignals,
    bool? sellDateReminders,
    bool? pnlMilestones,
  }) async {
    final updated = state.copyWith(
      notifyPriceAlerts: priceAlerts ?? state.notifyPriceAlerts,
      notifyMacdSignals: macdSignals ?? state.notifyMacdSignals,
      notifySellDateReminders:
          sellDateReminders ?? state.notifySellDateReminders,
      notifyPnlMilestones: pnlMilestones ?? state.notifyPnlMilestones,
    );
    await updateSettings(updated);
  }

  Future<void> reorderDashboardSections(
    List<DashboardSectionConfig> sections,
  ) async {
    final updated = state.copyWith(dashboardSections: sections);
    await updateSettings(updated);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});

// --- Security Lock State (false = locked/pending auth, true = session unlocked) ---
class SecurityLockNotifier extends StateNotifier<bool> {
  SecurityLockNotifier() : super(false);

  void setUnlocked(bool unlocked) {
    state = unlocked;
  }

  void lock() {
    state = false;
  }
}

final appUnlockedProvider = StateNotifierProvider<SecurityLockNotifier, bool>((
  ref,
) {
  return SecurityLockNotifier();
});

final securityLockProvider = appUnlockedProvider;

// --- Trades State & Notifier ---
class TradesNotifier extends StateNotifier<List<TradeRecord>> {
  TradesNotifier() : super([]);

  Future<void> load() async {
    state = await StorageService.loadTrades();
  }

  Future<void> addTrade(TradeRecord trade) async {
    state = [trade, ...state];
    await StorageService.saveTrades(state);
  }

  Future<void> updateTrade(TradeRecord updated) async {
    state = [
      for (final t in state)
        if (t.id == updated.id) updated else t,
    ];
    await StorageService.saveTrades(state);
  }

  Future<void> deleteTrade(String id) async {
    state = state.where((t) => t.id != id).toList();
    await StorageService.saveTrades(state);
  }

  Future<void> markTradeSold(String id) async {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(status: 'SOLD') else t,
    ];
    await StorageService.saveTrades(state);
  }
}

final tradesProvider = StateNotifierProvider<TradesNotifier, List<TradeRecord>>(
  (ref) {
    return TradesNotifier();
  },
);

// --- Calendar Reminders Notifier ---
class RemindersNotifier extends StateNotifier<List<CalendarReminder>> {
  RemindersNotifier() : super([]);

  Future<void> load() async {
    state = await StorageService.loadReminders();
  }

  Future<void> addReminder(CalendarReminder reminder) async {
    state = [reminder, ...state];
    await StorageService.saveReminders(state);
  }

  Future<void> toggleReminderCompleted(String id) async {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(isCompleted: !r.isCompleted) else r,
    ];
    await StorageService.saveReminders(state);
  }

  Future<void> deleteReminder(String id) async {
    state = state.where((r) => r.id != id).toList();
    await StorageService.saveReminders(state);
  }
}

final remindersProvider =
    StateNotifierProvider<RemindersNotifier, List<CalendarReminder>>((ref) {
      return RemindersNotifier();
    });

// --- Watchlist Notifier ---
class WatchlistNotifier extends StateNotifier<List<String>> {
  WatchlistNotifier() : super([]);

  Future<void> load() async {
    state = await StorageService.loadWatchlist();
  }

  Future<void> toggleSymbol(String symbol) async {
    if (state.contains(symbol)) {
      state = state.where((s) => s != symbol).toList();
    } else {
      state = [...state, symbol];
    }
    await StorageService.saveWatchlist(state);
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, List<String>>((ref) {
      return WatchlistNotifier();
    });

final appStartupProvider = FutureProvider<void>((ref) async {
  await ref.read(settingsProvider.notifier).load();
  await Future.wait([
    ref.read(tradesProvider.notifier).load(),
    ref.read(remindersProvider.notifier).load(),
    ref.read(watchlistProvider.notifier).load(),
  ]);
  ref
      .read(themeIndexProvider.notifier)
      .initialize(ref.read(settingsProvider).themeIndex);
});

// --- Portfolio Summary Computed Provider ---
class PortfolioSummary {
  final double totalInvested;
  final double currentValue;
  final double totalPnL;
  final double pnlPercentage;
  final int totalHoldingCount;
  final int targetReachedCount;
  final Map<String, double> sectorBreakdown; // Sector -> value
  final double dailyEstimatedChange;

  const PortfolioSummary({
    required this.totalInvested,
    required this.currentValue,
    required this.totalPnL,
    required this.pnlPercentage,
    required this.totalHoldingCount,
    required this.targetReachedCount,
    required this.sectorBreakdown,
    required this.dailyEstimatedChange,
  });
}

final portfolioSummaryProvider = Provider<PortfolioSummary>((ref) {
  final trades = ref.watch(tradesProvider);
  final activeTrades = trades.where((t) => t.status != 'SOLD').toList();

  double invested = 0;
  double current = 0;
  int targetReached = 0;
  final Map<String, double> sectorMap = {};
  double dailyChange = 0;

  for (final t in activeTrades) {
    invested += t.effectiveCost;
    current += t.currentValue;
    if (t.daysRemainingToTarget <= 0 || t.status == 'TARGET_REACHED') {
      targetReached++;
    }

    sectorMap[t.sector] = (sectorMap[t.sector] ?? 0.0) + t.currentValue;

    // Approximate daily change from company profile
    final company = CompanyRepository.findBySymbol(t.symbol);
    if (company != null) {
      dailyChange += (company.priceChange * t.quantity);
    }
  }

  final pnl = current - invested;
  final pnlPct = invested > 0 ? (pnl / invested) * 100 : 0.0;

  return PortfolioSummary(
    totalInvested: invested,
    currentValue: current,
    totalPnL: pnl,
    pnlPercentage: pnlPct,
    totalHoldingCount: activeTrades.length,
    targetReachedCount: targetReached,
    sectorBreakdown: sectorMap,
    dailyEstimatedChange: dailyChange,
  );
});

// --- Technical Indicator Analysis Provider Family ---
final technicalIndicatorProvider =
    Provider.family<TechnicalIndicatorData, String>((ref, symbol) {
      final company = CompanyRepository.findBySymbol(symbol);
      if (company == null) {
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

      // Generate simulated volume series
      final volumes = List.generate(
        company.recentPrices.length,
        (i) => (company.volume / 20) + (i * 1200),
      );

      return IndicatorCalculatorService.analyzeSymbol(
        symbol: symbol,
        prices: company.recentPrices,
        volumes: volumes,
      );
    });
