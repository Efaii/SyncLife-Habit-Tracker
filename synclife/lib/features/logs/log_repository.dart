import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/log_model.dart';

// Provider for LogRepository to be used with Riverpod
final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository(Supabase.instance.client);
});

class LogRepository {
  final SupabaseClient _supabase;

  LogRepository(this._supabase);

  static const String _tableName = 'logs';

  // CREATE
  Future<LogModel> createLog(LogModel log) async {
    final response = await _supabase
        .from(_tableName)
        .insert(log.toJson())
        .select()
        .single();
        
    return LogModel.fromJson(response);
  }

  // READ ALL
  Future<List<LogModel>> getLogs() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .order('timestamp', ascending: false);
    
    return response.map((json) => LogModel.fromJson(json)).toList();
  }

  // READ BY HABIT ID
  Future<List<LogModel>> getLogsByHabitId(String idHabit) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id_habit', idHabit)
        .order('timestamp', ascending: false);
    
    return response.map((json) => LogModel.fromJson(json)).toList();
  }

  // READ SINGLE
  Future<LogModel> getLogById(String idLog) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id_log', idLog)
        .single();
    
    return LogModel.fromJson(response);
  }

  // UPDATE
  Future<LogModel> updateLog(LogModel log) async {
    if (log.idLog == null) {
      throw Exception('Cannot update log without id_log');
    }
    
    final response = await _supabase
        .from(_tableName)
        .update(log.toJson())
        .eq('id_log', log.idLog!)
        .select()
        .single();
        
    return LogModel.fromJson(response);
  }

  // DELETE
  Future<void> deleteLog(String idLog) async {
    await _supabase
        .from(_tableName)
        .delete()
        .eq('id_log', idLog);
  }
}
