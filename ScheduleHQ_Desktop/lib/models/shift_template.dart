class ShiftTemplate {
  final int? id;
  final String templateName;
  final String startTime; // HH:MM format
  final String endTime;   // HH:MM format

  ShiftTemplate({
    this.id,
    required this.templateName,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateName': templateName,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory ShiftTemplate.fromMap(Map<String, dynamic> map) {
    return ShiftTemplate(
      id: map['id'] as int?,
      templateName: map['templateName'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String? ?? '17:00',
    );
  }

  ShiftTemplate copyWith({
    int? id,
    String? templateName,
    String? startTime,
    String? endTime,
  }) {
    return ShiftTemplate(
      id: id ?? this.id,
      templateName: templateName ?? this.templateName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
