import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final bool smartReminders;
  final bool streakAlerts;

  UserProfile({
    required this.id, 
    this.fullName, 
    this.avatarUrl, 
    this.bio,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.smartReminders = true,
    this.streakAlerts = true,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, {User? authUser}) {
    String? extractedName = map['full_name'];
    if (extractedName == null || extractedName.trim().isEmpty) {
      if (authUser != null) {
        extractedName = authUser.userMetadata?['full_name']?.toString();
        if ((extractedName == null || extractedName.trim().isEmpty) && authUser.email != null) {
          extractedName = authUser.email!.split('@')[0];
        }
      }
    }

    return UserProfile(
      id: map['id'],
      fullName: extractedName,
      avatarUrl: map['avatar_url'],
      bio: map['bio'],
      quietHoursStart: map['quiet_hours_start'],
      quietHoursEnd: map['quiet_hours_end'],
      smartReminders: map['smart_reminders'] ?? true,
      streakAlerts: map['streak_alerts'] ?? true,
    );
  }
}

class ProfileRepository {
  final SupabaseClient _client;
  ProfileRepository(this._client);

  Future<UserProfile?> getProfile(String userId, {User? authUser}) async {
    try {
      final data = await _client.from('profiles').select().eq('id', userId).single();
      return UserProfile.fromMap(data, authUser: authUser);
    } catch (e) {
      throw Exception('Gagal mengambil profil dari database. Pastikan RLS SELECT Policy sudah aktif: $e');
    }
  }

  Future<void> upsertProfile(String userId, {
    String? fullName, 
    String? avatarUrl, 
    String? bio,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? smartReminders,
    bool? streakAlerts,
  }) async {
    final updates = <String, dynamic>{
      'full_name': ?fullName,
      'avatar_url': ?avatarUrl,
      'bio': ?bio,
      'quiet_hours_start': ?quietHoursStart,
      'quiet_hours_end': ?quietHoursEnd,
      'smart_reminders': ?smartReminders,
      'streak_alerts': ?streakAlerts,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Use partial update if row exists to prevent null overwrites
    final existing = await _client.from('profiles').select('id').eq('id', userId).maybeSingle();
    if (existing != null) {
      await _client.from('profiles').update(updates).eq('id', userId);
    } else {
      updates['id'] = userId;
      await _client.from('profiles').insert(updates);
    }
  }
}

final profileRepositoryProvider = Provider((ref) => ProfileRepository(Supabase.instance.client));

final profileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  
  final repo = ref.read(profileRepositoryProvider);
  return await repo.getProfile(user.id, authUser: user);
});
