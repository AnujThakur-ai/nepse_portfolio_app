import 'package:flutter/material.dart';

import '../models/calendar_reminder.dart';
import '../providers/app_providers.dart';
import '../services/bikram_sambat_service.dart';

class HomeWidgetPreview extends StatefulWidget {
  final PortfolioSummary summary;
  final List<String> watchlist;
  final List<CalendarReminder> reminders;

  const HomeWidgetPreview({
    super.key,
    required this.summary,
    required this.watchlist,
    required this.reminders,
  });

  @override
  State<HomeWidgetPreview> createState() => _HomeWidgetPreviewState();
}

class _HomeWidgetPreviewState extends State<HomeWidgetPreview> {
  int _selectedWidgetSize = 0; // 0=Small (2x2), 1=Medium (4x2), 2=Large (4x4)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      Icons.widgets_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'HOME SCREEN WIDGETS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                // Size segmented control
                Row(
                  children: [
                    _buildSizeBtn(0, 'Small (2x2)', theme),
                    const SizedBox(width: 4),
                    _buildSizeBtn(1, 'Medium (4x2)', theme),
                    const SizedBox(width: 4),
                    _buildSizeBtn(2, 'Large (4x4)', theme),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Realistic Device Home Screen Mockup Frame
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _selectedWidgetSize == 0
                    ? 180
                    : (_selectedWidgetSize == 1 ? 340 : 340),
                height: _selectedWidgetSize == 0
                    ? 180
                    : (_selectedWidgetSize == 1 ? 160 : 320),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(77),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(102),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildSelectedWidget(theme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedWidget(ThemeData theme) {
    switch (_selectedWidgetSize) {
      case 0:
        return _buildSmallWidget(theme);
      case 1:
        return _buildMediumWidget(theme);
      case 2:
      default:
        return _buildLargeWidget(theme);
    }
  }

  // Small Widget (2x2): Portfolio PnL Quick Counter & Daily Trend
  Widget _buildSmallWidget(ThemeData theme) {
    final isBull = widget.summary.totalPnL >= 0;
    final color = isBull ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.surface, color.withAlpha(26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEPSE PORTFOLIO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.primary,
                ),
              ),
              Icon(Icons.bolt, color: color, size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rs ${widget.summary.currentValue.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    isBull ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${isBull ? '+' : ''}${widget.summary.pnlPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withAlpha(20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${widget.summary.totalHoldingCount} Active Positions',
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.onSurface.withAlpha(179),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Medium Widget (4x2): Watchlist & MACD Signal Alerts
  Widget _buildMediumWidget(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.candlestick_chart,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'WATCHLIST & MACD RADAR',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(38),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '3 BULLISH CROSSES',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStockBadge('NABIL', 'Rs 540', '+1.69%', true, theme),
              _buildMiniStockBadge('SHIVM', 'Rs 518', '+2.98%', true, theme),
              _buildMiniStockBadge('NICA', 'Rs 432', '-1.59%', false, theme),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEPSE Market Status: ${BikramSambatService.getNepseMarketStatus()}',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
              Icon(Icons.refresh, size: 14, color: theme.colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  // Large Widget (4x4): Portfolio Summary + Mini BS/AD Calendar & Target Reminders
  Widget _buildLargeWidget(ThemeData theme) {
    final now = DateTime.now();
    final nepDate = BikramSambatService.adToBs(now);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEPSE TRADER PRO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${nepDate.formatFullNepali()} (${now.day} ${_monthName(now.month)})',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(38),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Total PnL: Rs ${widget.summary.totalPnL.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Holding Reminders
          Text(
            'UPCOMING TARGET EXITS & DIVIDENDS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.reminders.take(3).length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final r = widget.reminders[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(38),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            r.type == 'HOLDING_TARGET'
                                ? Icons.timer_outlined
                                : Icons.savings_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                r.dateBS,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    153,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right, size: 14),
                    ],
                  ),
                );
              },
            ),
          ),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Synced with Device Home Launcher',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withAlpha(128),
                ),
              ),
              Icon(Icons.touch_app, size: 14, color: theme.colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStockBadge(
    String symbol,
    String price,
    String change,
    bool isBull,
    ThemeData theme,
  ) {
    final color = isBull ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Text(
            symbol,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Text(price, style: const TextStyle(fontSize: 10)),
          Text(
            change,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeBtn(int index, String label, ThemeData theme) {
    final isSelected = _selectedWidgetSize == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedWidgetSize = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha(38),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
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

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }
}
