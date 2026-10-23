import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../providers/app_providers.dart';
import '../services/bikram_sambat_service.dart';
import '../services/company_repository.dart';
import '../widgets/analog_gauge_widget.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/home_widget_preview.dart';
import '../widgets/shortcut_ribbon_widget.dart';
import '../widgets/technical_chart_widget.dart';
import 'company_search_view.dart';
import 'document_vault_view.dart';
import 'dual_calendar_view.dart';
import 'nepse_calculator_view.dart';
import 'portfolio_view.dart';
import 'settings_view.dart';
import 'technical_analysis_view.dart';
import 'trade_logger_view.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Bottom Navigation destinations
    final pages = [
      _buildCockpitDashboard(theme),
      const PortfolioView(isEmbedded: true),
      const TechnicalAnalysisView(isEmbedded: true),
      const DualCalendarView(isEmbedded: true),
      _buildToolsAndVaultMenu(theme),
    ];

    return Scaffold(
      appBar: CustomAppBar(
        onSearchTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CompanySearchView()),
          );
        },
        onThemeTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsView()),
          );
        },
      ),
      body: IndexedStack(index: _currentTabIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentTabIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Cockpit',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            selectedIcon: Icon(Icons.candlestick_chart),
            label: 'Radar',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'AD/BS',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared),
            label: 'Vault',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TradeLoggerView()),
          );
        },
        tooltip: 'Quick Trade Entry',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  Widget _buildCockpitDashboard(ThemeData theme) {
    final summary = ref.watch(portfolioSummaryProvider);
    final settings = ref.watch(settingsProvider);
    final trades = ref.watch(tradesProvider);
    final reminders = ref.watch(remindersProvider);
    final watchlist = ref.watch(watchlistProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh simulation
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // 1. Portfolio Telemetry Digital Cards
            _buildTelemetryGrid(summary, theme),
            const SizedBox(height: 12),

            // 2. Action Ribbon
            _buildShortcutRibbon(theme),
            const SizedBox(height: 12),

            // 3. Live NEPSE Market Indices Banner
            _buildNepseMarketIndicesCard(theme),
            const SizedBox(height: 12),

            // 4. Target sell deadlines from saved trades.
            _buildHoldingTargetsSection(trades, theme),
            const SizedBox(height: 12),

            // 5. Data Display Mode: Telemetry vs fl_chart vs Analog Gauge
            _buildDisplayModeSection(settings, theme),
            const SizedBox(height: 12),

            // 6. Active Watchlist & Quick Scan
            _buildWatchlistSection(watchlist, theme),
            const SizedBox(height: 12),

            // 7. Sector Allocation Breakdown
            if (summary.sectorBreakdown.isNotEmpty)
              _buildSectorBreakdownCard(summary, theme),
            const SizedBox(height: 12),

            // 8. Multi-Size Home Screen Widget Simulator
            HomeWidgetPreview(
              summary: summary,
              watchlist: watchlist,
              reminders: reminders,
            ),
          ],
        ),
      ),
    );
  }

  // Telemetry Grid
  Widget _buildTelemetryGrid(PortfolioSummary s, ThemeData theme) {
    final isBull = s.totalPnL >= 0;
    final pnlColor = isBull ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PORTFOLIO TELEMETRY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs ${s.currentValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Invested Capital: Rs ${s.totalInvested.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isBull ? '+' : ''}Rs ${s.totalPnL.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: pnlColor,
                      ),
                    ),
                    Text(
                      isBull ? 'Unrealized Gain' : 'Unrealized Loss',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Shortcut Ribbon
  Widget _buildShortcutRibbon(ThemeData theme) {
    return ShortcutRibbonWidget(
      actions: [
        ShortcutActionItem(
          id: 'quick_buy',
          label: 'Log Buy',
          icon: Icons.add_shopping_cart,
          color: const Color(0xFF10B981),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TradeLoggerView()),
            );
          },
        ),
        ShortcutActionItem(
          id: 'macd_scan',
          label: 'MACD Radar',
          icon: Icons.radar,
          color: const Color(0xFF3B82F6),
          onTap: () {
            setState(() => _currentTabIndex = 2);
          },
        ),
        ShortcutActionItem(
          id: 'target_dates',
          label: 'Target Dates',
          icon: Icons.timer,
          color: const Color(0xFFF59E0B),
          onTap: () {
            setState(() => _currentTabIndex = 3);
          },
        ),
        ShortcutActionItem(
          id: 'nepse_calc',
          label: 'Tax & Fee Calc',
          icon: Icons.calculate_outlined,
          color: const Color(0xFFA855F7),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NepseCalculatorView()),
            );
          },
        ),
        ShortcutActionItem(
          id: 'doc_vault',
          label: 'Trade Vault',
          icon: Icons.receipt_long,
          color: const Color(0xFF06B6D4),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentVaultView()),
            );
          },
        ),
        ShortcutActionItem(
          id: 'settings',
          label: 'Settings',
          icon: Icons.settings_outlined,
          color: theme.colorScheme.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsView()),
            );
          },
        ),
      ],
    );
  }

  // Live NEPSE Market Indices
  Widget _buildNepseMarketIndicesCard(ThemeData theme) {
    final status = BikramSambatService.getNepseMarketStatus();
    final isOpen = BikramSambatService.isNepseOpen();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'NEPSE MARKET STATUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  isOpen ? 'LIVE SESSION' : 'CLOSED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOpen
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              'Live index and turnover data are not connected. Market hours below use the device clock.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(179),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withAlpha(153),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ML Target Sell Deadlines
  Widget _buildHoldingTargetsSection(List<dynamic> trades, ThemeData theme) {
    final activeTrades = trades
        .where((t) => t.status != 'SOLD')
        .take(3)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'HOLDING TARGET DATES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _currentTabIndex = 1),
                  child: const Text('View All', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const Divider(height: 12),
            if (activeTrades.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No active holdings. Log a trade to generate ML target sell dates.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              )
            else
              ...activeTrades.map((t) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(38),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t.symbol,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target: ${t.targetSellDateBS}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        t.daysRemainingToTarget <= 0
                            ? 'Target Reached!'
                            : '${t.daysRemainingToTarget} days left',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: t.daysRemainingToTarget <= 0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // Display Mode Section: Telemetry vs fl_chart vs Analog Speedometer Gauge
  Widget _buildDisplayModeSection(AppSettings settings, ThemeData theme) {
    const demoSymbol = 'NABIL';
    final company = CompanyRepository.findBySymbol(demoSymbol)!;
    final indicators = ref.watch(technicalIndicatorProvider(demoSymbol));

    switch (settings.displayMode) {
      case DataDisplayMode.interactiveCharts:
        return TechnicalChartWidget(
          prices: company.recentPrices,
          sma20: List.filled(company.recentPrices.length, indicators.sma20),
          symbol: company.symbol,
          currentPrice: company.ltp,
          change: company.priceChange,
          percentageChange: company.percentageChange,
        );

      case DataDisplayMode.analogGauges:
        return AnalogGaugeWidget(
          value: indicators.sentimentScore,
          title: '$demoSymbol ANALOG SENTIMENT RADAR',
          subtitle: 'RSI / MACD / Volume Speedometer (0-100)',
        );

      case DataDisplayMode.telemetryCards:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$demoSymbol TECHNICAL TELEMETRY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'LTP: Rs ${company.ltp}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniTelemetryItem(
                      'RSI (14)',
                      indicators.rsi.toStringAsFixed(1),
                      theme,
                    ),
                    _buildMiniTelemetryItem(
                      'MACD Hist',
                      indicators.histogram.toStringAsFixed(2),
                      theme,
                      isBull: indicators.histogram > 0,
                    ),
                    _buildMiniTelemetryItem(
                      '20-SMA',
                      indicators.sma20.toStringAsFixed(1),
                      theme,
                    ),
                    _buildMiniTelemetryItem(
                      'Sentiment',
                      '${indicators.sentimentScore.toStringAsFixed(0)} / 100',
                      theme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildMiniTelemetryItem(
    String label,
    String value,
    ThemeData theme, {
    bool? isBull,
  }) {
    Color? col;
    if (isBull == true) col = const Color(0xFF10B981);
    if (isBull == false) col = const Color(0xFFEF4444);

    return Column(
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: col ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // Watchlist Section
  Widget _buildWatchlistSection(List<String> watchlist, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'QUICK WATCHLIST & SIGNALS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Search & Add Symbol',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompanySearchView(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 12),
            ...watchlist.take(4).map((symbol) {
              final comp = CompanyRepository.findBySymbol(symbol);
              if (comp == null) return const SizedBox();
              final isBull = comp.isBullish;
              final col = isBull
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          comp.symbol,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          comp.sector,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withAlpha(128),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Rs ${comp.ltp.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isBull ? '+' : ''}${comp.percentageChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: col,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Sector Breakdown
  Widget _buildSectorBreakdownCard(PortfolioSummary s, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'SECTOR ALLOCATION BREAKDOWN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...s.sectorBreakdown.entries.map((e) {
              final pct = s.currentValue > 0
                  ? (e.value / s.currentValue) * 100
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs ${e.value.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (pct / 100.0).clamp(0.0, 1.0),
                        minHeight: 4,
                        color: theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.onSurface.withAlpha(
                          26,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Tools & Vault Menu Tab
  Widget _buildToolsAndVaultMenu(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Trade Receipt & Document Vault',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Attach TMS bills, contract notes, and analysis charts offline',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DocumentVaultView(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calculate, color: Color(0xFF10B981)),
                ),
                title: const Text(
                  'NEPSE Tax & Broker Fee Calculator',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Calculate Broker Slabs, SEBON Fee, DP, and CGT brackets',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NepseCalculatorView(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings, color: Color(0xFFF59E0B)),
                ),
                title: const Text(
                  'Settings & 10-Theme Studio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Theme palettes, PIN security, notifications, and JSON backups',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsView()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
