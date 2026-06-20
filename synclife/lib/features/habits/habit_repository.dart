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
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final habitData = habit.toJson();
    habitData['user_id'] = userId;

    final response = await _supabase
        .from(_tableName)
        .insert(habitData)
        .select()
        .single();
        
    return HabitModel.fromJson(response);
  }

  // READ ALL
  Future<List<HabitModel>> getHabits() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false);
    
    return response.map((json) => HabitModel.fromJson(json)).toList();
  }

  // REALTIME STREAM
  Stream<List<HabitModel>> watchHabits() {
    final userId = _supabase.auth.currentUser?.id;
    print('--- FETCHING HABITS STREAM ---');
    print('Current Auth UID: $userId');
    if (userId == null) return const Stream.empty();

    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id_habit'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map(
          (data) {
            print('Fetched Data Count: ${data.length}');
            return data
                .where((json) => json['is_deleted'] == false || json['is_deleted'] == null)
                .map((json) => HabitModel.fromJson(json))
                .toList();
          },
        );
  }

  // READ SINGLE
  Future<HabitModel> getHabitById(String idHabit) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('id_habit', idHabit)
        .eq('user_id', userId)
        .single();
    
    return HabitModel.fromJson(response);
  }

  // UPDATE
  Future<HabitModel> updateHabit(HabitModel habit) async {
    if (habit.idHabit == null) {
      throw Exception('Cannot update habit without id_habit');
    }
    
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final response = await _supabase
        .from(_tableName)
        .update(habit.toJson())
        .eq('id_habit', habit.idHabit!)
        .eq('user_id', userId)
        .select()
        .single();
        
    return HabitModel.fromJson(response);
  }

  // DELETE
  Future<void> deleteHabit(String idHabit) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _supabase
        .from(_tableName)
        .update({'is_deleted': true})
        .eq('id_habit', idHabit)
        .eq('user_id', userId);
  }
}
