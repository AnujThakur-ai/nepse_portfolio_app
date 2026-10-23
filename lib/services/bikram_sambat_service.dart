class NepDate {
  final int year;
  final int month;
  final int day;

  const NepDate({required this.year, required this.month, required this.day});

  String get monthNameNepali => BikramSambatService.nepaliMonthNames[month - 1];
  String get monthNameEnglish =>
      BikramSambatService.englishMonthNames[month - 1];

  String formatBs() {
    final y = year.toString();
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d BS';
  }

  String formatFullNepali() {
    return '$day $monthNameNepali $year';
  }

  String formatFullEnglish() {
    return '$day $monthNameEnglish $year BS';
  }

  @override
  String toString() => formatBs();
}

class BikramSambatService {
  static const List<String> nepaliMonthNames = [
    'बैशाख',
    'जेठ',
    'असार',
    'श्रावण',
    'भाद्र',
    'असोज',
    'कार्तिक',
    'मंसिर',
    'पुष',
    'माघ',
    'फागुन',
    'चैत',
  ];

  static const List<String> englishMonthNames = [
    'Baisakh',
    'Jestha',
    'Ashadh',
    'Shrawan',
    'Bhadra',
    'Ashwin',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  static const List<String> dayNamesNepali = [
    'आइतबार',
    'सोमबार',
    'मंगलबार',
    'बुधबार',
    'बिहिबार',
    'शुक्रबार',
    'शनिबार',
  ];

  // Days in each month for BS years 2070 to 2090
  static const Map<int, List<int>> _bsCalendarData = {
    2070: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2071: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2072: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2073: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2074: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2075: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30],
    2076: [31, 32, 32, 31, 31, 30, 30, 30, 29, 30, 29, 31],
    2077: [31, 32, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2078: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 31],
    2079: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2080: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30], // 2023-2024
    2081: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 30], // 2024-2025
    2082: [31, 32, 32, 31, 31, 30, 30, 30, 29, 30, 29, 31], // 2025-2026
    2083: [31, 32, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30], // 2026-2027
    2084: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 31],
    2085: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2086: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2087: [31, 32, 31, 32, 31, 31, 30, 30, 29, 30, 29, 30],
    2088: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2089: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2090: [31, 32, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
  };

  // Base reference date: 2070 Baisakh 01 BS corresponds to 2013 April 14 AD
  static final DateTime _baseAdDate = DateTime(2013, 4, 14);
  static const int _baseBsYear = 2070;

  /// Converts Gregorian (AD) DateTime to Nepali (BS) NepDate
  static NepDate adToBs(DateTime adDate) {
    var diffDays = adDate.difference(_baseAdDate).inDays;

    if (diffDays < 0) {
      // Fallback for dates before 2070
      return const NepDate(year: 2070, month: 1, day: 1);
    }

    int currentYear = _baseBsYear;
    int currentMonth = 1;
    int currentDay = 1;

    while (diffDays > 0) {
      final monthDays = _bsCalendarData[currentYear];
      if (monthDays == null) {
        break; // Out of range, keep current
      }

      final daysInCurrentMonth = monthDays[currentMonth - 1];

      if (diffDays >= daysInCurrentMonth) {
        diffDays -= daysInCurrentMonth;
        currentMonth++;
        if (currentMonth > 12) {
          currentMonth = 1;
          currentYear++;
        }
      } else {
        currentDay += diffDays;
        diffDays = 0;
      }
    }

    return NepDate(year: currentYear, month: currentMonth, day: currentDay);
  }

  /// Converts Bikram Sambat (BS) date to Gregorian (AD) DateTime
  static DateTime bsToAd(int bsYear, int bsMonth, int bsDay) {
    if (bsYear < _baseBsYear || !_bsCalendarData.containsKey(bsYear)) {
      return _baseAdDate;
    }

    int totalDays = 0;

    // Add days for all preceding years
    for (int y = _baseBsYear; y < bsYear; y++) {
      final mDays = _bsCalendarData[y]!;
      for (final d in mDays) {
        totalDays += d;
      }
    }

    // Add days for preceding months of current year
    final currentYearMonths = _bsCalendarData[bsYear]!;
    for (int m = 1; m < bsMonth; m++) {
      totalDays += currentYearMonths[m - 1];
    }

    // Add day offset
    totalDays += (bsDay - 1);

    return _baseAdDate.add(Duration(days: totalDays));
  }

  /// Get total days in a specific BS month
  static int getDaysInBsMonth(int year, int month) {
    if (_bsCalendarData.containsKey(year) && month >= 1 && month <= 12) {
      return _bsCalendarData[year]![month - 1];
    }
    return 30;
  }

  /// Checks if NEPSE is open on the given AD date and time
  /// NEPSE operates Sunday to Thursday, 11:00 AM to 3:00 PM (NPT)
  static bool isNepseOpen([DateTime? targetDate]) {
    final now = targetDate ?? DateTime.now();
    // Sunday is 7 in DateTime.weekday, Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6
    final isTradingDay =
        now.weekday == DateTime.sunday ||
        (now.weekday >= DateTime.monday && now.weekday <= DateTime.thursday);

    if (!isTradingDay) return false;

    // Time window: 11:00 to 15:00
    final hour = now.hour;
    final minute = now.minute;
    final timeInMinutes = hour * 60 + minute;
    final openMinutes = 11 * 60;
    final closeMinutes = 15 * 60;

    return timeInMinutes >= openMinutes && timeInMinutes <= closeMinutes;
  }

  /// Get status text for NEPSE Market
  static String getNepseMarketStatus() {
    final now = DateTime.now();
    final isOpen = isNepseOpen(now);
    if (isOpen) {
      return 'MARKET OPEN (11:00 AM - 3:00 PM)';
    }

    if (now.weekday == DateTime.friday) {
      return 'MARKET CLOSED (Friday)';
    } else if (now.weekday == DateTime.saturday) {
      return 'MARKET CLOSED (Saturday Weekend)';
    }

    if (now.hour < 11) {
      return 'PRE-OPEN SESSION (Opens at 11:00 AM)';
    } else {
      return 'MARKET CLOSED (Closed at 3:00 PM)';
    }
  }
}
