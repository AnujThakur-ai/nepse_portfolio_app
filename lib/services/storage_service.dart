import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/calendar_reminder.dart';
import '../models/trade_record.dart';

class StorageService {
  static const String _tradesKey = 'nepse_trades_v1';
  static const String _remindersKey = 'nepse_reminders_v1';
  static const String _settingsKey = 'nepse_settings_v1';
  static const String _watchlistKey = 'nepse_watchlist_v1';
  static const String _receiptsKey = 'nepse_receipts_v1';

  // In-memory caches
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Loads trades, using an empty list when data is missing or malformed.
  static Future<List<TradeRecord>> loadTrades() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_tradesKey);
      if (raw == null || raw.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => TradeRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Graceful recovery keeps malformed saved data from crashing startup.
      return [];
    }
  }

  /// Saves trades list to disk
  static Future<bool> saveTrades(List<TradeRecord> trades) async {
    final prefs = await _getPrefs();
    final jsonList = trades.map((t) => t.toJson()).toList();
    return await prefs.setString(_tradesKey, jsonEncode(jsonList));
  }

  /// Loads calendar reminders
  static Future<List<CalendarReminder>> loadReminders() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_remindersKey);
      if (raw == null || raw.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => CalendarReminder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Saves reminders
  static Future<bool> saveReminders(List<CalendarReminder> reminders) async {
    final prefs = await _getPrefs();
    final jsonList = reminders.map((r) => r.toJson()).toList();
    return await prefs.setString(_remindersKey, jsonEncode(jsonList));
  }

  /// Loads app settings
  static Future<AppSettings> loadSettings() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_settingsKey);
      if (raw == null || raw.isEmpty) return const AppSettings();

      final Map<String, dynamic> decoded = jsonDecode(raw);
      return AppSettings.fromJson(decoded);
    } catch (e) {
      return const AppSettings();
    }
  }

  /// Saves app settings
  static Future<bool> saveSettings(AppSettings settings) async {
    final prefs = await _getPrefs();
    return await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  /// Loads watchlist symbols
  static Future<List<String>> loadWatchlist() async {
    try {
      final prefs = await _getPrefs();
      final list = prefs.getStringList(_watchlistKey);
      return (list ?? [])
          .where((symbol) => symbol.trim().isNotEmpty)
          .toSet()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Saves watchlist symbols
  static Future<bool> saveWatchlist(List<String> watchlist) async {
    final prefs = await _getPrefs();
    return await prefs.setStringList(_watchlistKey, watchlist);
  }

  /// Loads document receipts
  static Future<List<Map<String, String>>> loadReceipts() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_receiptsKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Saves receipts
  static Future<bool> saveReceipts(List<Map<String, String>> receipts) async {
    final prefs = await _getPrefs();
    return await prefs.setString(_receiptsKey, jsonEncode(receipts));
  }

  /// Generates CSV report of all trades
  static String exportTradesCsv(List<TradeRecord> trades) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Symbol,Company,Type,Date(AD),Date(BS),Quantity,BuyPrice,TotalAmount,EffectiveCost,TargetSellDate(AD),TargetSellDate(BS),Status,HoldingDays',
    );

    for (final t in trades) {
      buffer.writeln(
        '${t.id},${t.symbol},"${t.companyName}",${t.transactionType},${t.transactionDate.toIso8601String().split("T")[0]},${t.bsDate},${t.quantity},${t.pricePerShare},${t.totalAmount},${t.effectiveCost},${t.targetSellDate.toIso8601String().split("T")[0]},${t.targetSellDateBS},${t.status},${t.predictedHoldingDays}',
      );
    }

    return buffer.toString();
  }

  /// Generates a formatted text statement for PnL
  static String exportPnlStatement(List<TradeRecord> trades) {
    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('       NEPSE TRADING & PORTFOLIO STATEMENT           ');
    buffer.writeln(
      '           Generated on ${DateTime.now().toIso8601String().split("T")[0]}          ',
    );
    buffer.writeln('====================================================\n');

    double totalInvested = 0;
    double totalCurrent = 0;
    double totalPnL = 0;

    for (final t in trades) {
      totalInvested += t.effectiveCost;
      totalCurrent += t.currentValue;
      totalPnL += t.profitOrLoss;

      buffer.writeln('Symbol: ${t.symbol} (${t.companyName})');
      buffer.writeln('Sector: ${t.sector}');
      buffer.writeln(
        'Quantity: ${t.quantity} | Buy Price: Rs ${t.pricePerShare}',
      );
      buffer.writeln(
        'Total Buy Cost (w/ fees): Rs ${t.effectiveCost.toStringAsFixed(2)}',
      );
      buffer.writeln('Target Sell Date (BS): ${t.targetSellDateBS}');
      buffer.writeln('ML Optimal Hold: ${t.predictedHoldingDays} days');
      buffer.writeln(
        'Current PnL: Rs ${t.profitOrLoss.toStringAsFixed(2)} (${t.profitOrLossPercentage.toStringAsFixed(2)}%)',
      );
      buffer.writeln('----------------------------------------------------');
    }

    buffer.writeln('\nPORTFOLIO TOTALS:');
    buffer.writeln(
      'Total Capital Invested: Rs ${totalInvested.toStringAsFixed(2)}',
    );
    buffer.writeln(
      'Total Current Portfolio Value: Rs ${totalCurrent.toStringAsFixed(2)}',
    );
    buffer.writeln('Net Overall PnL: Rs ${totalPnL.toStringAsFixed(2)}');
    buffer.writeln('====================================================');

    return buffer.toString();
  }

  /// Encrypted JSON full database backup export
  static Future<String> exportFullJsonBackup() async {
    final trades = await loadTrades();
    final reminders = await loadReminders();
    final settings = await loadSettings();
    final watchlist = await loadWatchlist();
    final receipts = await loadReceipts();

    final backup = {
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'trades': trades.map((t) => t.toJson()).toList(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
      'settings': settings.toJson(),
      'watchlist': watchlist,
      'receipts': receipts,
    };

    final rawJson = jsonEncode(backup);
    // Base64 encode for portability
    return base64Encode(utf8.encode(rawJson));
  }

  /// Restores database from full JSON backup
  static Future<bool> restoreFullJsonBackup(String backupString) async {
    try {
      final decodedJson = utf8.decode(base64Decode(backupString.trim()));
      final Map<String, dynamic> data = jsonDecode(decodedJson);

      if (data.containsKey('trades')) {
        final List<dynamic> tList = data['trades'];
        final trades = tList
            .map((e) => TradeRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveTrades(trades);
      }

      if (data.containsKey('reminders')) {
        final List<dynamic> rList = data['reminders'];
        final reminders = rList
            .map((e) => CalendarReminder.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveReminders(reminders);
      }

      if (data.containsKey('settings')) {
        final settings = AppSettings.fromJson(
          data['settings'] as Map<String, dynamic>,
        );
        await saveSettings(settings);
      }

      if (data.containsKey('watchlist')) {
        final List<dynamic> wList = data['watchlist'];
        await saveWatchlist(wList.map((e) => e.toString()).toList());
      }

      if (data.containsKey('receipts')) {
        final List<dynamic> rList = data['receipts'];
        final receipts = rList
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
        await saveReceipts(receipts);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
