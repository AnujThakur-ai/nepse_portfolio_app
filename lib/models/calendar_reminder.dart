class CalendarReminder {
  final String id;
  final String title;
  final String description;
  final DateTime dateAD;
  final String dateBS;
  final String
  type; // 'HOLDING_TARGET', 'DIVIDEND', 'AGM', 'BOOK_CLOSURE', 'CUSTOM'
  final String? symbol;
  final bool isCompleted;
  final bool isNativeSyncEnabled;

  const CalendarReminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dateAD,
    required this.dateBS,
    required this.type,
    this.symbol,
    this.isCompleted = false,
    this.isNativeSyncEnabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateAD': dateAD.toIso8601String(),
      'dateBS': dateBS,
      'type': type,
      'symbol': symbol,
      'isCompleted': isCompleted,
      'isNativeSyncEnabled': isNativeSyncEnabled,
    };
  }

  factory CalendarReminder.fromJson(Map<String, dynamic> json) {
    return CalendarReminder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dateAD: DateTime.parse(json['dateAD'] as String),
      dateBS: json['dateBS'] as String? ?? '',
      type: json['type'] as String? ?? 'CUSTOM',
      symbol: json['symbol'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isNativeSyncEnabled: json['isNativeSyncEnabled'] as bool? ?? false,
    );
  }

  CalendarReminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateAD,
    String? dateBS,
    String? type,
    String? symbol,
    bool? isCompleted,
    bool? isNativeSyncEnabled,
  }) {
    return CalendarReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateAD: dateAD ?? this.dateAD,
      dateBS: dateBS ?? this.dateBS,
      type: type ?? this.type,
      symbol: symbol ?? this.symbol,
      isCompleted: isCompleted ?? this.isCompleted,
      isNativeSyncEnabled: isNativeSyncEnabled ?? this.isNativeSyncEnabled,
    );
  }
}
