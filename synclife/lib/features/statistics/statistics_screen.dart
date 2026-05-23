import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../logs/log_repository.dart';
import '../habits/habit_repository.dart';

// Composite class to hold statistics
class StatisticsData {
  final int currentStreak;
  final String topHabitName;
  final List<int> weeklyConsistency; 
  final String? topProductiveDay;

  StatisticsData({
    required this.currentStreak,
    required this.topHabitName,
    required this.weeklyConsistency,
    this.topProductiveDay,
  });
}

// Provider to compute all statistics dynamically
final statisticsProvider = FutureProvider<StatisticsData>((ref) async {
  final logRepo = ref.watch(logRepositoryProvider);
  final habitRepo = ref.watch(habitRepositoryProvider);

  final logs = await logRepo.getLogs();
  final habits = await habitRepo.getHabits();

  if (logs.isEmpty) {
    return StatisticsData(
      currentStreak: 0,
      topHabitName: 'Belum Ada Data',
      weeklyConsistency: List.filled(7, 0),
    );
  }

  // 1. Calculate Top Habit
  final habitCounts = <String, int>{};
  for (var log in logs) {
    if (log.status) { 
      habitCounts[log.idHabit] = (habitCounts[log.idHabit] ?? 0) + 1;
    }
  }

  String topHabitName = 'Belum Ada Data';
  if (habitCounts.isNotEmpty) {
    var topEntry = habitCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    var topHabitModel = habits.where((h) => h.idHabit == topEntry.key).firstOrNull;
    if (topHabitModel != null) {
      topHabitName = topHabitModel.namaHabit;
    }
  }

  // 2. Calculate Weekly Consistency (Last 7 Days)
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
        final index = 6 - difference; 
        weeklyConsistency[index]++;
      }
    }
  }

  // 3. Calculate Total Active Streak
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

  // 4. Calculate Predictive Insights (Top Productive Day)
  String? topProductiveDay;
  if (logs.length >= 5) {
    final dayCounts = <int, int>{}; // 1 = Monday, 7 = Sunday
    for (var log in logs) {
      if (log.status && log.timestamp != null) {
        dayCounts[log.timestamp!.weekday] = (dayCounts[log.timestamp!.weekday] ?? 0) + 1;
      }
    }
    if (dayCounts.isNotEmpty) {
      final topDayIndex = dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final indonesianDays = {
        1: 'Senin', 2: 'Selasa', 3: 'Rabu', 4: 'Kamis', 5: 'Jumat', 6: 'Sabtu', 7: 'Minggu'
      };
      topProductiveDay = indonesianDays[topDayIndex];
    }
  }

  return StatisticsData(
    currentStreak: currentStreak,
    topHabitName: topHabitName,
    weeklyConsistency: weeklyConsistency,
    topProductiveDay: topProductiveDay,
  );
});

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
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
                  'Performance Overview',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Streak',
                        value: '${stats.currentStreak}',
                        subtitle: 'Days in a row',
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Habit Terkuat',
                        value: stats.topHabitName,
                        subtitle: 'Paling konsisten',
                        icon: Icons.emoji_events_rounded,
                        color: Colors.amber,
                        isTextSmall: stats.topHabitName.length > 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  '7-Day Consistency',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBarChart(stats.weeklyConsistency),
                const SizedBox(height: 32),
                Text(
                  'Predictive Insights',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInsightsCard(stats.topProductiveDay),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
        error: (error, _) => Center(child: Text('Error loading stats: $error')),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isTextSmall = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: isTextSmall ? 18 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<int> weeklyData) {
    int maxY = weeklyData.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 5;

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              getTooltipColor: (_) => Colors.deepPurple,
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
                          color: index == 6 ? Colors.deepPurple : Colors.grey.shade500,
                          fontWeight: index == 6 ? FontWeight.bold : FontWeight.w500,
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
              return FlLine(color: Colors.grey.shade100, strokeWidth: 2, dashArray: [5, 5]);
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: weeklyData[index].toDouble(),
                  color: index == 6 ? Colors.deepPurple : Colors.deepPurpleAccent.withOpacity(0.5),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY.toDouble() + (maxY * 0.2),
                    color: Colors.grey.shade50,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInsightsCard(String? topDay) {
    final hasData = topDay != null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasData 
            ? [Colors.deepPurpleAccent, Colors.deepPurple]
            : [Colors.grey.shade400, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (hasData ? Colors.deepPurple : Colors.grey).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              hasData
                  ? 'Kamu cenderung paling produktif di Hari $topDay. Pertahankan momentum ini!'
                  : 'Terus selesaikan habit harianmu agar kami bisa memberikan insight personal!',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
