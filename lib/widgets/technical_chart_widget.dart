import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TechnicalChartWidget extends StatefulWidget {
  final List<double> prices;
  final List<double>? sma20;
  final List<double>? volumes;
  final String symbol;
  final double currentPrice;
  final double change;
  final double percentageChange;

  const TechnicalChartWidget({
    super.key,
    required this.prices,
    this.sma20,
    this.volumes,
    required this.symbol,
    required this.currentPrice,
    required this.change,
    required this.percentageChange,
  });

  @override
  State<TechnicalChartWidget> createState() => _TechnicalChartWidgetState();
}

class _TechnicalChartWidgetState extends State<TechnicalChartWidget> {
  int _selectedPeriodIndex = 0; // 0=1M, 1=3M, 2=All
  bool _showSma = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBullish = widget.change >= 0;
    final trendColor = isBullish
        ? (theme.brightness == Brightness.dark
              ? const Color(0xFF10B981)
              : const Color(0xFF16A34A))
        : (theme.brightness == Brightness.dark
              ? const Color(0xFFEF4444)
              : const Color(0xFFDC2626));

    if (widget.prices.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No historical price data available')),
      );
    }

    // Filter by selected period (1M: last 15 points, 3M: last 35 points, ALL: all points)
    List<double> displayPrices = widget.prices;
    List<double>? displaySma = widget.sma20;

    if (_selectedPeriodIndex == 0) {
      final count = min(15, widget.prices.length);
      displayPrices = widget.prices.sublist(widget.prices.length - count);
      if (widget.sma20 != null && widget.sma20!.isNotEmpty) {
        final smaCount = min(count, widget.sma20!.length);
        displaySma = widget.sma20!.sublist(widget.sma20!.length - smaCount);
      }
    } else if (_selectedPeriodIndex == 1) {
      final count = min(35, widget.prices.length);
      displayPrices = widget.prices.sublist(widget.prices.length - count);
      if (widget.sma20 != null && widget.sma20!.isNotEmpty) {
        final smaCount = min(count, widget.sma20!.length);
        displaySma = widget.sma20!.sublist(widget.sma20!.length - smaCount);
      }
    }

    final minPrice = displayPrices.reduce(min) * 0.98;
    final maxPrice = displayPrices.reduce(max) * 1.02;

    final priceSpots = displayPrices.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    List<FlSpot>? smaSpots;
    if (_showSma && displaySma != null && displaySma.isNotEmpty) {
      smaSpots = displaySma.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value);
      }).toList();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Symbol, Price, and Period Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.symbol,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: trendColor.withAlpha(38),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${isBullish ? '+' : ''}${widget.percentageChange.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: trendColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs ${widget.currentPrice.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                // Controls
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _showSma ? Icons.show_chart : Icons.timeline,
                        color: _showSma
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withAlpha(102),
                        size: 20,
                      ),
                      tooltip: 'Toggle 20-EMA',
                      onPressed: () {
                        setState(() {
                          _showSma = !_showSma;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    _buildPeriodChip(0, '1M', theme),
                    const SizedBox(width: 4),
                    _buildPeriodChip(1, '3M', theme),
                    const SizedBox(width: 4),
                    _buildPeriodChip(2, 'ALL', theme),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price Chart
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: minPrice,
                  maxY: maxPrice,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((maxPrice - minPrice) / 4).clamp(
                      1.0,
                      500.0,
                    ),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.onSurface.withAlpha(20),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          theme.colorScheme.surface,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            'Rs ${spot.y.toStringAsFixed(1)}',
                            TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    // Main Price Line
                    LineChartBarData(
                      spots: priceSpots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: trendColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            trendColor.withAlpha(64),
                            trendColor.withAlpha(0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // SMA Line
                    if (smaSpots != null)
                      LineChartBarData(
                        spots: smaSpots,
                        isCurved: true,
                        color: theme.colorScheme.primary.withAlpha(179),
                        barWidth: 1.5,
                        dashArray: [5, 4],
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                ),
              ),
            ),

            if (_showSma && widget.sma20 != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 14,
                      height: 3,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '20-Day SMA',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(int index, String label, ThemeData theme) {
    final isSelected = _selectedPeriodIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPeriodIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
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
            fontSize: 10,
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
}
