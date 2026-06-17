import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationLog {
  final String id;
  final String title;
  final String message;
  final String? habitId;
  final DateTime createdAt;
  final bool isRead;

  NotificationLog({
    required this.id,
    required this.title,
    required this.message,
    this.habitId,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationLog.fromMap(Map<String, dynamic> map) {
    return NotificationLog(
      id: map['id'].toString(),
      title: map['title'] ?? 'Pengingat',
      message: map['message'] ?? '',
      habitId: map['habit_id']?.toString(),
      createdAt: DateTime.parse(map['created_at']),
      isRead: map['is_read'] ?? false,
    );
  }
}

final notificationHistoryProvider = FutureProvider.autoDispose<List<NotificationLog>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final response = await Supabase.instance.client
      .from('notifications_log')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return (response as List).map((e) => NotificationLog.fromMap(e)).toList();
});
