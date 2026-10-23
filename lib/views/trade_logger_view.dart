import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/calendar_reminder.dart';
import '../models/company_profile.dart';
import '../models/holding_prediction.dart';
import '../models/trade_record.dart';
import '../providers/app_providers.dart';
import '../services/bikram_sambat_service.dart';
import '../services/company_repository.dart';
import '../services/indicator_calculator_service.dart';
import '../services/nepse_fee_calculator_service.dart';
import '../services/holding_estimate_service.dart';
import '../widgets/dual_calendar_dialog.dart';

class TradeLoggerView extends ConsumerStatefulWidget {
  final String? preselectedSymbol;

  const TradeLoggerView({super.key, this.preselectedSymbol});

  @override
  ConsumerState<TradeLoggerView> createState() => _TradeLoggerViewState();
}

class _TradeLoggerViewState extends ConsumerState<TradeLoggerView> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _tradeDate = DateTime.now();
  String _tradeDateBs = '';

  String _transactionType = 'BUY'; // 'BUY' or 'SELL'
  String? _selectedSector;
  String? _companyName;

  // ML Prediction
  HoldingPrediction? _prediction;
  bool _isPredicting = false;

  // Fee calculation
  NepseCalculationResult? _feeResult;

  // Receipt image
  String? _receiptImagePath;

  @override
  void initState() {
    super.initState();
    _tradeDateBs = BikramSambatService.adToBs(_tradeDate).formatBs();

    if (widget.preselectedSymbol != null) {
      _symbolController.text = widget.preselectedSymbol!;
      _onSymbolSelected(widget.preselectedSymbol!);
    }
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSymbolSelected(String symbol) {
    final company = CompanyRepository.findBySymbol(symbol);
    if (company != null) {
      setState(() {
        _companyName = company.companyName;
        _selectedSector = company.sector;
        _priceController.text = company.ltp.toStringAsFixed(1);
      });
      _recalculateFees();
      _calculateHoldingEstimate();
    }
  }

  void _recalculateFees() {
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final qty = int.tryParse(_quantityController.text) ?? 0;

    if (price > 0 && qty > 0) {
      setState(() {
        if (_transactionType == 'BUY') {
          _feeResult = NepseFeeCalculatorService.calculateBuy(
            quantity: qty,
            pricePerShare: price,
          );
        } else {
          _feeResult = NepseFeeCalculatorService.calculateSell(
            quantity: qty,
            sellPrice: price,
            originalPurchaseCost: price * qty * 0.9,
            holdingDays: 60,
          );
        }
      });
    }
  }

  Future<void> _calculateHoldingEstimate() async {
    final symbol = _symbolController.text.trim().toUpperCase();
    final company = CompanyRepository.findBySymbol(symbol);
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final qty = int.tryParse(_quantityController.text) ?? 100;

    if (company == null || price <= 0) return;

    setState(() => _isPredicting = true);

    final volumes = List.generate(
      company.recentPrices.length,
      (i) => (company.volume / 20) + (i * 1200),
    );
    final indicators = IndicatorCalculatorService.analyzeSymbol(
      symbol: symbol,
      prices: company.recentPrices,
      volumes: volumes,
    );

    final pred = await HoldingEstimateService.predictOptimalHolding(
      buyPrice: price,
      quantity: qty,
      indicators: indicators,
      tradeDate: _tradeDate,
    );

    setState(() {
      _prediction = pred;
      _isPredicting = false;
    });
  }

  Future<void> _pickReceiptImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _receiptImagePath = picked.path;
        });
      }
    } catch (_) {}
  }

  Future<void> _openDatePicker() async {
    final result = await DualCalendarDialog.show(
      context,
      initialDate: _tradeDate,
    );
    if (result != null) {
      setState(() {
        _tradeDate = result['adDate'] as DateTime;
        _tradeDateBs = result['bsDate'] as String;
      });
      _calculateHoldingEstimate();
    }
  }

  void _saveTrade() {
    if (!_formKey.currentState!.validate()) return;

    final symbol = _symbolController.text.trim().toUpperCase();
    final price = double.parse(_priceController.text);
    final qty = int.parse(_quantityController.text);
    final company = CompanyRepository.findBySymbol(symbol);

    final gross = price * qty;
    final commission = NepseFeeCalculatorService.calculateBrokerCommission(
      gross,
    );
    final sebon = NepseFeeCalculatorService.calculateSebonFee(gross);
    const dp = NepseFeeCalculatorService.dpFeeStandard;

    final isSell = _transactionType == 'SELL';
    final effectiveCost = isSell
        ? (gross - commission - sebon - dp)
        : (gross + commission + sebon + dp);

    final predDays = _prediction?.predictedDays ?? 30;
    final targetSellDate =
        _prediction?.targetSellDate ?? _tradeDate.add(Duration(days: predDays));
    final targetSellDateBS =
        _prediction?.targetSellDateBS ??
        BikramSambatService.adToBs(targetSellDate).formatBs();

    final trade = TradeRecord(
      id: 'TRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      symbol: symbol,
      companyName: _companyName ?? company?.companyName ?? symbol,
      sector: _selectedSector ?? company?.sector ?? 'General',
      transactionType: _transactionType,
      transactionDate: _tradeDate,
      bsDate: _tradeDateBs,
      quantity: qty,
      pricePerShare: price,
      totalAmount: gross,
      brokerCommission: commission,
      sebonFee: sebon,
      dpCharge: dp,
      effectiveCost: effectiveCost,
      targetSellDate: targetSellDate,
      targetSellDateBS: targetSellDateBS,
      predictedHoldingDays: predDays,
      status: isSell ? 'SOLD' : 'HOLDING',
      receiptImagePath: _receiptImagePath,
      notes: _notesController.text,
      currentLtp: company?.ltp ?? price,
    );

    // Add trade
    ref.read(tradesProvider.notifier).addTrade(trade);

    if (!isSell) {
      // Auto-create Calendar Reminder for target sell date for new holdings
      final reminder = CalendarReminder(
        id: 'REM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        title: '$symbol Target Exit Date',
        description:
            'ML optimal holding period of $predDays trading days completed for $qty shares of $symbol.',
        dateAD: targetSellDate,
        dateBS: targetSellDateBS,
        type: 'HOLDING_TARGET',
        symbol: symbol,
      );
      ref.read(remindersProvider.notifier).addReminder(reminder);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSell
              ? 'Sell trade logged for $symbol! Net receivable: Rs ${effectiveCost.toStringAsFixed(2)}'
              : 'Buy trade logged! ML Target Exit Reminder set for $targetSellDateBS',
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Log NEPSE Trade')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Buy / Sell Selector
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      'BUY ORDER',
                      _transactionType == 'BUY',
                      const Color(0xFF10B981),
                      () {
                        setState(() => _transactionType = 'BUY');
                        _recalculateFees();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(
                      'SELL ORDER',
                      _transactionType == 'SELL',
                      const Color(0xFFEF4444),
                      () {
                        setState(() => _transactionType = 'SELL');
                        _recalculateFees();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Symbol Field with Autocomplete
              Autocomplete<CompanyProfile>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return CompanyRepository.initialCompanies;
                  }
                  return CompanyRepository.searchCompanies(
                    textEditingValue.text,
                  );
                },
                displayStringForOption: (option) =>
                    '${option.symbol} - ${option.companyName}',
                onSelected: (option) {
                  _symbolController.text = option.symbol;
                  _onSymbolSelected(option.symbol);
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      if (_symbolController.text.isNotEmpty &&
                          controller.text != _symbolController.text) {
                        controller.text = _symbolController.text;
                      }
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'NEPSE Symbol / Company',
                          hintText: 'e.g. NABIL, SHIVM, CHCL, GBIME',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _companyName != null
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF10B981),
                                )
                              : null,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter stock symbol';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          _symbolController.text = val;
                          final comp = CompanyRepository.findBySymbol(val);
                          if (comp != null) {
                            _onSymbolSelected(comp.symbol);
                          }
                        },
                      );
                    },
              ),
              if (_companyName != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _companyName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _selectedSector ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Price & Quantity in a Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price per Share (NPR)',
                        hintText: '0.0',
                        prefixText: 'Rs ',
                      ),
                      validator: (val) {
                        final p = double.tryParse(val ?? '');
                        if (p == null || p <= 0) return 'Invalid price';
                        if (!CompanyRepository.isValidPriceTick(p)) {
                          return 'Tick size must be Rs 0.10';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        _recalculateFees();
                        _calculateHoldingEstimate();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity (Kitta)',
                        hintText: '100',
                        suffixText: 'Units',
                      ),
                      validator: (val) {
                        final q = int.tryParse(val ?? '');
                        if (q == null || q <= 0) return 'Enter quantity';
                        return null;
                      },
                      onChanged: (_) {
                        _recalculateFees();
                        _calculateHoldingEstimate();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Dual Calendar Date Picker Card
              GestureDetector(
                onTap: _openDatePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(51),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction Date (AD / BS)',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  153,
                                ),
                              ),
                            ),
                            Text(
                              '$_tradeDateBs (${_tradeDate.year}-${_tradeDate.month.toString().padLeft(2, '0')}-${_tradeDate.day.toString().padLeft(2, '0')} AD)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_calendar, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Embedded NEPSE Tax & Commission Fee Breakdown
              if (_feeResult != null) _buildFeeBreakdownCard(theme),
              const SizedBox(height: 16),

              // Embedded rule-based holding estimate card.
              _buildHoldingEstimateCard(theme),
              const SizedBox(height: 16),

              // Attach Receipt / Bill Image
              GestureDetector(
                onTap: _pickReceiptImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withAlpha(51),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _receiptImagePath != null
                            ? Icons.image
                            : Icons.attach_file,
                        color: _receiptImagePath != null
                            ? const Color(0xFF10B981)
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _receiptImagePath != null
                              ? 'Trade Bill Attached (${_receiptImagePath!.split("/").last})'
                              : 'Attach TMS Bill / Broker Contract Note',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _receiptImagePath != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Icon(
                        _receiptImagePath != null
                            ? Icons.check
                            : Icons.camera_alt,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Strategy Notes / Entry Rationale',
                  hintText: 'e.g. Swing entry on 20-day EMA support with MACD confirmation',
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _saveTrade,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  _transactionType == 'BUY'
                      ? 'EXECUTE & LOG BUY ORDER'
                      : 'EXECUTE & LOG SELL ORDER',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _transactionType == 'BUY'
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
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
            letterSpacing: 0.8,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFeeBreakdownCard(ThemeData theme) {
    final res = _feeResult!;
    return Card(
      elevation: 1,
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
                      Icons.receipt_long,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'NEPSE FEE BREAKDOWN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Breakeven: Rs ${res.breakevenPrice}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildFeeRow(
              'Gross Trade Amount',
              'Rs ${res.grossAmount.toStringAsFixed(2)}',
            ),
            _buildFeeRow(
              'Broker Commission (Slab)',
              'Rs ${res.brokerCommission.toStringAsFixed(2)}',
            ),
            _buildFeeRow(
              'SEBON Regulatory Fee (0.015%)',
              'Rs ${res.sebonFee.toStringAsFixed(2)}',
            ),
            _buildFeeRow(
              'DP Fee per Transaction',
              'Rs ${res.dpFee.toStringAsFixed(2)}',
            ),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Effective Total Buying Cost:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Rs ${res.effectiveCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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

  Widget _buildHoldingEstimateCard(ThemeData theme) {
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
                      'RULE-BASED HOLDING ESTIMATE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                if (_isPredicting)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_prediction != null)
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
                      '${(_prediction!.confidence * 100).toStringAsFixed(0)}% INDICATOR ALIGNMENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Target Exit: ${_prediction!.targetSellDateBS}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
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
                            fontSize: 14,
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
              const SizedBox(height: 8),
              Text(
                'Strategy: ${_prediction!.recommendation}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withAlpha(179),
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
            ] else
              Text(
                'Select a symbol for an indicative holding period based on available technical indicators.',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withAlpha(128),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
