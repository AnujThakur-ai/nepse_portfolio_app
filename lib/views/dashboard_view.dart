import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_reminder.dart';
import '../models/app_settings.dart';
import '../models/trade_record.dart';
import '../providers/app_providers.dart';
import '../services/bikram_sambat_service.dart';
import '../services/company_repository.dart';
import '../widgets/analog_gauge_widget.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/glass_panel.dart';
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
  static const _tabSlideDuration = Duration(milliseconds: 340);
  static const _tabFadeDuration = Duration(milliseconds: 240);

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
      body: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: List.generate(pages.length, (index) {
            final isSelected = index == _currentTabIndex;
            final hiddenOffset = index < _currentTabIndex ? -0.035 : 0.035;
            return Positioned.fill(
              child: IgnorePointer(
                ignoring: !isSelected,
                child: AnimatedOpacity(
                  opacity: isSelected ? 1 : 0,
                  duration: _tabFadeDuration,
                  curve: Curves.easeOut,
                  child: AnimatedSlide(
                    offset: isSelected ? Offset.zero : Offset(hiddenOffset, 0),
                    duration: _tabSlideDuration,
                    curve: Curves.easeInOutCubic,
                    child: TickerMode(enabled: isSelected, child: pages[index]),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 58,
                color: theme.colorScheme.surface.withAlpha(185),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Row(
                  children: [
                    _buildNavItem(
                      theme,
                      0,
                      Icons.home_outlined,
                      Icons.home_rounded,
                      'Home',
                    ),
                    _buildNavItem(
                      theme,
                      1,
                      Icons.account_balance_wallet_outlined,
                      Icons.account_balance_wallet,
                      'Portfolio',
                    ),
                    _buildNavItem(
                      theme,
                      2,
                      Icons.candlestick_chart_outlined,
                      Icons.candlestick_chart,
                      'Markets',
                    ),
                    _buildNavItem(
                      theme,
                      3,
                      Icons.calendar_month_outlined,
                      Icons.calendar_month,
                      'Calendar',
                    ),
                    _buildNavItem(
                      theme,
                      4,
                      Icons.person_outline,
                      Icons.person,
                      'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
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

  Widget _buildNavItem(
    ThemeData theme,
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = index == _currentTabIndex;
    final accent = theme.colorScheme.primary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isSelected) return;
            HapticFeedback.selectionClick();
            setState(() => _currentTabIndex = index);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                width: isSelected ? 38 : 34,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? accent.withAlpha(34) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: isSelected ? 1.12 : 0.92,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      size: 19,
                      color: isSelected
                          ? accent
                          : theme.colorScheme.onSurface.withAlpha(155),
                      shadows: isSelected
                          ? [
                              Shadow(
                                color: accent.withAlpha(105),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: theme.textTheme.labelSmall!.copyWith(
                  fontSize: 9,
                  height: 1,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? accent
                      : theme.colorScheme.onSurface.withAlpha(155),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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

            _buildRiskSignalsSection(trades, summary, theme),
            const SizedBox(height: 12),

            _buildIdeasSection(reminders, theme),
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
              reminders: reminders
                  .where((reminder) => reminder.type != 'IDEA')
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSignalsSection(
    List<TradeRecord> trades,
    PortfolioSummary summary,
    ThemeData theme,
  ) {
    final openTrades = trades.where((trade) => trade.status != 'SOLD').toList();
    final alerts = <(IconData, Color, String, String)>[];

    for (final trade in openTrades) {
      if (trade.profitOrLossPercentage <= -5) {
        alerts.add((
          Icons.trending_down,
          theme.colorScheme.error,
          '${trade.symbol} is down ${trade.profitOrLossPercentage.abs().toStringAsFixed(1)}%',
          'Review position size and your original risk limit.',
        ));
      }
      if (trade.daysRemainingToTarget <= 0 && trade.status == 'HOLDING') {
        alerts.add((
          Icons.event_busy,
          theme.colorScheme.secondary,
          '${trade.symbol} reached its planned exit date',
          'Your saved target date has passed. Review the position.',
        ));
      }
    }

    final sectorEntries = summary.sectorBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (summary.currentValue > 0 && sectorEntries.isNotEmpty) {
      final share = sectorEntries.first.value / summary.currentValue;
      if (share >= 0.5) {
        alerts.add((
          Icons.pie_chart_outline,
          theme.colorScheme.primary,
          '${sectorEntries.first.key} is ${(share * 100).round()}% of portfolio value',
          'Consider whether this sector concentration matches your plan.',
        ));
      }
    }

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: theme.colorScheme.primary,
                size: 19,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PORTFOLIO RISK SIGNALS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'LOCAL',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(130),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (alerts.isEmpty)
            Text(
              'No threshold alerts from saved holdings.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withAlpha(175),
                fontSize: 12,
              ),
            )
          else
            ...alerts
                .take(4)
                .map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(alert.$1, color: alert.$2, size: 17),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.$3,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                alert.$4,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    165,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          Text(
            'Rule based checks on locally saved trades and bundled company prices; not a market forecast.',
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withAlpha(135),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeasSection(List<CalendarReminder> reminders, ThemeData theme) {
    final ideas = reminders.where((item) => item.type == 'IDEA').toList();
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'INVESTMENT IDEAS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              IconButton.filledTonal(
                onPressed: _showAddIdeaDialog,
                tooltip: 'Track an idea',
                icon: const Icon(Icons.add, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (ideas.isEmpty)
            Text(
              'Save a thesis or stock to revisit later.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(165),
              ),
            )
          else
            ...ideas
                .take(3)
                .map(
                  (idea) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                idea.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  decoration: idea.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (idea.description.isNotEmpty)
                                Text(
                                  idea.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(160),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: idea.isCompleted,
                          onChanged: (_) => ref
                              .read(remindersProvider.notifier)
                              .toggleReminderCompleted(idea.id),
                        ),
                        IconButton(
                          onPressed: () => ref
                              .read(remindersProvider.notifier)
                              .deleteReminder(idea.id),
                          tooltip: 'Delete idea',
                          icon: const Icon(Icons.close, size: 18),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  void _showAddIdeaDialog() {
    var symbol = '';
    var thesis = '';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Track an investment idea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) => symbol = value.trim().toUpperCase(),
              decoration: const InputDecoration(
                labelText: 'Symbol or short title',
                hintText: 'e.g. NABIL or watch hydropower',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              minLines: 2,
              maxLines: 4,
              onChanged: (value) => thesis = value.trim(),
              decoration: const InputDecoration(
                labelText: 'Thesis / what to revisit',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (symbol.isEmpty) return;
              final now = DateTime.now();
              ref
                  .read(remindersProvider.notifier)
                  .addReminder(
                    CalendarReminder(
                      id: 'IDEA-${now.microsecondsSinceEpoch}',
                      title: symbol,
                      description: thesis,
                      dateAD: now,
                      dateBS: BikramSambatService.adToBs(now).formatBs(),
                      type: 'IDEA',
                    ),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Save idea'),
          ),
        ],
      ),
    );
  }

  // Telemetry Grid
  Widget _buildTelemetryGrid(PortfolioSummary s, ThemeData theme) {
    final isBull = s.totalPnL >= 0;
    final pnlColor = isBull ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final estimatedDailyPercent = s.currentValue > 0
        ? s.dailyEstimatedChange / s.currentValue * 100
        : 0.0;

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, size: 18, color: theme.colorScheme.primary),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: s.currentValue),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Text(
                      'Rs ${value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
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
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        s.dailyEstimatedChange >= 0
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 13,
                        color: s.dailyEstimatedChange >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Est. daily ${s.dailyEstimatedChange >= 0 ? '+' : ''}Rs ${s.dailyEstimatedChange.toStringAsFixed(2)} (${estimatedDailyPercent >= 0 ? '+' : ''}${estimatedDailyPercent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          fontSize: 10,
                          color: s.dailyEstimatedChange >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
    final profile = ref.watch(settingsProvider);
    final profileName = profile.displayName.trim();
    final profileInitial = profileName.isEmpty
        ? 'U'
        : profileName.substring(0, 1).toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GlassPanel(
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withAlpha(35),
                child: Text(
                  profileInitial,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileName.isEmpty ? 'Set up your profile' : profileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 3),
                    Text(
                      profile.emailAddress.isEmpty
                          ? 'Add contact details and preferences'
                          : profile.emailAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Account and security settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsView()),
                ),
                icon: const Icon(Icons.manage_accounts_outlined),
              ),
            ],
          ),
        ),
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
