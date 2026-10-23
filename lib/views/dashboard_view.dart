import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trade_record.dart';
import '../providers/app_providers.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioSummaryProvider);
    final trades = ref.watch(tradesProvider);
    final watchlist = ref.watch(watchlistProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NEPSE Portfolio'),
        actions: [
          IconButton(
            onPressed: () {
              final current = ref.read(settingsProvider);
              ref.read(settingsProvider.notifier).updateSettings(
                current.copyWith(
                  isPinSecurityEnabled: !current.isPinSecurityEnabled,
                ),
              );
            },
            icon: const Icon(Icons.security),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context, portfolio),
              const SizedBox(height: 16),
              _buildStatRow(context, portfolio),
              const SizedBox(height: 16),
              _buildSectionTitle('Watchlist'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final symbol in watchlist)
                    Chip(
                      label: Text(symbol),
                      avatar: const Icon(Icons.trending_up, size: 16),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Recent Holdings'),
              const SizedBox(height: 8),
              ...[
                for (final trade in trades) _buildTradeTile(context, trade),
              ],
              const SizedBox(height: 16),
              _buildSectionTitle('Settings Snapshot'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _textRow('Theme', settings.themeIndex.toString()),
                      _textRow('Display', settings.displayMode.name),
                      _textRow('PIN security', settings.isPinSecurityEnabled ? 'On' : 'Off'),
                      _textRow('Biometric', settings.isBiometricEnabled ? 'On' : 'Off'),
                      _textRow('Onboarding', settings.hasCompletedOnboarding ? 'Complete' : 'Pending'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final now = DateTime.now();
          ref.read(tradesProvider.notifier).addTrade(
            TradeRecord(
              id: 'trade_${now.millisecondsSinceEpoch}',
              symbol: 'NICA',
              companyName: 'Nepal Credit and Commerce Bank',
              transactionType: 'BUY',
              transactionDate: now,
              quantity: 50,
              pricePerShare: 430,
              sector: 'Banking',
              currentPrice: 440,
              targetPrice: 470,
              predictedHoldingDays: 55,
              status: 'ACTIVE',
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Map<String, dynamic> portfolio) {
    final theme = Theme.of(context);
    final pnl = portfolio['pnl'] as double;
    final positive = pnl >= 0;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio value',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'NPR ${((portfolio['currentValue'] as num).toDouble()).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${positive ? '+' : ''}${pnl.toStringAsFixed(2)} (${portfolio['pnlPercentage'].toStringAsFixed(2)}%)',
              style: TextStyle(
                color: positive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, Map<String, dynamic> portfolio) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            context,
            'Invested',
            'NPR ${((portfolio['invested'] as num).toDouble()).toStringAsFixed(2)}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            context,
            'Trades',
            portfolio['count'].toString(),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha(180),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }

  Widget _buildTradeTile(BuildContext context, dynamic trade) {
    final item = trade as TradeRecord;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(item.symbol.substring(0, item.symbol.length > 3 ? 3 : item.symbol.length)),
        ),
        title: Text(item.symbol),
        subtitle: Text('${item.companyName} • ${item.quantity} shares'),
        trailing: Text(
          'NPR ${item.currentValue.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _textRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
