import 'package:flutter/material.dart';

import '../services/bikram_sambat_service.dart';

class DualCalendarDialog extends StatefulWidget {
  final DateTime initialDate;

  const DualCalendarDialog({super.key, required this.initialDate});

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    DateTime? initialDate,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          DualCalendarDialog(initialDate: initialDate ?? DateTime.now()),
    );
  }

  @override
  State<DualCalendarDialog> createState() => _DualCalendarDialogState();
}

class _DualCalendarDialogState extends State<DualCalendarDialog> {
  bool _isBsMode = true; // Toggle between BS (Bikram Sambat) and AD (Gregorian)
  late int _selectedBsYear;
  late int _selectedBsMonth;
  late int _selectedBsDay;
  late DateTime _selectedAdDate;

  @override
  void initState() {
    super.initState();
    _selectedAdDate = widget.initialDate;
    final nepDate = BikramSambatService.adToBs(_selectedAdDate);
    _selectedBsYear = nepDate.year;
    _selectedBsMonth = nepDate.month;
    _selectedBsDay = nepDate.day;
  }

  void _onBsDaySelected(int day) {
    setState(() {
      _selectedBsDay = day;
      _selectedAdDate = BikramSambatService.bsToAd(
        _selectedBsYear,
        _selectedBsMonth,
        day,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = BikramSambatService.getDaysInBsMonth(
      _selectedBsYear,
      _selectedBsMonth,
    );
    final firstDayAd = BikramSambatService.bsToAd(
      _selectedBsYear,
      _selectedBsMonth,
      1,
    );
    final startWeekdayOffset = firstDayAd.weekday % 7;
    final totalGridCells = startWeekdayOffset + daysInMonth;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(18),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calendar Switch Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Dual Calendar (AD / BS)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                // Toggle AD / BS switch
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(51),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildModeButton('BS', _isBsMode, () {
                        setState(() => _isBsMode = true);
                      }, theme),
                      _buildModeButton('AD', !_isBsMode, () {
                        setState(() => _isBsMode = false);
                      }, theme),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Selection Banner Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(77),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bikram Sambat (BS)',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                      Text(
                        'Gregorian (AD)',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_selectedBsDay ${BikramSambatService.englishMonthNames[_selectedBsMonth - 1]} $_selectedBsYear',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${_selectedAdDate.year}-${_selectedAdDate.month.toString().padLeft(2, '0')}-${_selectedAdDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Month / Year Selectors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<int>(
                  value: _selectedBsMonth,
                  dropdownColor: theme.cardColor,
                  underline: const SizedBox(),
                  items: List.generate(12, (index) {
                    final m = index + 1;
                    return DropdownMenuItem(
                      value: m,
                      child: Text(
                        '${BikramSambatService.englishMonthNames[index]} (${BikramSambatService.nepaliMonthNames[index]})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedBsMonth = val;
                        if (_selectedBsDay >
                            BikramSambatService.getDaysInBsMonth(
                              _selectedBsYear,
                              _selectedBsMonth,
                            )) {
                          _selectedBsDay = BikramSambatService.getDaysInBsMonth(
                            _selectedBsYear,
                            _selectedBsMonth,
                          );
                        }
                        _selectedAdDate = BikramSambatService.bsToAd(
                          _selectedBsYear,
                          _selectedBsMonth,
                          _selectedBsDay,
                        );
                      });
                    }
                  },
                ),
                DropdownButton<int>(
                  value: _selectedBsYear,
                  dropdownColor: theme.cardColor,
                  underline: const SizedBox(),
                  items: List.generate(15, (index) {
                    final yr = 2075 + index;
                    return DropdownMenuItem(
                      value: yr,
                      child: Text(
                        '$yr BS',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedBsYear = val;
                        _selectedAdDate = BikramSambatService.bsToAd(
                          _selectedBsYear,
                          _selectedBsMonth,
                          _selectedBsDay,
                        );
                      });
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 16),

            // Weekday Headers
            Row(
              children: const [
                _WeekdayLabel('Sun'),
                _WeekdayLabel('Mon'),
                _WeekdayLabel('Tue'),
                _WeekdayLabel('Wed'),
                _WeekdayLabel('Thu'),
                _WeekdayLabel('Fri', isWeekend: true),
                _WeekdayLabel('Sat', isWeekend: true),
              ],
            ),
            const SizedBox(height: 6),

            // Days Grid
            SizedBox(
              height: 230,
              child: GridView.builder(
                itemCount: totalGridCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  if (index < startWeekdayOffset) {
                    return const SizedBox();
                  }
                  final day = index - startWeekdayOffset + 1;
                  final isSelected = day == _selectedBsDay;
                  final adEquivalent = BikramSambatService.bsToAd(
                    _selectedBsYear,
                    _selectedBsMonth,
                    day,
                  );
                  final isWeekend =
                      adEquivalent.weekday == DateTime.friday ||
                      adEquivalent.weekday == DateTime.saturday;

                  return GestureDetector(
                    onTap: () => _onBsDaySelected(day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isWeekend
                                  ? theme.colorScheme.error.withAlpha(20)
                                  : theme.colorScheme.surface),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? (theme.brightness == Brightness.dark
                                        ? Colors.black
                                        : Colors.white)
                                  : (isWeekend
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurface),
                            ),
                          ),
                          Text(
                            '${adEquivalent.day}',
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected
                                  ? (theme.brightness == Brightness.dark
                                        ? Colors.black87
                                        : Colors.white70)
                                  : theme.colorScheme.onSurface.withAlpha(128),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final formattedBs =
                        '$_selectedBsYear-${_selectedBsMonth.toString().padLeft(2, '0')}-${_selectedBsDay.toString().padLeft(2, '0')} BS';
                    Navigator.pop(context, {
                      'adDate': _selectedAdDate,
                      'bsDate': formattedBs,
                      'bsYear': _selectedBsYear,
                      'bsMonth': _selectedBsMonth,
                      'bsDay': _selectedBsDay,
                    });
                  },
                  child: const Text('Select Date'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
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

class _WeekdayLabel extends StatelessWidget {
  final String label;
  final bool isWeekend;

  const _WeekdayLabel(this.label, {this.isWeekend = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isWeekend
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface.withAlpha(153),
        ),
      ),
    );
  }
}
