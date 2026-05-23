import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/habit_model.dart';

// Provider for HabitRepository to be used with Riverpod
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(Supabase.instance.client);
});

class HabitRepository {
  final SupabaseClient _supabase;

  HabitRepository(this._supabase);

  // Table name constant
  static const String _tableName = 'habits';

  // CREATE
  Future<HabitModel> createHabit(HabitModel habit) async {
    final response = await _supabase
        .from(_tableName)
        .insert(habit.toJson())
        .select()
        .single();
        
    return HabitModel.fromJson(response);
  }

  // READ ALL
  Future<List<HabitModel>> getHabits() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .order('created_at', ascending: false);
    
    return response.map((json) => HabitModel.fromJson(json)).toList();
  }

  // READ SINGLE
  Future<HabitModel> getHabitById(String idHabit) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id_habit', idHabit)
        .single();
    
    return HabitModel.fromJson(response);
  }

  // UPDATE
  Future<HabitModel> updateHabit(HabitModel habit) async {
    if (habit.idHabit == null) {
      throw Exception('Cannot update habit without id_habit');
    }
    
    final response = await _supabase
        .from(_tableName)
        .update(habit.toJson())
        .eq('id_habit', habit.idHabit!)
        .select()
        .single();
        
    return HabitModel.fromJson(response);
  }

  // DELETE
  Future<void> deleteHabit(String idHabit) async {
    await _supabase
        .from(_tableName)
        .delete()
        .eq('id_habit', idHabit);
  }
}
