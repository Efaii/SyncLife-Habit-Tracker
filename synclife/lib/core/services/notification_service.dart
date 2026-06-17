import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../models/habit_model.dart';
import '../../features/predictor/prediction_provider.dart';
import '../../features/profile/profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init({void Function(NotificationResponse)? onDidReceiveNotificationResponse}) async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  bool _isWithinQuietHours(DateTime target, UserProfile? profile) {
    if (profile == null) return false;
    final startStr = profile.quietHoursStart; 
    final endStr = profile.quietHoursEnd;     
    if (startStr == null || endStr == null) return false;

    final startHour = int.tryParse(startStr.split(':')[0]) ?? 22;
    final endHour = int.tryParse(endStr.split(':')[0]) ?? 6;
    
    final targetHour = target.hour;
    
    if (startHour > endHour) {
      return targetHour >= startHour || targetHour < endHour;
    } else {
      return targetHour >= startHour && targetHour < endHour;
    }
  }

  Future<void> scheduleSmartReminder(HabitModel habit, PredictionResult prediction, {UserProfile? profile}) async {
    final parts = habit.targetWaktu.split(':');
    if (parts.length != 2) return;
    
    final int hour = int.tryParse(parts[0]) ?? 8;
    final int minute = int.tryParse(parts[1]) ?? 0;

    var targetDate = DateTime.now().copyWith(hour: hour, minute: minute, second: 0);
    
    bool isUrgent = false;
    if (targetDate.isBefore(DateTime.now())) {
      // Target time passed, make it urgent and schedule for 1 min from now
      targetDate = DateTime.now().add(const Duration(minutes: 1));
      isUrgent = true;
    } else {
      targetDate = targetDate.subtract(const Duration(minutes: 30));
    }

    if (_isWithinQuietHours(targetDate, profile)) {
      return; // Suppress notification during quiet hours
    }

    String title = '';
    String body = '';

    if (isUrgent) {
      title = 'Peringatan: ${habit.namaHabit} Terlewat!';
      body = 'Waktu target sudah lewat, tapi belum terlambat! ';
    } else {
      title = 'Pengingat: ${habit.namaHabit}';
      body = 'Waktunya untuk habitmu! ';
    }

    if (prediction.percentage > 70) {
      body += 'Peluang suksesmu tinggi hari ini (AI: ${prediction.percentage.round()}%)! Ayo selesaikan.';
    } else {
      body += 'Kamu bisa melakukannya! AI merekomendasikan ekstra fokus hari ini.';
    }

    // Hashcode is used to ensure a unique ID per habit
    final int notificationId = habit.idHabit?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    await _notificationsPlugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(targetDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: habit.idHabit, // Deep Linking payload
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Recurring daily at this time
    );
    
    await _logNotification(title, body, habit.idHabit);
  }

  Future<void> scheduleStreakAlert(int currentStreak, {UserProfile? profile}) async {
    if (currentStreak == 0) return;

    // Schedule for 20:00 every day
    var targetDate = DateTime.now().copyWith(hour: 20, minute: 0, second: 0);
    if (targetDate.isBefore(DateTime.now())) {
      targetDate = targetDate.add(const Duration(days: 1));
    }

    if (_isWithinQuietHours(targetDate, profile)) {
      return;
    }

    await _notificationsPlugin.zonedSchedule(
      id: 999, // Unique ID for Streak Alert
      title: 'Streak Alert! 🔥',
      body: '$currentStreak hari konsisten tercapai. Selesaikan habitmu hari ini jangan sampai putus!',
      scheduledDate: tz.TZDateTime.from(targetDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_alerts',
          'Streak Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    
    await _logNotification('Streak Alert! 🔥', '$currentStreak hari konsisten tercapai. Selesaikan habitmu hari ini jangan sampai putus!', null);
  }

  Future<void> _logNotification(String title, String message, String? habitId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client.from('notifications_log').insert({
        'user_id': user.id,
        'title': title,
        'message': message,
        'habit_id': habitId,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
    } catch (e) {
      // Silent catch
    }
  }

  Future<void> cancelStreakAlert() async {
    await _notificationsPlugin.cancel(id: 999);
  }

  Future<void> cancelSmartReminders(List<HabitModel> habits) async {
    for (var habit in habits) {
      if (habit.idHabit != null) {
        await _notificationsPlugin.cancel(id: habit.idHabit.hashCode);
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
