import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/dashboard_screen.dart';
import '../home/main_screen.dart';
import '../statistics/statistics_screen.dart';
import '../predictor/prediction_provider.dart';
import '../../models/habit_model.dart';
import '../../utils/ui_helper.dart';

enum NotificationRoute {
  dashboard,
  habits,
  statistics,
}

class NotificationItem {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String? habitId;
  final NotificationRoute routeTarget;
  final DateTime timestamp;
  final String type;

  NotificationItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.timestamp,
    required this.type,
    this.habitId,
    this.routeTarget = NotificationRoute.dashboard,
  });
}

class NotificationHistoryScreen extends ConsumerWidget {
  const NotificationHistoryScreen({super.key});

  List<NotificationItem> _generateNotifications(
    List<HabitModel> activeHabits, 
    Set<String> completedIds, 
    Map<String, int> habitStreaks,
    PredictionResult? prediction,
  ) {
    List<NotificationItem> reminders = [];
    List<NotificationItem> insights = [];
    final now = DateTime.now();

    // 1. Prediction Insight Alert (selalu tambahkan jika ada prediksi)
    if (prediction != null) {
      if (prediction.percentage < 40.0) {
        insights.add(NotificationItem(
          title: 'Insight Prediksi',
          message: 'Peluang sukses hari ini cukup rendah. Fokus pada habit prioritasmu!',
          icon: Icons.lightbulb_outline,
          color: Colors.deepPurple,
          timestamp: now.subtract(const Duration(minutes: 30)),
          type: 'prediction_insight',
          routeTarget: NotificationRoute.dashboard,
        ));
      } else {
        insights.add(NotificationItem(
          title: 'Insight Prediksi',
          message: 'Peluang suksesmu tinggi hari ini! Pertahankan ritme belajarmu.',
          icon: Icons.auto_awesome_rounded,
          color: Colors.deepPurple,
          timestamp: now.subtract(const Duration(minutes: 30)),
          type: 'prediction_insight',
          routeTarget: NotificationRoute.dashboard,
        ));
      }
    }

    // 2. Weekly Stats Recap
    if (now.weekday == DateTime.sunday && now.hour >= 17) {
      insights.add(NotificationItem(
        title: 'Rekap Mingguan',
        message: 'Statistik mingguanmu sudah siap! Cek habit terkuatmu minggu ini.',
        icon: Icons.bar_chart_rounded,
        color: Colors.indigo,
        timestamp: now.subtract(const Duration(hours: 1)),
        type: 'statistics_recap',
        routeTarget: NotificationRoute.statistics,
      ));
    }

    // 3. Reminders
    for (var i = 0; i < activeHabits.length; i++) {
      var habit = activeHabits[i];
      if (habit.idHabit == null) continue;
      final isCompletedToday = completedIds.contains(habit.idHabit);
      final streak = habitStreaks[habit.idHabit!] ?? 0;
      
      // Kasih timestamp yang berbeda-beda sedikit agar urutan terlihat natural
      final itemTime = now.subtract(Duration(hours: 2, minutes: i * 15));

      if (!isCompletedToday) {
        if (streak > 0) {
          reminders.add(NotificationItem(
            title: 'Awas Streak Putus!',
            message: 'Hati-hati, streak $streak hari untuk "${habit.namaHabit}" kamu terancam putus!',
            icon: Icons.warning_rounded,
            color: Colors.orange,
            habitId: habit.idHabit!,
            timestamp: itemTime,
            type: 'habit_reminder',
            routeTarget: NotificationRoute.habits,
          ));
        } else {
          reminders.add(NotificationItem(
            title: 'Pengingat Habit',
            message: 'Jangan lupa selesaikan "${habit.namaHabit}" hari ini!',
            icon: Icons.notifications_active_rounded,
            color: Colors.blue,
            habitId: habit.idHabit!,
            timestamp: itemTime,
            type: 'habit_reminder',
            routeTarget: NotificationRoute.habits,
          ));
        }
      } else {
        final milestoneDays = [3, 7, 14, 21, 30, 50, 100, 365];
        if (milestoneDays.contains(streak)) {
          reminders.add(NotificationItem(
            title: 'Pencapaian Luar Biasa!',
            message: 'Hebat! Kamu berhasil mencapai streak $streak hari untuk "${habit.namaHabit}"!',
            icon: Icons.emoji_events_rounded,
            color: Colors.amber.shade600,
            habitId: habit.idHabit!,
            timestamp: itemTime,
            type: 'habit_reminder',
            routeTarget: NotificationRoute.habits,
          ));
        }
      }
    }

    // COMBINE AND SORT THE LISTS
    List<NotificationItem> allNotifications = [...reminders, ...insights];
    allNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return allNotifications;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    final habitsAsync = ref.watch(habitsProvider);
    final completedAsync = ref.watch(todayCompletedHabitsProvider);
    final statsAsync = ref.watch(statisticsProvider);
    final predictionAsync = ref.watch(predictionProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Riwayat Notifikasi',
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: habitsAsync.when(
        data: (habits) {
          return completedAsync.when(
            data: (completedIds) {
              return statsAsync.when(
                data: (stats) {
                  final prediction = predictionAsync.whenOrNull(data: (p) => p);
                  final allNotifications = _generateNotifications(habits, completedIds, stats.habitStreaks, prediction);
                  
                  if (allNotifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_rounded, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Semua aman!',
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tidak ada pengingat untuk saat ini.',
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: allNotifications.length,
                    itemBuilder: (context, index) {
                      final notif = allNotifications[index];

                      // RENDER UNIFIED LISTVIEW: Dynamic styling based on notification.type
                      BoxDecoration iconDecoration;
                      if (notif.type == 'habit_reminder') {
                        iconDecoration = BoxDecoration(
                          color: notif.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        );
                      } else if (notif.type == 'prediction_insight' || notif.type == 'statistics_recap') {
                        iconDecoration = BoxDecoration(
                          color: notif.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        );
                      } else {
                        iconDecoration = BoxDecoration(
                          color: notif.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        );
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        elevation: 0,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            if (notif.routeTarget == NotificationRoute.statistics) {
                              ref.read(bottomNavIndexProvider.notifier).setIndex(2);
                            } else if (notif.routeTarget == NotificationRoute.habits) {
                              ref.read(bottomNavIndexProvider.notifier).setIndex(1);
                            } else {
                              ref.read(bottomNavIndexProvider.notifier).setIndex(0);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: iconDecoration,
                                  child: Icon(notif.icon, color: notif.color),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif.title,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold, 
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.message,
                                        style: GoogleFonts.inter(color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${notif.timestamp.hour.toString().padLeft(2, '0')}:${notif.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: textColor))),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: textColor))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: textColor))),
      ),
    );
  }
}
