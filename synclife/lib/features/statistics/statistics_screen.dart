import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../logs/log_repository.dart';
import '../habits/habit_repository.dart';
import '../../models/habit_model.dart';
import '../../utils/ui_helper.dart';
import 'habit_history_screen.dart';
import '../home/dashboard_screen.dart';

// Composite class to hold statistics
class StatisticsData {
  final int currentStreak;
  final String topHabitName;
  final List<int> weeklyConsistency;
  final String? topProductiveDay;
  final double avgMood;
  final double successRate;
  final String smartInsight;
  final List<HabitModel> habits; 
  final Map<String, int> habitCounts;
  final Map<String, int> habitStreaks;

  StatisticsData({
    required this.currentStreak,
    required this.topHabitName,
    required this.weeklyConsistency,
    this.topProductiveDay,
    required this.avgMood,
    required this.successRate,
    required this.smartInsight,
    required this.habits,
    required this.habitCounts,
    required this.habitStreaks,
  });
}

final statisticsProvider = FutureProvider<StatisticsData>((ref) async {
  final logRepo = ref.watch(logRepositoryProvider);
  final habitRepo = ref.watch(habitRepositoryProvider);

  final allLogs = await logRepo.getLogs();
  final habits = await ref.watch(habitsProvider.future);

  final activeHabitIds = habits.map((h) => h.idHabit).toSet();
  final logs = allLogs.where((log) => activeHabitIds.contains(log.idHabit)).toList();

  if (logs.isEmpty) {
    return StatisticsData(
      currentStreak: 0,
      topHabitName: 'Belum Ada Data',
      weeklyConsistency: List.filled(7, 0),
      avgMood: 0,
      successRate: 0,
      smartInsight: 'Belum cukup data untuk memberikan insight. Tetap semangat!',
      habits: habits,
      habitCounts: {},
      habitStreaks: {},
    );
  }

  // 1. Top Habit
  final habitCounts = <String, int>{};
  final habitLatestLog = <String, DateTime>{};

  for (var log in logs) {
    if (log.status && log.idHabit != null) {
      final id = log.idHabit!;
      habitCounts[id] = (habitCounts[id] ?? 0) + 1;
      
      if (log.timestamp != null) {
        if (!habitLatestLog.containsKey(id) || log.timestamp!.isAfter(habitLatestLog[id]!)) {
          habitLatestLog[id] = log.timestamp!;
        }
      }
    }
  }

  String topHabitName = 'Belum Ada Data';
  if (habitCounts.isNotEmpty) {
    var entries = habitCounts.entries.toList();
    entries.sort((a, b) {
      final countCompare = b.value.compareTo(a.value);
      if (countCompare != 0) return countCompare; // Sort by completions descending
      
      // Tie-breaker: sort by last completed timestamp descending
      final dateA = habitLatestLog[a.key] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = habitLatestLog[b.key] ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    
    for (var entry in entries) {
      var topHabit = habits.where((h) => h.idHabit == entry.key).firstOrNull;
      if (topHabit != null) {
        topHabitName = topHabit.namaHabit;
        break;
      }
    }
    if (topHabitName == 'Belum Ada Data') {
      topHabitName = 'Belum ada data';
    }
  } else {
    topHabitName = 'Belum ada data';
  }

  // 2. Weekly Consistency
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weeklyConsistency = List.filled(7, 0);
  final daysWithLogs = <DateTime>{};

  for (var log in logs) {
    if (log.timestamp == null) continue;
    final logDate = DateTime(log.timestamp!.year, log.timestamp!.month, log.timestamp!.day);
    if (log.status) {
      daysWithLogs.add(logDate);
      final difference = todayStart.difference(logDate).inDays;
      if (difference >= 0 && difference < 7) {
        weeklyConsistency[6 - difference]++;
      }
    }
  }

  // 3. Streak
  int currentStreak = 0;
  for (int i = 0; i < 365; i++) {
    final checkDate = todayStart.subtract(Duration(days: i));
    if (daysWithLogs.contains(checkDate)) {
      currentStreak++;
    } else {
      if (i == 0) continue;
      break;
    }
  }

  final habitStreaks = <String, int>{};
  for (var habitId in activeHabitIds) {
    if (habitId == null) continue;
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final checkDate = todayStart.subtract(Duration(days: i));
      final hasLog = logs.any((l) => l.idHabit == habitId && l.status && l.timestamp != null && 
        DateTime(l.timestamp!.year, l.timestamp!.month, l.timestamp!.day).isAtSameMomentAs(checkDate));
      if (hasLog) {
        streak++;
      } else {
        if (i == 0) continue; 
        break;
      }
    }
    habitStreaks[habitId] = streak;
  }

  // 4. Top Productive Day
  String? topProductiveDay;
  final dayCounts = <int, int>{};
  for (var log in logs) {
    if (log.status && log.timestamp != null) {
      dayCounts[log.timestamp!.weekday] = (dayCounts[log.timestamp!.weekday] ?? 0) + 1;
    }
  }
  if (dayCounts.isNotEmpty) {
    final topDayIndex = dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final indonesianDays = {
      1: 'Senin', 2: 'Selasa', 3: 'Rabu', 4: 'Kamis',
      5: 'Jumat', 6: 'Sabtu', 7: 'Minggu'
    };
    topProductiveDay = indonesianDays[topDayIndex];
  }

  // 5. Rata-rata Mood
  final moodLogs = logs.where((l) => l.moodLevel > 0).toList();
  final avgMood = moodLogs.isEmpty
      ? 0.0
      : moodLogs.map((l) => l.moodLevel).reduce((a, b) => a + b) / moodLogs.length;

  // 6. Success Rate
  final completedToday = logs.where((l) => 
    l.status && 
    l.idHabit != null && 
    l.timestamp != null && 
    l.timestamp!.year == now.year &&
    l.timestamp!.month == now.month &&
    l.timestamp!.day == now.day
  ).map((e) => e.idHabit).toSet().length;

  final totalActiveHabits = activeHabitIds.length;
  final successRate = totalActiveHabits == 0 ? 0.0 : (completedToday / totalActiveHabits) * 100;

  // 7. Smart Insight berdasarkan mood & busy level
  String smartInsight;
  final avgBusy = logs.isEmpty
      ? 0.0
      : logs.map((l) => l.busyLevel).reduce((a, b) => a + b) / logs.length;

  if (avgMood >= 4 && avgBusy <= 2) {
    smartInsight = 'Mood kamu bagus dan jadwal santai! Ini waktu terbaik untuk menambah habit baru.';
  } else if (avgMood >= 4 && avgBusy >= 3) {
    smartInsight = 'Kamu produktif meski sibuk! Kamu punya mental yang kuat.';
  } else if (avgMood <= 2 && avgBusy >= 3) {
    smartInsight = 'Kamu sedang sibuk dan mood kurang baik. Kurangi beban dan fokus habit prioritas.';
  } else if (avgMood <= 2) {
    smartInsight = 'Mood kamu sedang rendah. Coba mulai dengan habit kecil yang menyenangkan!';
  } else if (successRate >= 80) {
    smartInsight = 'Konsistensimu luar biasa! Success rate ${successRate.toStringAsFixed(0)}%. Pertahankan!';
  } else if (topProductiveDay != null) {
    smartInsight = 'Kamu paling produktif di hari $topProductiveDay. Manfaatkan hari itu!';
  } else {
    smartInsight = 'Terus semangat! Setiap langkah kecil membawamu lebih dekat ke tujuan.';
  }

  return StatisticsData(
    currentStreak: currentStreak,
    topHabitName: topHabitName,
    weeklyConsistency: weeklyConsistency,
    topProductiveDay: topProductiveDay,
    avgMood: avgMood,
    successRate: successRate,
    smartInsight: smartInsight,
    habits: habits,
    habitCounts: habitCounts,
    habitStreaks: habitStreaks,
  );
});

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsProvider);

    // --- LOGIKA THEME DITAMBAHKAN DI SINI ---
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
     backgroundColor: backgroundColor, 
      appBar: AppBar(
        title: Text(
          'Statistik',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF2B3A8C), 
            fontSize: 26,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: statsAsync.when(
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Performa Kinerja',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor, 
                  ),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Streak',
                        value: '${stats.currentStreak}',
                        subtitle: 'Days in a row',
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.orangeAccent,
                        cardColor: cardColor, 
                        textColor: textColor, 
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Habit Terkuat',
                        value: stats.topHabitName,
                        subtitle: 'Paling konsisten',
                        icon: Icons.emoji_events_rounded,
                        color: stats.topHabitName == 'Belum ada data' ? theme.disabledColor : Colors.amber,
                        isTextSmall: stats.topHabitName.length > 10,
                        cardColor: cardColor,
                        textColor: textColor, 
                      ),
                    ),
                  ],
                ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Konsisten 7-Hari',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                // PERBAIKAN: Mengirim semua parameter yang dibutuhkan oleh _buildBarChart
                _buildBarChart(stats.weeklyConsistency, context, cardColor, textColor, subtitleColor, isDarkMode),
                const SizedBox(height: 32),
                Text(
                  'Insights Prediksi',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInsightsCard(stats.topProductiveDay, stats.smartInsight, stats.successRate, context, cardColor, textColor),
                const SizedBox(height: 32),
                Text(
                  'Analisis Habit Spesifik',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildHabitsPerformanceList(stats.habits, stats.habitCounts, context, cardColor, textColor, subtitleColor, isDarkMode),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
        error: (error, _) => Center(child: Text('Error loading stats: $error', style: TextStyle(color: textColor))), // Warna pesan error dinamis
      ),
    );
  }

  // MENERIMA PARAMETER cardColor DAN textColor
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isTextSmall = false,
    required Color cardColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: isTextSmall ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: textColor, 
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MENERIMA PARAMETER TAMBAHAN UNTUK WARNA
  Widget _buildBarChart(List<int> weeklyData, BuildContext context, Color cardColor, Color textColor, Color subtitleColor, bool isDarkMode) {
    final bool isEmpty = weeklyData.every((v) => v == 0);

    if (isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 250),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2B3A8C).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 48,
                color: Color(0xFF2B3A8C),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Data',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selesaikan habit harianmu\nuntuk melihat konsistensimu di sini!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: subtitleColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Mulai hari ini!',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    int maxY = weeklyData.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 5;

    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    
    final todayIndex = DateTime.now().weekday - 1; 
    final shiftedDays = List<String>.filled(7, '');
    for (int i = 0; i < 7; i++) {
      int dayOffset = 6 - i;
      int targetDayIndex = (todayIndex - dayOffset) % 7;
      if (targetDayIndex < 0) targetDayIndex += 7;
      shiftedDays[i] = days[targetDayIndex];
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor, // Menggunakan warna dinamis
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY.toDouble() + (maxY * 0.2), 
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF2B3A8C),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.round()} Habits',
                  GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < 7) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        shiftedDays[index],
                        style: GoogleFonts.inter(
                          color: shiftedDays[index] == days[todayIndex]
                                ? const Color(0xFF2B3A8C)
                                : subtitleColor, 
                          fontWeight: shiftedDays[index] == days[todayIndex]
                                ? FontWeight.bold
                                : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 32,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY / 4) > 0 ? (maxY / 4) : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
                strokeWidth: 2, 
                dashArray: [5, 5]
              ); 
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: weeklyData[index].toDouble(),
                  color: shiftedDays[index] == days[todayIndex]
                    ? const Color(0xFF2B3A8C)
                    : const Color(0xFF2B3A8C).withValues(alpha: 0.5),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY.toDouble() + (maxY * 0.2),
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade50, // Warna background bar dinamis
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInsightsCard(String? topDay, String smartInsight, double successRate, BuildContext context, Color cardColor, Color textColor) {
  final hasData = topDay != null;
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;

  return Column(
    children: [
      // Smart Insight Card
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: hasData ? null : cardColor,
          gradient: hasData 
              ? const LinearGradient(
                  colors: [Color(0xFF2B3A8C), Color(0xFF1A237E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (hasData)
              BoxShadow(
                color: const Color(0xFF2B3A8C).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasData ? Colors.white.withValues(alpha: 0.2) : primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: hasData ? Colors.white : primaryBlue, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                smartInsight,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasData ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
      if (hasData) ...[
        const SizedBox(height: 16),
        // Success Rate Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Success Rate',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${successRate.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: successRate / 100,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          successRate >= 70 ? Colors.green : successRate >= 40 ? Colors.orange : Colors.red,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

  Widget _buildHabitsPerformanceList(List<HabitModel> habits, Map<String, int> counts, BuildContext context, Color cardColor, Color textColor, Color subtitleColor, bool isDarkMode) {
    final theme = Theme.of(context);
    
    if (habits.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.analytics_outlined, size: 48, color: primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada data analisis habit.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: habits.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final habit = habits[index];
        final count = counts[habit.idHabit] ?? 0;
        
        Color habitColor = const Color(0xFF2B3A8C);
        if (habit.warnaTag.isNotEmpty) {
          final buffer = StringBuffer();
          if (habit.warnaTag.length == 6 || habit.warnaTag.length == 7) buffer.write('ff');
          buffer.write(habit.warnaTag.replaceFirst('#', ''));
          try {
            habitColor = Color(int.parse(buffer.toString(), radix: 16));
          } catch (_) {}
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HabitHistoryScreen(habit: habit, color: habitColor)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: habitColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: UIHelper.renderHabitIcon(habit.ikon, size: 24, color: habitColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.namaHabit,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total selesai: $count kali',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: subtitleColor),
              ],
            ),
          ),
        );
      },
    );
  }
}