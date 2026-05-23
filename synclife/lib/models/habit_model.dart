class HabitModel {
  final String? idHabit;
  final String namaHabit;
  final String ikon;
  final String targetWaktu;
  final String warnaTag;
  final DateTime? createdAt;

  HabitModel({
    this.idHabit,
    required this.namaHabit,
    required this.ikon,
    required this.targetWaktu,
    required this.warnaTag,
    this.createdAt,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      idHabit: json['id_habit'] as String?,
      namaHabit: json['nama_habit'] as String,
      ikon: json['ikon'] as String,
      targetWaktu: json['target_waktu'] as String,
      warnaTag: json['warna_tag'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'nama_habit': namaHabit,
      'ikon': ikon,
      'target_waktu': targetWaktu,
      'warna_tag': warnaTag,
    };
    if (idHabit != null) {
      data['id_habit'] = idHabit;
    }
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String();
    }
    return data;
  }
}
