class LogModel {
  final String? idLog;
  final String idHabit;
  final DateTime? timestamp;
  final int moodLevel;
  final int busyLevel;
  final bool status;

  LogModel({
    this.idLog,
    required this.idHabit,
    this.timestamp,
    required this.moodLevel,
    required this.busyLevel,
    required this.status,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      idLog: json['id_log'] as String?,
      idHabit: json['id_habit'] as String,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : null,
      moodLevel: json['mood_level'] as int,
      busyLevel: json['busy_level'] as int,
      status: json['status'] is bool ? json['status'] as bool : (json['status'] == 1),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id_habit': idHabit,
      'mood_level': moodLevel,
      'busy_level': busyLevel,
      'status': status ? 1 : 0,
    };
    if (idLog != null) {
      data['id_log'] = idLog;
    }
    if (timestamp != null) {
      data['timestamp'] = timestamp!.toIso8601String();
    }
    return data;
  }
}
