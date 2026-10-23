import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trade_record.dart';
import '../providers/app_providers.dart';
import '../services/nepse_fee_calculator_service.dart';
import '../services/storage_service.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/portfolio_value_chart.dart';
import 'trade_logger_view.dart';

enum _PortfolioSort { targetDate, profitLoss, symbol }

class PortfolioView extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const PortfolioView({super.key, this.isEmbedded = false});

  @override
  ConsumerState<PortfolioView> createState() => _PortfolioViewState();
}

class _PortfolioViewState extends ConsumerState<PortfolioView> {
  String _selectedFilter = 'ALL'; // 'ALL', 'HOLDING', 'TARGET_REACHED', 'SOLD'
  String _selectedSector = 'ALL';
  String _searchQuery = '';
  _PortfolioSort _sortOption = _PortfolioSort.targetDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = 'ALL';
      _selectedSector = 'ALL';
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trades = ref.watch(tradesProvider);
    final summary = ref.watch(portfolioSummaryProvider);

    final query = _searchQuery.trim().toLowerCase();
    final filteredTrades =
        trades.where((trade) {
          final matchesStatus =
              _selectedFilter == 'ALL' || trade.status == _selectedFilter;
          final matchesSector =
              _selectedSector == 'ALL' || trade.sector == _selectedSector;
          final matchesSearch =
              query.isEmpty ||
              trade.symbol.toLowerCase().contains(query) ||
              trade.companyName.toLowerCase().contains(query);
          return matchesStatus && matchesSector && matchesSearch;
        }).toList()..sort((a, b) {
          switch (_sortOption) {
            case _PortfolioSort.targetDate:
              return a.targetSellDate.compareTo(b.targetSellDate);
            case _PortfolioSort.profitLoss:
              return b.profitOrLoss.compareTo(a.profitOrLoss);
            case _PortfolioSort.symbol:
              return a.symbol.compareTo(b.symbol);
          }
        });

    final sectors = trades.map((trade) => trade.sector).toSet().toList()
      ..sort();
    sectors.insert(0, 'ALL');

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('My Portfolio'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Log New Trade',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TradeLoggerView(),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: trades.isEmpty
          ? Center(
              child: EmptyStateCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No Trades in Portfolio',
                message: 'Log your first NEPSE stock trade to track PnL, calculate fees, and review holding period estimates.',
                buttonLabel: 'Log First Trade',
                onButtonPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TradeLoggerView()),
                  );
                },
              ),
            )
          : CustomScrollView(
              slivers: [
                if (widget.isEmbedded)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Portfolio',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add, size: 18),
                            tooltip: 'Log New Trade',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TradeLoggerView(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: _buildPortfolioTelemetryCard(summary, theme, trades),
                  ),
                ),
                SliverToBoxAdapter(
                  child: PortfolioValueChart(
                    trades: trades
                        .where((trade) => trade.status != 'SOLD')
                        .toList(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search symbol or company',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () => setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                      }),
                                      icon: const Icon(Icons.close),
                                    ),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<_PortfolioSort>(
                          tooltip: 'Sort positions',
                          initialValue: _sortOption,
                          onSelected: (option) =>
                              setState(() => _sortOption = option),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _PortfolioSort.targetDate,
                              child: Text('Target date'),
                            ),
                            PopupMenuItem(
                              value: _PortfolioSort.profitLoss,
                              child: Text('Highest P&L'),
                            ),
                            PopupMenuItem(
                              value: _PortfolioSort.symbol,
                              child: Text('Symbol A–Z'),
                            ),
                          ],
                          icon: const Icon(Icons.sort),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter Chips
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        _buildStatusChip(
                          'ALL',
                          'All Positions (${trades.length})',
                          theme,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          'HOLDING',
                          'Holding (${trades.where((t) => t.status == 'HOLDING').length})',
                          theme,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          'TARGET_REACHED',
                          'Target Reached (${trades.where((t) => t.status == 'TARGET_REACHED').length})',
                          theme,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          'SOLD',
                          'Sold (${trades.where((t) => t.status == 'SOLD').length})',
                          theme,
                        ),
                      ],
                    ),
                  ),
                ),

                // Sector Filter
                if (sectors.length > 2)
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: sectors.map((s) {
                          final isSelected = _selectedSector == s;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(
                                s,
                                style: const TextStyle(fontSize: 11),
                              ),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _selectedSector = s),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // Trade List
                if (filteredTrades.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 38,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No positions match these filters',
                            style: theme.textTheme.titleSmall,
                          ),
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.filter_alt_off),
                            label: const Text('Clear filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 24, top: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final trade = filteredTrades[index];
                        return _buildTradeCard(trade, theme);
                      }, childCount: filteredTrades.length),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildPortfolioTelemetryCard(
    PortfolioSummary s,
    ThemeData theme,
    List<TradeRecord> trades,
  ) {
    final isBull = s.totalPnL >= 0;
    final pnlColor = isBull ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [theme.cardColor, pnlColor.withAlpha(20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL PORTFOLIO VALUATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: pnlColor.withAlpha(38),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isBull ? '+' : ''}${s.pnlPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: pnlColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs ${s.currentValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${isBull ? '+' : ''}Rs ${s.totalPnL.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: pnlColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildMiniMetric(
                    'Capital invested',
                    'Rs ${s.totalInvested.toStringAsFixed(0)}',
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildMiniMetric(
                    'Active positions',
                    '${s.totalHoldingCount}',
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildMiniMetric(
                    'Targets due / reached',
                    '${s.targetReachedCount}',
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final statement = StorageService.exportPnlStatement(trades);
                await Clipboard.setData(ClipboardData(text: statement));
                HapticFeedback.mediumImpact();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Financial PnL Statement copied to clipboard!',
                      ),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(51),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.share_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Copy Formatted Portfolio Statement',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeCard(TradeRecord t, ThemeData theme) {
    final isBull = t.isProfitable;
    final color = isBull ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    // Holding timeline progress
    final totalWindow = t.predictedHoldingDays > 0
        ? t.predictedHoldingDays
        : 30;
    final daysElapsed = t.daysHeld.clamp(0, totalWindow);
    final progress = (daysElapsed / totalWindow).clamp(0.0, 1.0);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTradeDetailsModal(t, theme),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Symbol, Name, Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(38),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.symbol,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${t.quantity} Kitta @ Rs ${t.pricePerShare}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _buildTradeStatusBadge(t.status),
                ],
              ),
              const SizedBox(height: 8),

              // PnL & Current Val
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last price: Rs ${t.currentLtp ?? t.pricePerShare}',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                      Text(
                        'Rs ${t.currentValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Unrealized PnL',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                      Text(
                        '${isBull ? '+' : ''}Rs ${t.profitOrLoss.toStringAsFixed(2)} (${t.profitOrLossPercentage.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ML Holding Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Planned hold: ${t.daysHeld} / ${t.predictedHoldingDays} days',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                  Text(
                    t.daysRemainingToTarget <= 0
                        ? 'Target Date Reached!'
                        : '${t.daysRemainingToTarget} days to target',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: t.daysRemainingToTarget <= 0
                          ? const Color(0xFFEF4444)
                          : theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.onSurface.withAlpha(26),
                  color: progress >= 1.0
                      ? const Color(0xFFEF4444)
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Entry: ${t.bsDate}',
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withAlpha(128),
                    ),
                  ),
                  Text(
                    'Target Exit: ${t.targetSellDateBS}',
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTradeDetailsModal(TradeRecord t, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${t.symbol} Trade Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              _buildDetailItem('Company', t.companyName),
              _buildDetailItem('Sector', t.sector),
              _buildDetailItem('Transaction Type', t.transactionType),
              _buildDetailItem(
                'Bought On (BS / AD)',
                '${t.bsDate} (${t.transactionDate.toIso8601String().split("T")[0]})',
              ),
              _buildDetailItem(
                'Target Sell Date',
                '${t.targetSellDateBS} (${t.targetSellDate.toIso8601String().split("T")[0]})',
              ),
              _buildDetailItem('Quantity', '${t.quantity} Kitta'),
              _buildDetailItem('Purchase Price', 'Rs ${t.pricePerShare}'),
              _buildDetailItem(
                'Gross Amount',
                'Rs ${t.totalAmount.toStringAsFixed(2)}',
              ),
              _buildDetailItem(
                'Broker Commission',
                'Rs ${t.brokerCommission.toStringAsFixed(2)}',
              ),
              _buildDetailItem(
                'SEBON + DP Fee',
                'Rs ${(t.sebonFee + t.dpCharge).toStringAsFixed(2)}',
              ),
              _buildDetailItem(
                'Total Effective Cost',
                'Rs ${t.effectiveCost.toStringAsFixed(2)}',
              ),
              _buildDetailItem(
                'Current Market Value',
                'Rs ${t.currentValue.toStringAsFixed(2)}',
              ),
              _buildDetailItem(
                'Net PnL',
                'Rs ${t.profitOrLoss.toStringAsFixed(2)} (${t.profitOrLossPercentage.toStringAsFixed(2)}%)',
              ),
              if (t.receiptImagePath != null) ...[
                const SizedBox(height: 10),
                const Text(
                  'Attached Trade Receipt:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(t.receiptImagePath!),
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Text('Image file not found'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (t.status != 'SOLD') ...[
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showExitSimulator(t, theme);
                  },
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Simulate Exit & Tax Breakdown'),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(tradesProvider.notifier).deleteTrade(t.id);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (t.status != 'SOLD')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          // Quick Sell with CGT
                          final sellRes =
                              NepseFeeCalculatorService.calculateSell(
                                quantity: t.quantity,
                                sellPrice: t.currentLtp ?? t.pricePerShare,
                                originalPurchaseCost: t.effectiveCost,
                                holdingDays: t.daysHeld,
                              );
                          ref.read(tradesProvider.notifier).markTradeSold(t.id);
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Marked as SOLD! CGT: Rs ${sellRes.capitalGainsTax.toStringAsFixed(2)} | Net Profit: Rs ${sellRes.profitOrLoss.toStringAsFixed(2)}',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        },
                        icon: const Icon(Icons.sell_outlined),
                        label: const Text('Mark Sold'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String filter, String label, ThemeData theme) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha(38),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (theme.brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white)
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildTradeStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'TARGET_REACHED':
        bg = const Color(0xFFEF4444).withAlpha(38);
        fg = const Color(0xFFEF4444);
        label = 'TARGET REACHED';
        break;
      case 'SOLD':
        bg = Colors.grey.withAlpha(38);
        fg = Colors.grey;
        label = 'CLOSED';
        break;
      case 'HOLDING':
      default:
        bg = const Color(0xFF10B981).withAlpha(38);
        fg = const Color(0xFF10B981);
        label = 'HOLDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showExitSimulator(TradeRecord t, ThemeData theme) {
    double simPrice = t.currentLtp ?? t.pricePerShare;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final simResult = NepseFeeCalculatorService.calculateSell(
              quantity: t.quantity,
              sellPrice: simPrice,
              originalPurchaseCost: t.effectiveCost,
              holdingDays: t.daysHeld,
            );
            final isProfitable = simResult.profitOrLoss >= 0;
            final pnlColor = isProfitable
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444);

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${t.symbol} Exit Profit Simulator',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    'Simulated Target Exit Price: Rs ${simPrice.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Slider(
                    value: simPrice,
                    min: (t.pricePerShare * 0.70).clamp(10.0, double.infinity),
                    max: t.pricePerShare * 1.60,
                    divisions: 90,
                    label: 'Rs ${simPrice.toStringAsFixed(1)}',
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setModalState(() => simPrice = (val * 10).round() / 10.0);
                    },
                  ),
                  _buildDetailItem(
                    'Gross Exit Value',
                    'Rs ${simResult.grossAmount.toStringAsFixed(2)}',
                  ),
                  _buildDetailItem(
                    'Broker Commission',
                    'Rs ${simResult.brokerCommission.toStringAsFixed(2)}',
                  ),
                  _buildDetailItem(
                    'SEBON + DP Charge',
                    'Rs ${(simResult.sebonFee + simResult.dpFee).toStringAsFixed(2)}',
                  ),
                  _buildDetailItem(
                    t.daysHeld >= 365
                        ? 'CGT (5.0% Long Term)'
                        : 'CGT (7.5% Short Term)',
                    'Rs ${simResult.capitalGainsTax.toStringAsFixed(2)}',
                  ),
                  _buildDetailItem(
                    'Net Cash Receivable',
                    'Rs ${simResult.netReceivable.toStringAsFixed(2)}',
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Projected PnL:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${isProfitable ? "+" : ""}Rs ${simResult.profitOrLoss.toStringAsFixed(2)} (${isProfitable ? "+" : ""}${simResult.profitPercentage.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: pnlColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(tradesProvider.notifier).markTradeSold(t.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sold ${t.quantity} kitta of ${t.symbol} @ Rs $simPrice! Net Profit: Rs ${simResult.profitOrLoss.toStringAsFixed(2)}',
                          ),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text('Execute Sale @ Rs $simPrice'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
