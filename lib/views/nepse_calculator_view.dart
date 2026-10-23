import 'package:flutter/material.dart';

import '../services/nepse_fee_calculator_service.dart';

class NepseCalculatorView extends StatefulWidget {
  const NepseCalculatorView({super.key});

  @override
  State<NepseCalculatorView> createState() => _NepseCalculatorViewState();
}

class _NepseCalculatorViewState extends State<NepseCalculatorView> {
  final _buyPriceController = TextEditingController(text: '500');
  final _quantityController = TextEditingController(text: '100');
  final _sellPriceController = TextEditingController(text: '580');

  String _orderMode = 'BUY'; // 'BUY' or 'SELL'
  String _investorType = 'INDIVIDUAL_SHORT'; // 'INDIVIDUAL_SHORT', 'INDIVIDUAL_LONG', 'INSTITUTIONAL'
  static const int _holdingDays = 90;

  NepseCalculationResult? _buyResult;
  NepseCalculationResult? _sellResult;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  @override
  void dispose() {
    _buyPriceController.dispose();
    _quantityController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  void _compute() {
    final buyPrice = double.tryParse(_buyPriceController.text) ?? 0.0;
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final sellPrice = double.tryParse(_sellPriceController.text) ?? 0.0;

    if (qty > 0 && buyPrice > 0) {
      final bRes = NepseFeeCalculatorService.calculateBuy(
        quantity: qty,
        pricePerShare: buyPrice,
      );

      final sRes = NepseFeeCalculatorService.calculateSell(
        quantity: qty,
        sellPrice: sellPrice > 0 ? sellPrice : buyPrice,
        originalPurchaseCost: bRes.effectiveCost,
        holdingDays: _holdingDays,
        investorType: _investorType,
      );

      setState(() {
        _buyResult = bRes;
        _sellResult = sRes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('NEPSE Fee & Tax Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selector: Buy or Sell
            Row(
              children: [
                Expanded(
                  child: _buildModeTab(
                    'BUY COMMISSION',
                    _orderMode == 'BUY',
                    const Color(0xFF10B981),
                    () => setState(() => _orderMode = 'BUY'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeTab(
                    'SELL & CGT CALC',
                    _orderMode == 'SELL',
                    const Color(0xFFEF4444),
                    () => setState(() => _orderMode = 'SELL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Input Fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buyPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Purchase Price (NPR)',
                      prefixText: 'Rs ',
                    ),
                    onChanged: (_) => _compute(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (Kitta)',
                      suffixText: 'Units',
                    ),
                    onChanged: (_) => _compute(),
                  ),
                ),
              ],
            ),

            if (_orderMode == 'SELL') ...[
              const SizedBox(height: 14),
              TextField(
                controller: _sellPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Selling Price (NPR)',
                  prefixText: 'Rs ',
                ),
                onChanged: (_) => _compute(),
              ),
              const SizedBox(height: 14),

              // Investor Type for CGT
              DropdownButtonFormField<String>(
                initialValue: _investorType,
                decoration: const InputDecoration(
                  labelText: 'Investor Type for CGT',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'INDIVIDUAL_SHORT',
                    child: Text('Individual Short-Term (< 365 days): 7.5% CGT'),
                  ),
                  DropdownMenuItem(
                    value: 'INDIVIDUAL_LONG',
                    child: Text('Individual Long-Term (>= 365 days): 5.0% CGT'),
                  ),
                  DropdownMenuItem(
                    value: 'INSTITUTIONAL',
                    child: Text('Institutional / Corporate: 10.0% CGT'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _investorType = val);
                    _compute();
                  }
                },
              ),
            ],
            const SizedBox(height: 20),

            // Calculation Results Card
            if (_orderMode == 'BUY' && _buyResult != null)
              _buildBuyCard(_buyResult!, theme)
            else if (_orderMode == 'SELL' && _sellResult != null)
              _buildSellCard(_sellResult!, _buyResult!, theme),

            const SizedBox(height: 18),

            // Official NEPSE Slab Reference Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'OFFICIAL NEPSE COMMISSION SLABS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildSlabRow('Up to Rs 50,000', '0.40% (Min Rs 10)'),
                    _buildSlabRow('Rs 50,001 to Rs 500,000', '0.37%'),
                    _buildSlabRow('Rs 500,001 to Rs 2,000,000', '0.34%'),
                    _buildSlabRow('Rs 2,000,001 to Rs 10,000,000', '0.30%'),
                    _buildSlabRow('Above Rs 10,000,000', '0.27%'),
                    const SizedBox(height: 8),
                    _buildSlabRow('SEBON Regulatory Fee', '0.015% of turnover'),
                    _buildSlabRow('DP Charge per Trade', 'Rs 25.00 flat'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyCard(NepseCalculationResult res, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BUYING COST SUMMARY',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
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
                    'Breakeven Exit: Rs ${res.breakevenPrice}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildResultRow(
              'Gross Amount (Shares × Price)',
              'Rs ${res.grossAmount.toStringAsFixed(2)}',
            ),
            _buildResultRow(
              'Broker Commission',
              'Rs ${res.brokerCommission.toStringAsFixed(2)}',
            ),
            _buildResultRow(
              'SEBON Fee (0.015%)',
              'Rs ${res.sebonFee.toStringAsFixed(2)}',
            ),
            _buildResultRow('DP Charge', 'Rs ${res.dpFee.toStringAsFixed(2)}'),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Effective Buy Cost:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rs ${res.effectiveCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellCard(
    NepseCalculationResult sell,
    NepseCalculationResult buy,
    ThemeData theme,
  ) {
    final isBull = sell.profitOrLoss >= 0;
    final color = isBull ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SELLING & NET PNL SUMMARY',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isBull ? '+' : ''}${sell.profitPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildResultRow(
              'Gross Sell Amount',
              'Rs ${sell.grossAmount.toStringAsFixed(2)}',
            ),
            _buildResultRow(
              'Selling Broker Commission',
              'Rs ${sell.brokerCommission.toStringAsFixed(2)}',
            ),
            _buildResultRow(
              'SEBON + DP Charge',
              'Rs ${(sell.sebonFee + sell.dpFee).toStringAsFixed(2)}',
            ),
            _buildResultRow(
              'Original Total Purchase Cost',
              'Rs ${buy.effectiveCost.toStringAsFixed(2)}',
            ),
            _buildResultRow(
              'Capital Gains Tax (CGT)',
              'Rs ${sell.capitalGainsTax.toStringAsFixed(2)}',
              highlight: sell.capitalGainsTax > 0,
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Profit / Loss:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${isBull ? '+' : ''}Rs ${sell.profitOrLoss.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Bank Receivable:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Rs ${sell.netReceivable.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(
    String label,
    bool isSelected,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: activeColor, width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : activeColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.amber : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlabRow(String tier, String rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(tier, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            rate,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
