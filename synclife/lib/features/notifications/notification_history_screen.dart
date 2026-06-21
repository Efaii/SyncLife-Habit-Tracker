import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/dashboard_screen.dart';
import '../home/main_screen.dart';
import '../statistics/statistics_screen.dart';
import '../predictor/prediction_provider.dart';
import '../logs/log_repository.dart';
import '../../models/habit_model.dart';
import '../../models/log_model.dart';
import '../logs/context_bottom_sheet.dart';
import 'notification_history_provider.dart';

enum NotificationRoute {
  dashboard,
  habits,
  statistics,
}

final notificationLogsProvider = FutureProvider.autoDispose<List<LogModel>>((ref) async {
  return await ref.read(logRepositoryProvider).getLogs();
});

class NotificationItem {
  final String? id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String? habitId;
  final NotificationRoute routeTarget;
  final DateTime timestamp;
  final String type;

  NotificationItem({
    this.id,
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

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends ConsumerState<NotificationHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  (List<NotificationItem>, List<NotificationItem>) _generateNotifications(
      List<HabitModel> habits, 
      Set<String> completedIds, 
      Map<String, int> habitStreaks,
      PredictionResult? prediction,
      List<LogModel>? logs) {
    
    final active = <NotificationItem>[];
    final history = <NotificationItem>[];
    final now = DateTime.now();

    // 1. Prediction Insight Alert (History)
    if (prediction != null && prediction.loggedDaysCount >= 7) {
      if (prediction.percentage < 40.0) {
        history.add(NotificationItem(
          title: 'Insight Prediksi',
          message: 'Berdasarkan pola harianmu, peluang sukses menyelesaikan target hari ini sekitar ${prediction.percentage.round()}%. Yuk, siapkan waktu khusus dan kurangi distraksi!',
          icon: Icons.lightbulb_outline,
          color: Colors.deepPurple,
          timestamp: now.subtract(const Duration(minutes: 30)),
          type: 'prediction_insight',
          routeTarget: NotificationRoute.dashboard,
        ));
      } else {
        history.add(NotificationItem(
          title: 'Insight Prediksi',
          message: 'Luar biasa! Peluang suksesmu mencapai ${prediction.percentage.round()}% hari ini. Berdasarkan datamu, ini adalah momentum terbaik untuk bertindak!',
          icon: Icons.auto_awesome_rounded,
          color: Colors.deepPurple,
          timestamp: now.subtract(const Duration(minutes: 30)),
          type: 'prediction_insight',
          routeTarget: NotificationRoute.dashboard,
        ));
      }
    }

    // 2. Weekly Stats Recap (History)
    if (now.weekday == DateTime.sunday && now.hour >= 17) {
      history.add(NotificationItem(
        title: 'Rekap Mingguan',
        message: 'Statistik mingguanmu sudah siap! Cek habit terkuatmu minggu ini.',
        icon: Icons.bar_chart_rounded,
        color: Colors.indigo,
        timestamp: now.subtract(const Duration(hours: 1)),
        type: 'statistics_recap',
        routeTarget: NotificationRoute.statistics,
      ));
    }

    // 3. Reminders & Milestones
    for (var i = 0; i < habits.length; i++) {
      var habit = habits[i];
      if (habit.idHabit == null) continue;
      final isCompletedToday = completedIds.contains(habit.idHabit);
      final streak = habitStreaks[habit.idHabit!] ?? 0;
      
      final itemTime = now.subtract(Duration(hours: 2, minutes: i * 15));

      if (!isCompletedToday) {
        // Belum selesai -> Masuk tab Aktif
        if (streak > 0) {
          active.add(NotificationItem(
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
          active.add(NotificationItem(
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
        // Sudah selesai -> Masuk tab History (khusus milestone)
        final milestoneDays = [3, 7, 14, 21, 30, 50, 100, 365];
        if (milestoneDays.contains(streak)) {
          history.add(NotificationItem(
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

    // 4. Fetch User Logs from DB (History)
    if (logs != null) {
      for (final log in logs) {
        String habitName = log.habitName ?? 'Tidak Diketahui';
        try {
          habitName = habits.firstWhere((h) => h.idHabit == log.idHabit).namaHabit;
        } catch (_) {}

        history.add(NotificationItem(
          title: 'Aktivitas Dicatat',
          message: 'Kamu menyelesaikan habit "$habitName" hari ini.',
          icon: Icons.history_rounded,
          color: Colors.green,
          habitId: log.idHabit,
          timestamp: log.timestamp ?? DateTime.now(),
          type: 'log_history',
          routeTarget: NotificationRoute.statistics,
        ));
      }
    }

    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    active.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return (active, history);
  }

  Widget _buildEmptyState(BuildContext context, bool isActive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? Icons.task_alt_rounded : Icons.history_rounded, 
            size: 80, 
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            isActive ? 'Semua beres!' : 'Belum ada riwayat',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isActive 
                  ? 'Kamu telah menyelesaikan semua targetmu hari ini. Pertahankan prestasimu!'
                  : 'Riwayat pencapaian dan insight AI akan muncul di sini seiring berjalannya waktu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 15, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItem> items, List<HabitModel> habits, bool isDarkMode, Color textColor) {
    if (items.isEmpty) {
      // Return empty state but wrapped in a widget to allow AnimatedSwitcher to see it as a different child type
      return _buildEmptyState(context, _tabController.index == 0);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final notif = items[index];

        BoxDecoration iconDecoration;
        if (notif.type == 'habit_reminder') {
          iconDecoration = BoxDecoration(
            color: notif.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          );
        } else {
          iconDecoration = BoxDecoration(
            color: notif.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          );
        }

        final cardWidget = Card(
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
                          style: GoogleFonts.inter(color: Colors.grey.shade600, height: 1.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${notif.timestamp.hour.toString().padLeft(2, '0')}:${notif.timestamp.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (notif.type == 'habit_reminder' && _tabController.index == 0)
                    Icon(Icons.swipe_left_rounded, color: Colors.grey.shade300)
                  else
                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
                ],
              ),
            ),
          ),
        );

        // Jika ini di tab Aktif dan tipe habit_reminder, bungkus dengan Dismissible
        if (notif.type == 'habit_reminder' && _tabController.index == 0) {
          return Dismissible(
            key: Key('dismiss_${notif.habitId}_${notif.timestamp.millisecondsSinceEpoch}'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24.0),
              decoration: BoxDecoration(
                color: Colors.green.shade500,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Tandai Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              if (notif.habitId != null) {
                try {
                  final habit = habits.firstWhere((h) => h.idHabit == notif.habitId);
                  final result = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ContextBottomSheet(
                      habitId: habit.idHabit!,
                      habitName: habit.namaHabit,
                    ),
                  );
                  return result == true;
                } catch (_) {
                  return false;
                }
              }
              return false;
            },
            onDismissed: (direction) {
              // Invalidate state providers so the UI rebuilds with the new completed habit
              ref.invalidate(todayCompletedHabitsProvider);
              ref.invalidate(notificationLogsProvider);
              
              if (notif.id != null) {
                // Delete from State and Supabase
                ref.read(notificationHistoryProvider.notifier).removeNotification(notif.id!);
              }
            },
            child: cardWidget,
          );
        }

        return cardWidget;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    final habitsAsync = ref.watch(habitsProvider);
    final completedAsync = ref.watch(todayCompletedHabitsProvider);
    final statsAsync = ref.watch(statisticsProvider);
    final predictionAsync = ref.watch(predictionProvider);
    final logsAsync = ref.watch(notificationLogsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Pusat Notifikasi',
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: habitsAsync.when(
        data: (habits) {
          return completedAsync.when(
            data: (completedIds) {
              return statsAsync.when(
                data: (stats) {
                  return logsAsync.when(
                    data: (logs) {
                      final prediction = predictionAsync.whenOrNull(data: (p) => p);
                      final (activeItems, historyItems) = _generateNotifications(habits, completedIds, stats.habitStreaks, prediction, logs);
                      
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Aktif
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildNotificationList(activeItems, habits, isDarkMode, textColor),
                          ),
                          // Tab 2: Riwayat
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _buildNotificationList(historyItems, habits, isDarkMode, textColor),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Gagal memuat log.', style: TextStyle(color: textColor))),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Gagal memuat stats.', style: TextStyle(color: textColor))),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Gagal memuat kebiasaan.', style: TextStyle(color: textColor))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Gagal memuat profil.', style: TextStyle(color: textColor))),
      ),
    );
  }
}
