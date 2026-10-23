import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/trade_record.dart';

class PortfolioValueChart extends StatelessWidget {
  const PortfolioValueChart({super.key, required this.trades});

  final List<TradeRecord> trades;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holdings = <String, ({double cost, double value})>{};
    for (final trade in trades) {
      final previous = holdings[trade.symbol];
      holdings[trade.symbol] = (
        cost: (previous?.cost ?? 0) + trade.effectiveCost,
        value: (previous?.value ?? 0) + trade.currentValue,
      );
    }
    final entries = holdings.entries.toList()
      ..sort((a, b) => b.value.value.compareTo(a.value.value));
    final visible = entries.take(6).toList();
    final maxValue = visible.fold<double>(0, (max, item) {
      final highest = item.value.cost > item.value.value
          ? item.value.cost
          : item.value.value;
      return highest > max ? highest : max;
    });

    return Card(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio snapshot',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cost basis vs last recorded value',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.insights_rounded, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            if (visible.isEmpty)
              Container(
                height: 120,
                alignment: Alignment.center,
                child: Text(
                  'Add an active holding to see your portfolio chart',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 210,
                child: BarChart(
                  BarChartData(
                    maxY: maxValue <= 0 ? 100 : maxValue * 1.25,
                    minY: 0,
                    alignment: BarChartAlignment.spaceAround,
                    groupsSpace: 18,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: theme.dividerColor.withAlpha(110),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 46,
                          getTitlesWidget: (value, meta) => Text(
                            _compact(value),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= visible.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                visible[index].key,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(visible.length, (index) {
                      final entry = visible[index];
                      return BarChartGroupData(
                        x: index,
                        barsSpace: 5,
                        barRods: [
                          _rod(entry.value.cost, const Color(0xFF9AA9C4)),
                          _rod(entry.value.value, theme.colorScheme.primary),
                        ],
                      );
                    }),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final entry = visible[group.x];
                          final label = rodIndex == 0
                              ? 'Cost basis'
                              : 'Last recorded';
                          return BarTooltipItem(
                            '${entry.key} · $label\nRs ${rod.toY.toStringAsFixed(0)}',
                            TextStyle(
                              color: theme.colorScheme.onInverseSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendDot(color: const Color(0xFF9AA9C4), label: 'Cost basis'),
                const SizedBox(width: 18),
                _LegendDot(
                  color: theme.colorScheme.primary,
                  label: 'Last recorded',
                ),
                const Spacer(),
                if (entries.length > visible.length)
                  Text(
                    '+${entries.length - visible.length} more',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartRodData _rod(double value, Color color) => BarChartRodData(
    toY: value,
    width: 11,
    color: color,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
  );

  String _compact(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
