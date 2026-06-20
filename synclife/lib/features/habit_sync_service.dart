import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import 'profile/profile_provider.dart';

import 'habits/habit_repository.dart';
import 'logs/log_repository.dart';
import 'home/dashboard_screen.dart';
import 'statistics/statistics_screen.dart';
import 'predictor/prediction_provider.dart';
import '../models/log_model.dart';
import 'notifications/notification_history_screen.dart';

final habitSyncServiceProvider = Provider<HabitSyncService>((ref) {
  return HabitSyncService(ref);
});

/// HabitSyncService acts as the single source of truth controller
/// ensuring that when a habit is updated or logged, all relevant
/// screens (HabitsScreen -> Execution, StatisticsScreen -> Evaluation)
/// are perfectly synced without redundant fetching.
class HabitSyncService {
  final Ref _ref;

  HabitSyncService(this._ref);

  Future<void> submitHabitLog(LogModel log) async {
    final logRepo = _ref.read(logRepositoryProvider);
    
    // Save to database
    await logRepo.createLog(log);

    // SMART SYNC: Instantly refresh both Action (Today) and Insight (Journey) states
    _ref.invalidate(todayCompletedHabitsProvider);
    _ref.invalidate(habitsProvider);
    _ref.invalidate(statisticsProvider);
    _ref.invalidate(predictionProvider);
    _ref.invalidate(notificationLogsProvider);
    _scheduleBackgroundTasks();
  }

  Future<void> removeTodayLog(String habitId) async {
    final logRepo = _ref.read(logRepositoryProvider);
    
    // Remove from database
    await logRepo.deleteTodayLog(habitId);

    // SMART SYNC: Instantly refresh both Action (Today) and Insight (Journey) states
    _ref.invalidate(todayCompletedHabitsProvider);
    _ref.invalidate(habitsProvider);
    _ref.invalidate(statisticsProvider);
    _ref.invalidate(predictionProvider);
    _ref.invalidate(notificationLogsProvider);
    _scheduleBackgroundTasks();
  }

  Future<void> deleteHabit(String habitId) async {
    final habitRepo = _ref.read(habitRepositoryProvider);
    
    // Remove from database
    await habitRepo.deleteHabit(habitId);

    // SMART SYNC: Instantly refresh both Action (Today) and Insight (Journey) states
    _ref.invalidate(todayCompletedHabitsProvider);
    _ref.invalidate(habitsProvider);
    _ref.invalidate(statisticsProvider);
    _ref.invalidate(predictionProvider);
    _scheduleBackgroundTasks();
  }

  void _scheduleBackgroundTasks() {
    // Give riverpod time to invalidate and fetch new data, then update notifications
    Future.delayed(const Duration(seconds: 2), () async {
      await updateNotifications();
    });
  }

  Future<void> updateNotifications() async {
    try {
      final profile = await _ref.read(profileProvider.future);
      if (profile == null) return;

      final habits = await _ref.read(habitsProvider.future);
      final completedIds = await _ref.read(todayCompletedHabitsProvider.future);
      final stats = await _ref.read(statisticsProvider.future);
      final prediction = await _ref.read(predictionProvider.future);

      // 1. Streak Alerts
      if (profile.streakAlerts == true) {
        await NotificationService().cancelStreakAlert(habits); // Reset all first
        for (var habit in habits) {
          if (!completedIds.contains(habit.idHabit)) {
            // Has incomplete habit -> schedule streak alert for 20:00 today
            await NotificationService().scheduleStreakAlert(habit, profile: profile);
          }
        }
      } else {
        await NotificationService().cancelStreakAlert(habits);
      }

      // 2. Smart Reminders
      if (profile.smartReminders == true) {
        // Cancel all existing to avoid duplicates
        await NotificationService().cancelSmartReminders(habits.toList());
        // Re-schedule for incomplete habits
        for (var habit in habits) {
          if (!completedIds.contains(habit.idHabit)) {
            await NotificationService().scheduleSmartReminder(habit, prediction, profile: profile);
          }
        }
      } else {
        await NotificationService().cancelSmartReminders(habits.toList());
      }
    } catch (e) {
      // Silent catch for background task
    }
  }
}
