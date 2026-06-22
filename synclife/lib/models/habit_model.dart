class HabitModel {
  final String? idHabit;
  final String? userId;
  final String namaHabit;
  final String ikon;
  final String targetWaktu;
  final String warnaTag;
  final bool isDeleted;
  final DateTime? createdAt;

  HabitModel({
    this.idHabit,
    this.userId,
    required this.namaHabit,
    required this.ikon,
    required this.targetWaktu,
    required this.warnaTag,
    this.isDeleted = false,
    this.createdAt,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      idHabit: json['id_habit'] as String?,
      userId: json['user_id'] as String?,
      namaHabit: json['nama_habit'] as String? ?? 'Unknown',
      ikon: json['ikon'] as String? ?? '58502',
      targetWaktu: json['target_waktu'] as String? ?? '00:00',
      warnaTag: json['warna_tag'] as String? ?? '#000000',
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'nama_habit': namaHabit,
      'ikon': ikon,
      'target_waktu': targetWaktu,
      'warna_tag': warnaTag,
      'is_deleted': isDeleted,
    };
    if (idHabit != null) {
      data['id_habit'] = idHabit;
    }
    if (userId != null) {
      data['user_id'] = userId;
    }
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }
    return data;
  }
}
