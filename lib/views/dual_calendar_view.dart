import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_reminder.dart';
import '../providers/app_providers.dart';
import '../services/bikram_sambat_service.dart';
import '../widgets/dual_calendar_dialog.dart';
import '../widgets/empty_state_card.dart';

class DualCalendarView extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const DualCalendarView({super.key, this.isEmbedded = false});

  @override
  ConsumerState<DualCalendarView> createState() => _DualCalendarViewState();
}

class _DualCalendarViewState extends ConsumerState<DualCalendarView> {
  late int _currentBsYear;
  late int _currentBsMonth;
  late int _selectedBsDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final nepDate = BikramSambatService.adToBs(now);
    _currentBsYear = nepDate.year;
    _currentBsMonth = nepDate.month;
    _selectedBsDay = nepDate.day;
  }

  void _nextMonth() {
    setState(() {
      _currentBsMonth++;
      if (_currentBsMonth > 12) {
        _currentBsMonth = 1;
        _currentBsYear++;
      }
    });
  }

  void _prevMonth() {
    setState(() {
      _currentBsMonth--;
      if (_currentBsMonth < 1) {
        _currentBsMonth = 12;
        _currentBsYear--;
      }
    });
  }

  void _addNewReminderDialog(ThemeData theme) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String type = 'CUSTOM';
    DateTime selectedDate = DateTime.now();
    String selectedDateBs = BikramSambatService.adToBs(selectedDate).formatBs();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Calendar Alert / Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        hintText: 'e.g. NABIL Dividend Book Closure',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description / Notes',
                        hintText: 'e.g. 10% Cash + 5% Bonus share alert',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'HOLDING_TARGET',
                          child: Text('ML Holding Target'),
                        ),
                        DropdownMenuItem(
                          value: 'DIVIDEND',
                          child: Text('Dividend / Bonus'),
                        ),
                        DropdownMenuItem(
                          value: 'AGM',
                          child: Text('Annual General Meeting (AGM)'),
                        ),
                        DropdownMenuItem(
                          value: 'BOOK_CLOSURE',
                          child: Text('Book Closure Date'),
                        ),
                        DropdownMenuItem(
                          value: 'CUSTOM',
                          child: Text('Custom Trade Note'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final res = await DualCalendarDialog.show(
                          context,
                          initialDate: selectedDate,
                        );
                        if (res != null) {
                          setDialogState(() {
                            selectedDate = res['adDate'] as DateTime;
                            selectedDateBs = res['bsDate'] as String;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(51),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDateBs,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;

                    final reminder = CalendarReminder(
                      id: 'REM-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      dateAD: selectedDate,
                      dateBS: selectedDateBs,
                      type: type,
                      isNativeSyncEnabled: true,
                    );

                    ref.read(remindersProvider.notifier).addReminder(reminder);
                    Navigator.pop(context);
                  },
                  child: const Text('Save Event'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reminders = ref.watch(remindersProvider);
    final daysInCurrentMonth = BikramSambatService.getDaysInBsMonth(
      _currentBsYear,
      _currentBsMonth,
    );
    final firstDayAd = BikramSambatService.bsToAd(
      _currentBsYear,
      _currentBsMonth,
      1,
    );
    final startWeekdayOffset = firstDayAd.weekday % 7;
    final totalGridCells = startWeekdayOffset + daysInCurrentMonth;

    final now = DateTime.now();
    final todayNep = BikramSambatService.adToBs(now);

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Dual Calendar & Reminders'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_alert_outlined),
                  tooltip: 'Add Alert / Event',
                  onPressed: () => _addNewReminderDialog(theme),
                ),
              ],
            ),
      body: CustomScrollView(
        slivers: [
          if (widget.isEmbedded)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dual Calendar (AD / BS)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add_alert_outlined, size: 18),
                      tooltip: 'Add Alert / Event',
                      onPressed: () => _addNewReminderDialog(theme),
                    ),
                  ],
                ),
              ),
            ),

          // Month Header Card with AD/BS toggle
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _prevMonth,
                        ),
                        Column(
                          children: [
                            Text(
                              '${BikramSambatService.englishMonthNames[_currentBsMonth - 1]} $_currentBsYear BS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              '${BikramSambatService.nepaliMonthNames[_currentBsMonth - 1]} • Bikram Sambat',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  153,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Weekday Labels
                    Row(
                      children: const [
                        _CalendarColLabel('Sun'),
                        _CalendarColLabel('Mon'),
                        _CalendarColLabel('Tue'),
                        _CalendarColLabel('Wed'),
                        _CalendarColLabel('Thu'),
                        _CalendarColLabel('Fri', isWeekend: true),
                        _CalendarColLabel('Sat', isWeekend: true),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Days Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalGridCells,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                            childAspectRatio: 1.1,
                          ),
                      itemBuilder: (context, index) {
                        if (index < startWeekdayOffset) {
                          return const SizedBox();
                        }
                        final day = index - startWeekdayOffset + 1;
                        final isSelected = day == _selectedBsDay;
                        final isToday =
                            _currentBsYear == todayNep.year &&
                            _currentBsMonth == todayNep.month &&
                            day == todayNep.day;
                        final adDate = BikramSambatService.bsToAd(
                          _currentBsYear,
                          _currentBsMonth,
                          day,
                        );
                        final isWeekend =
                            adDate.weekday == DateTime.friday ||
                            adDate.weekday == DateTime.saturday;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedBsDay = day);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (isToday
                                        ? theme.colorScheme.secondary.withAlpha(
                                            38,
                                          )
                                        : (isWeekend
                                              ? theme.colorScheme.error
                                                    .withAlpha(15)
                                              : theme.colorScheme.surface)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isToday
                                    ? theme.colorScheme.secondary
                                    : (isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent),
                                width: isToday ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isToday || isSelected
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
                                  '${adDate.day}',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: isSelected
                                        ? (theme.brightness == Brightness.dark
                                              ? Colors.black87
                                              : Colors.white70)
                                        : theme.colorScheme.onSurface.withAlpha(
                                            128,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Events & Reminders Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EVENTS & HOLDING DEADLINES (${reminders.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addNewReminderDialog(theme),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Add Event',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reminders List
          if (reminders.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyStateCard(
                  icon: Icons.event_available,
                  title: 'No Active Reminders',
                  message: 'Add dividend announcements, book closures, or target holding reminders for your trades.',
                  buttonLabel: 'Add First Reminder',
                  onButtonPressed: () => _addNewReminderDialog(theme),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final r = reminders[index];
                  return _buildReminderTile(r, theme);
                }, childCount: reminders.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderTile(CalendarReminder r, ThemeData theme) {
    IconData icon;
    Color iconColor;

    switch (r.type) {
      case 'HOLDING_TARGET':
        icon = Icons.timer_outlined;
        iconColor = const Color(0xFF10B981);
        break;
      case 'DIVIDEND':
        icon = Icons.savings_outlined;
        iconColor = const Color(0xFFF59E0B);
        break;
      case 'AGM':
        icon = Icons.groups_outlined;
        iconColor = const Color(0xFF3B82F6);
        break;
      case 'BOOK_CLOSURE':
        icon = Icons.lock_clock_outlined;
        iconColor = const Color(0xFFEF4444);
        break;
      default:
        icon = Icons.event_note;
        iconColor = theme.colorScheme.primary;
        break;
    }

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(38),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          r.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: r.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.description.isNotEmpty)
              Text(
                r.description,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              '${r.dateBS} • ${r.dateAD.toIso8601String().split("T")[0]} AD',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: r.isCompleted,
              onChanged: (_) {
                ref
                    .read(remindersProvider.notifier)
                    .toggleReminderCompleted(r.id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () {
                ref.read(remindersProvider.notifier).deleteReminder(r.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarColLabel extends StatelessWidget {
  final String label;
  final bool isWeekend;

  const _CalendarColLabel(this.label, {this.isWeekend = false});

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
