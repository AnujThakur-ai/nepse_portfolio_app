import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/trade_record.dart';
import '../services/storage_service.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  Future<void> load() async {
    final settings = await StorageService.loadSettings();
    state = settings;
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    await StorageService.saveSettings(newSettings);
  }

  Future<void> completeOnboarding() async {
    final updated = state.copyWith(hasCompletedOnboarding: true);
    await updateSettings(updated);
  }

  Future<void> updateNotificationPreferences({
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

  Future<void> setPin(String pinHash) async {
    final updated = state.copyWith(
      pinHash: pinHash,
      isPinSecurityEnabled: pinHash.isNotEmpty,
    );
    await updateSettings(updated);
  }

  Future<void> setBiometricAuth(bool enabled) async {
    final updated = state.copyWith(isBiometricEnabled: enabled);
    await updateSettings(updated);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class TradesNotifier extends Notifier<List<TradeRecord>> {
  @override
  List<TradeRecord> build() => const [];

  Future<void> load() async {
    state = await StorageService.loadTrades();
  }

  Future<void> addTrade(TradeRecord trade) async {
    final updated = [trade, ...state];
    state = updated;
    await StorageService.saveTrades(updated);
  }

  Future<void> updateTrade(TradeRecord trade) async {
    final updated = state
        .map((item) => item.id == trade.id ? trade : item)
        .toList();
    state = updated;
    await StorageService.saveTrades(updated);
  }

  Future<void> deleteTrade(String id) async {
    final updated = state.where((item) => item.id != id).toList();
    state = updated;
    await StorageService.saveTrades(updated);
  }
}

final tradesProvider = NotifierProvider<TradesNotifier, List<TradeRecord>>(
  TradesNotifier.new,
);

class WatchlistNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  Future<void> load() async {
    state = await StorageService.loadWatchlist();
  }

  Future<void> toggleSymbol(String symbol) async {
    final updated = state.contains(symbol)
        ? state.where((item) => item != symbol).toList()
        : [...state, symbol];
    state = updated;
    await StorageService.saveWatchlist(updated);
  }
}

final watchlistProvider = NotifierProvider<WatchlistNotifier, List<String>>(
  WatchlistNotifier.new,
);

class SecurityLockNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setLocked(bool locked) {
    state = locked;
  }
}

final securityLockProvider = NotifierProvider<SecurityLockNotifier, bool>(
  SecurityLockNotifier.new,
);

final appStartupProvider = FutureProvider<bool>((ref) async {
  await ref.read(settingsProvider.notifier).load();
  await ref.read(tradesProvider.notifier).load();
  await ref.read(watchlistProvider.notifier).load();
  return true;
});

final portfolioSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final trades = ref.watch(tradesProvider);

  double invested = 0;
  double currentValue = 0;

  for (final trade in trades) {
    invested += trade.totalInvestment;
    currentValue += trade.currentValue;
  }

  final pnl = currentValue - invested;
  final percentage = invested == 0 ? 0.0 : (pnl / invested) * 100;

  return {
    'invested': invested,
    'currentValue': currentValue,
    'pnl': pnl,
    'pnlPercentage': percentage,
    'count': trades.length,
  };
});
