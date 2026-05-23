import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/frequency_model.dart';

// Provider for FrequencyRepository to be used with Riverpod
final frequencyRepositoryProvider = Provider<FrequencyRepository>((ref) {
  return FrequencyRepository(Supabase.instance.client);
});

class FrequencyRepository {
  final SupabaseClient _supabase;

  FrequencyRepository(this._supabase);

  static const String _tableName = 'frequency';

  // GET ALL FREQUENCIES
  Future<List<FrequencyModel>> getFrequencies() async {
    final response = await _supabase.from(_tableName).select();
    return response.map((json) => FrequencyModel.fromJson(json)).toList();
  }

  // GET FREQUENCY BY TYPE AND VALUE
  Future<FrequencyModel?> getFrequency(String variableType, String variableValue) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('variable_type', variableType)
        .eq('variable_value', variableValue)
        .maybeSingle();
        
    if (response == null) return null;
    return FrequencyModel.fromJson(response);
  }

  // UPSERT FREQUENCY (INCREMENT SUCCESS/FAIL)
  Future<FrequencyModel> incrementFrequency({
    required String variableType,
    required String variableValue,
    required bool isSuccess,
  }) async {
    // 1. Check if record exists
    final existing = await getFrequency(variableType, variableValue);

    if (existing != null) {
      // 2. Update existing record
      final newSuccessCount = isSuccess ? existing.countSuccess + 1 : existing.countSuccess;
      final newFailCount = !isSuccess ? existing.countFail + 1 : existing.countFail;

      final response = await _supabase
          .from(_tableName)
          .update({
            'count_success': newSuccessCount,
            'count_fail': newFailCount,
          })
          .eq('id', existing.id!)
          .select()
          .single();

      return FrequencyModel.fromJson(response);
    } else {
      // 3. Create new record if it doesn't exist
      final newRecord = FrequencyModel(
        variableType: variableType,
        variableValue: variableValue,
        countSuccess: isSuccess ? 1 : 0,
        countFail: !isSuccess ? 1 : 0,
      );

      final response = await _supabase
          .from(_tableName)
          .insert(newRecord.toJson())
          .select()
          .single();

      return FrequencyModel.fromJson(response);
    }
  }
}
