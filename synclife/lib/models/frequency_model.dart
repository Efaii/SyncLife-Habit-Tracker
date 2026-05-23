class FrequencyModel {
  final String? id;
  final String variableType;
  final String variableValue;
  final int countSuccess;
  final int countFail;

  FrequencyModel({
    this.id,
    required this.variableType,
    required this.variableValue,
    required this.countSuccess,
    required this.countFail,
  });

  factory FrequencyModel.fromJson(Map<String, dynamic> json) {
    return FrequencyModel(
      id: json['id'] as String?,
      variableType: json['variable_type'] as String,
      variableValue: json['variable_value'] as String,
      countSuccess: json['count_success'] as int,
      countFail: json['count_fail'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'variable_type': variableType,
      'variable_value': variableValue,
      'count_success': countSuccess,
      'count_fail': countFail,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}
