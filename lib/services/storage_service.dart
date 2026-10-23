import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/trade_record.dart';

class StorageService {
  static const String _settingsKey = 'nepse_settings_v1';
  static const String _tradesKey = 'nepse_trades_v1';
  static const String _watchlistKey = 'nepse_watchlist_v1';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<AppSettings> loadSettings() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_settingsKey);
      if (raw == null || raw.isEmpty) {
        return const AppSettings();
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const AppSettings();
      }
      return AppSettings.fromJson(decoded);
    } catch (_) {
      return const AppSettings();
    }
  }

  static Future<bool> saveSettings(AppSettings settings) async {
    final prefs = await _getPrefs();
    return prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  static Future<List<TradeRecord>> loadTrades() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_tradesKey);
      if (raw == null || raw.isEmpty) {
        return _seedTrades();
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return _seedTrades();
      }
      return decoded
          .map((e) => TradeRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return _seedTrades();
    }
  }

  static Future<bool> saveTrades(List<TradeRecord> trades) async {
    final prefs = await _getPrefs();
    return prefs.setString(
      _tradesKey,
      jsonEncode(trades.map((trade) => trade.toJson()).toList()),
    );
  }

  static Future<List<String>> loadWatchlist() async {
    try {
      final prefs = await _getPrefs();
      final values = prefs.getStringList(_watchlistKey);
      if (values == null || values.isEmpty) {
        return ['NABIL', 'NICA', 'NLIC', 'SHIVM', 'NTC'];
      }
      return values;
    } catch (_) {
      return ['NABIL', 'NICA', 'NLIC', 'SHIVM', 'NTC'];
    }
  }

  static Future<bool> saveWatchlist(List<String> watchlist) async {
    final prefs = await _getPrefs();
    return prefs.setStringList(_watchlistKey, watchlist);
  }

  static List<TradeRecord> _seedTrades() {
    final now = DateTime.now();
    return [
      TradeRecord(
        id: 't1',
        symbol: 'NABIL',
        companyName: 'Nabil Bank',
        transactionType: 'BUY',
        transactionDate: now.subtract(const Duration(days: 60)),
        quantity: 100,
        pricePerShare: 630,
        sector: 'Banking',
        currentPrice: 670,
        targetPrice: 720,
        predictedHoldingDays: 75,
        status: 'ACTIVE',
      ),
      TradeRecord(
        id: 't2',
        symbol: 'SHIVM',
        companyName: 'Shivam Cements',
        transactionType: 'BUY',
        transactionDate: now.subtract(const Duration(days: 40)),
        quantity: 200,
        pricePerShare: 220,
        sector: 'Manufacturing',
        currentPrice: 245,
        targetPrice: 260,
        predictedHoldingDays: 60,
        status: 'ACTIVE',
      ),
      TradeRecord(
        id: 't3',
        symbol: 'NTC',
        companyName: 'Nepal Telecom',
        transactionType: 'BUY',
        transactionDate: now.subtract(const Duration(days: 20)),
        quantity: 150,
        pricePerShare: 260,
        sector: 'Telecom',
        currentPrice: 275,
        targetPrice: 290,
        predictedHoldingDays: 45,
        status: 'ACTIVE',
      ),
    ];
  }
}
