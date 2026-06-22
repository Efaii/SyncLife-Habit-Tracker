class LogModel {
  final String? idLog;
  final String? userId;
  final String? idHabit;
  final String? habitName;
  final DateTime? timestamp;
  final int moodLevel;
  final int busyLevel;
  final bool status;

  LogModel({
    this.idLog,
    this.userId,
    this.idHabit,
    this.habitName,
    this.timestamp,
    required this.moodLevel,
    required this.busyLevel,
    required this.status,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      idLog: json['id_log'] as String?,
      userId: json['user_id'] as String?,
      idHabit: json['id_habit'] as String?,
      habitName: json['habit_name'] as String?,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : null,
      moodLevel: (json['mood_level'] as num?)?.toInt() ?? 0,
      busyLevel: (json['busy_level'] as num?)?.toInt() ?? 0,
      status: json['status'] == true || json['status'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      if (idHabit != null) 'id_habit': idHabit,
      'mood_level': moodLevel,
      'busy_level': busyLevel,
      'status': status ? 1 : 0,
    };
    if (idLog != null) {
      data['id_log'] = idLog;
    }
    if (userId != null) {
      data['user_id'] = userId;
    }
    if (habitName != null) {
      data['habit_name'] = habitName;
    }
    if (timestamp != null) {
      data['timestamp'] = timestamp!.toIso8601String();
    }
    return data;
  }
}
