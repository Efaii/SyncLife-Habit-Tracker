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
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final insertPayload = {
      if (log.idHabit != null) 'id_habit': log.idHabit,
      if (log.habitName != null) 'habit_name': log.habitName,
      'user_id': userId,
      'mood_level': log.moodLevel,
      'busy_level': log.busyLevel,
      'status': log.status ? 1 : 0,
      if (log.timestamp != null) 'timestamp': log.timestamp!.toIso8601String(),
    };

    final response = await _supabase
        .from(_tableName)
        .insert(insertPayload)
        .select()
        .single();
        
    return LogModel.fromJson(response);
  }

  // DELETE TODAY LOG
  Future<void> deleteTodayLog(String idHabit) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

    await _supabase
        .from(_tableName)
        .delete()
        .eq('user_id', userId)
        .eq('id_habit', idHabit)
        .gte('timestamp', startOfDay)
        .lte('timestamp', endOfDay);
  }

  // READ ALL
  Future<List<LogModel>> getLogs() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .not('habit_name', 'is', null)
        .order('timestamp', ascending: false);
    
    return response.map((json) => LogModel.fromJson(json)).toList();
  }

  // READ BY HABIT ID
  Future<List<LogModel>> getLogsByHabitId(String idHabit) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id_habit', idHabit)
        .eq('user_id', userId)
        .not('habit_name', 'is', null)
        .order('timestamp', ascending: false);
    
    return response.map((json) => LogModel.fromJson(json)).toList();
  }

  // READ SINGLE
  Future<LogModel> getLogById(String idLog) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id_log', idLog)
        .eq('user_id', userId)
        .single();
        
    return LogModel.fromJson(response);
  }

  // DYNAMIC STREAK CALCULATION
  Future<int> calculateStreak(String habitId, String userId) async {
    final response = await _supabase
        .from(_tableName)
        .select('timestamp, status')
        .eq('id_habit', habitId)
        .eq('user_id', userId)
        .order('timestamp', ascending: false);

    if (response.isEmpty) return 0;

    final distinctDays = <DateTime>[];
    for (final row in response) {
      final status = row['status'];
      if (status == 1 || status == true) {
        if (row['timestamp'] != null) {
          final t = DateTime.parse(row['timestamp'].toString()).toLocal();
          final day = DateTime(t.year, t.month, t.day);
          if (!distinctDays.contains(day)) {
            distinctDays.add(day);
          }
        }
      } else {
        // If the user explicitly logged a failure, we might break the streak here 
        // depending on logic, but we'll stick to consecutive positive days.
      }
    }

    if (distinctDays.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    final newestLogDate = distinctDays.first;
    final diffToToday = todayDate.difference(newestLogDate).inDays;

    if (diffToToday > 1) {
      return 0; // Streak is already broken
    }

    int streakCount = 1;

    for (int i = 0; i < distinctDays.length - 1; i++) {
      final currentLogDate = distinctDays[i];
      final nextLogDate = distinctDays[i + 1];
      
      final differenceInDays = currentLogDate.difference(nextLogDate).inDays;

      if (differenceInDays == 1) {
        streakCount++;
      } else if (differenceInDays == 0) {
        continue;
      } else {
        break; // A gap of > 1 day occurred, stop counting
      }
    }

    return streakCount;
  }

  // UPDATE
  Future<LogModel> updateLog(LogModel log) async {
    if (log.idLog == null) {
      throw Exception('Cannot update log without id_log');
    }
    
    final updatePayload = {
      if (log.idHabit != null) 'id_habit': log.idHabit,
      'mood_level': log.moodLevel,
      'busy_level': log.busyLevel,
      'status': log.status ? 1 : 0,
      if (log.timestamp != null) 'timestamp': log.timestamp!.toIso8601String(),
    };

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase
        .from(_tableName)
        .update(updatePayload)
        .eq('id_log', log.idLog!)
        .eq('user_id', userId)
        .select()
        .single();
        
    return LogModel.fromJson(response);
  }

  // DELETE
  Future<void> deleteLog(String idLog) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase
        .from(_tableName)
        .delete()
        .eq('id_log', idLog)
        .eq('user_id', userId);
  }
  Future<void> deleteLogsByHabitId(String idHabit) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

  await _supabase
      .from(_tableName)
      .delete()
      .eq('id_habit', idHabit)
      .eq('user_id', userId);
  }
}
