import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/holding_prediction.dart';
import '../providers/app_providers.dart';
import '../services/company_repository.dart';
import '../services/holding_estimate_service.dart';
import '../widgets/analog_gauge_widget.dart';
import '../widgets/technical_chart_widget.dart';
import 'trade_logger_view.dart';

class TechnicalAnalysisView extends ConsumerStatefulWidget {
  final String? initialSymbol;
  final bool isEmbedded;

  const TechnicalAnalysisView({
    super.key,
    this.initialSymbol,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<TechnicalAnalysisView> createState() =>
      _TechnicalAnalysisViewState();
}

class _TechnicalAnalysisViewState extends ConsumerState<TechnicalAnalysisView> {
  late String _currentSymbol;
  HoldingPrediction? _prediction;
  bool _isLoadingPrediction = false;

  @override
  void initState() {
    super.initState();
    _currentSymbol = widget.initialSymbol ?? 'NABIL';
    _runPredictionForCurrent();
  }

  Future<void> _runPredictionForCurrent() async {
    setState(() => _isLoadingPrediction = true);
    final indicators = ref.read(technicalIndicatorProvider(_currentSymbol));
    final company = CompanyRepository.findBySymbol(_currentSymbol);

    if (company != null) {
      final pred = await HoldingEstimateService.predictOptimalHolding(
        buyPrice: company.ltp,
        quantity: 100,
        indicators: indicators,
      );
      setState(() {
        _prediction = pred;
        _isLoadingPrediction = false;
      });
    } else {
      setState(() => _isLoadingPrediction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final company =
        CompanyRepository.findBySymbol(_currentSymbol) ??
        CompanyRepository.initialCompanies.first;
    final indicators = ref.watch(technicalIndicatorProvider(_currentSymbol));

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text('$_currentSymbol Technical Radar'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart),
                  tooltip: 'Log Trade for $_currentSymbol',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TradeLoggerView(preselectedSymbol: _currentSymbol),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isEmbedded)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_currentSymbol Technical Radar',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      tooltip: 'Log Trade for $_currentSymbol',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TradeLoggerView(
                              preselectedSymbol: _currentSymbol,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // Company Selector Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CompanyRepository.initialCompanies.map((c) {
                  final isSelected = c.symbol == _currentSymbol;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c.symbol),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _currentSymbol = c.symbol;
                        });
                        _runPredictionForCurrent();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Main Interactive Technical Chart
            TechnicalChartWidget(
              prices: company.recentPrices,
              sma20: indicators.prices.isNotEmpty
                  ? List.filled(indicators.prices.length, indicators.sma20)
                  : null,
              symbol: company.symbol,
              currentPrice: company.ltp,
              change: company.priceChange,
              percentageChange: company.percentageChange,
            ),
            const SizedBox(height: 14),

            // Analog Speedometer Gauge for Composite Sentiment
            AnalogGaugeWidget(
              value: indicators.sentimentScore,
              title: '${company.symbol} SENTIMENT RADAR',
              subtitle: 'Multi-Indicator Confluence Score (0-100)',
            ),
            const SizedBox(height: 14),

            // Technical Indicators Grid Cards
            Row(
              children: [
                Expanded(
                  child: _buildIndicatorTile(
                    'MACD (12, 26, 9)',
                    indicators.histogram > 0 ? 'BULLISH' : 'BEARISH',
                    'Hist: ${indicators.histogram.toStringAsFixed(2)}',
                    indicators.histogram > 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    theme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildIndicatorTile(
                    'RSI (14 Wilder)',
                    indicators.rsi.toStringAsFixed(1),
                    indicators.isRsiOversold
                        ? 'OVERSOLD'
                        : (indicators.isRsiOverbought
                              ? 'OVERBOUGHT'
                              : 'NEUTRAL'),
                    indicators.isRsiOversold
                        ? const Color(0xFF10B981)
                        : (indicators.isRsiOverbought
                              ? const Color(0xFFEF4444)
                              : theme.colorScheme.primary),
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildIndicatorTile(
                    'Bollinger Bands',
                    'Mid: ${indicators.middleBollinger.toStringAsFixed(1)}',
                    'Band: [${indicators.lowerBollinger.toStringAsFixed(0)} - ${indicators.upperBollinger.toStringAsFixed(0)}]',
                    theme.colorScheme.secondary,
                    theme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildIndicatorTile(
                    'Moving Averages',
                    'SMA 20: ${indicators.sma20.toStringAsFixed(1)}',
                    indicators.isAboveSma20
                        ? 'Above 20-EMA (Bull)'
                        : 'Below 20-EMA (Bear)',
                    indicators.isAboveSma20
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Rule-based holding estimate card.
            Card(
              elevation: 2,
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
                              Icons.psychology,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'RULE-BASED HOLDING ESTIMATE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        if (_isLoadingPrediction)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            tooltip: 'Recalculate estimate',
                            onPressed: _runPredictionForCurrent,
                          ),
                      ],
                    ),
                    const Divider(height: 16),
                    if (_prediction != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_prediction!.predictedDays} Trading Days',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Target Exit: ${_prediction!.targetSellDateBS}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(38),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${_prediction!.projectedReturnPercentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                Text(
                                  'Scenario price: Rs ${_prediction!.projectedExitPrice}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Recommendation: ${_prediction!.recommendation}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Rule inputs:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Illustrative rule-based scenario only; not a price forecast.',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                      ..._prediction!.featureContributions.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                entry.value.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Trade Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TradeLoggerView(preselectedSymbol: _currentSymbol),
                  ),
                );
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: Text('LOG TRADE FOR $_currentSymbol'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorTile(
    String title,
    String mainValue,
    String subValue,
    Color accentColor,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withAlpha(153),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mainValue,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withAlpha(179),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
