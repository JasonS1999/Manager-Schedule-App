class StoreHours {
  final int? id;
  final String openTime; // Format: HH:mm (e.g., "04:30")
  final String closeTime; // Format: HH:mm (e.g., "01:00")

  static const String defaultOpenTime = '04:30';
  static const String defaultCloseTime = '01:00';

  // Static cache for global access
  static StoreHours _cached = StoreHours.defaults();
  
  /// Get the cached store hours (synchronous access)
  static StoreHours get cached => _cached;
  
  /// Update the cache (call this after loading from DB)
  static void setCache(StoreHours hours) {
    _cached = hours;
  }

  StoreHours({
    this.id,
    required this.openTime,
    required this.closeTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }

  factory StoreHours.fromMap(Map<String, dynamic> map) {
    return StoreHours(
      id: map['id'] as int?,
      openTime: map['openTime'] as String,
      closeTime: map['closeTime'] as String,
    );
  }

  factory StoreHours.defaults() {
    return StoreHours(
      openTime: defaultOpenTime,
      closeTime: defaultCloseTime,
    );
  }

  StoreHours copyWith({
    int? id,
    String? openTime,
    String? closeTime,
  }) {
    return StoreHours(
      id: id ?? this.id,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  /// Parse time string to hour and minute
  static (int hour, int minute) parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Check if a given time matches the open time
  bool isOpenTime(int hour, int minute) {
    final (openHour, openMinute) = parseTime(openTime);
    return hour == openHour && minute == openMinute;
  }

  /// Check if a given time matches the close time
  bool isCloseTime(int hour, int minute) {
    final (closeHour, closeMinute) = parseTime(closeTime);
    return hour == closeHour && minute == closeMinute;
  }
}
