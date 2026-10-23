import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nepse_portfolio_app/models/app_settings.dart';
import 'package:nepse_portfolio_app/models/trade_record.dart';
import 'package:nepse_portfolio_app/providers/app_providers.dart';
import 'package:nepse_portfolio_app/services/security_service.dart';
import 'package:nepse_portfolio_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('PIN verification rejects empty and incorrect values', () {
    final hash = SecurityService.hashPin('1234');
    expect(SecurityService.verifyPin('1234', hash), isTrue);
    expect(SecurityService.verifyPin('0000', hash), isFalse);
    expect(SecurityService.verifyPin('', hash), isFalse);
    expect(SecurityService.verifyPin('1234', ''), isFalse);
  });

  test('settings load tolerates invalid enum values', () {
    final settings = AppSettings.fromJson({
      'displayMode': 999,
      'themeIndex': -4,
    });
    expect(settings.displayMode, DataDisplayMode.telemetryCards);
    expect(settings.themeIndex, 0);
  });

  test('onboarding completion is persisted and restored', () async {
    final notifier = SettingsNotifier();
    await notifier.completeOnboarding();
    expect(notifier.state.hasCompletedOnboarding, isTrue);
    expect(
      (await StorageService.loadSettings()).hasCompletedOnboarding,
      isTrue,
    );
  });

  test('lock state only unlocks after explicit state update', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(appUnlockedProvider), isFalse);
    container.read(appUnlockedProvider.notifier).setUnlocked(true);
    expect(container.read(appUnlockedProvider), isTrue);
    container.read(appUnlockedProvider.notifier).lock();
    expect(container.read(appUnlockedProvider), isFalse);
  });

  test('portfolio summary calculates invested value and PnL', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final trade = TradeRecord(
      id: 'test-1',
      symbol: 'NABIL',
      companyName: 'Nabil Bank',
      sector: 'Banking',
      transactionType: 'BUY',
      transactionDate: DateTime(2026, 1, 1),
      bsDate: '',
      quantity: 10,
      pricePerShare: 100,
      totalAmount: 1000,
      brokerCommission: 0,
      sebonFee: 0,
      dpCharge: 0,
      effectiveCost: 1000,
      targetSellDate: DateTime(2026, 2, 1),
      targetSellDateBS: '',
      predictedHoldingDays: 30,
      currentLtp: 120,
    );
    await container.read(tradesProvider.notifier).addTrade(trade);
    final summary = container.read(portfolioSummaryProvider);
    expect(summary.totalInvested, 1000);
    expect(summary.currentValue, 1200);
    expect(summary.totalPnL, 200);
    expect(summary.pnlPercentage, 20);
    expect(summary.totalHoldingCount, 1);
  });
}
