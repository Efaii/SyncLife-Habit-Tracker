import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../predictor/prediction_provider.dart';
import '../habits/habit_repository.dart';
import '../logs/context_bottom_sheet.dart';
import '../habits/add_habit_screen.dart';
import '../habits/edit_habit_screen.dart';
import '../logs/log_repository.dart';

// Constants
const Color bgColor = Color(0xFFF8F9FA);
const Color primaryBlue = Color(0xFF2B3A8C);
const Color softGreen = Color(0xFFA5D6A7);
final BoxShadow cardShadow = BoxShadow(
  color: Colors.black.withOpacity(0.05),
  blurRadius: 10,
  offset: const Offset(0, 4),
);

// Provider for fetching today's completed habits
final todayCompletedHabitsProvider = FutureProvider<Set<String>>((ref) async {
  final logRepo = ref.watch(logRepositoryProvider);
  final logs = await logRepo.getLogs();
  
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  
  final completedIds = <String>{};
  for (var log in logs) {
    if (log.status && log.timestamp != null) {
      final logDate = DateTime(log.timestamp!.year, log.timestamp!.month, log.timestamp!.day);
      if (logDate.isAtSameMomentAs(todayStart)) {
        completedIds.add(log.idHabit);
      }
    }
  }
  return completedIds;
});

// Provider for fetching habits asynchronously
final habitsFutureProvider = FutureProvider((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return repo.getHabits();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(predictionProvider);
    final habitsAsync = ref.watch(habitsFutureProvider);
    final completedAsync = ref.watch(todayCompletedHabitsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildForecastAndInsightCards(predictionAsync),
              const SizedBox(height: 32),
              _buildHabitsSection(context, ref, habitsAsync, completedAsync),
              const SizedBox(height: 32),
              _buildBottomStats(),
              const SizedBox(height: 100), // FAB padding
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddHabitScreen()),
          );
        },
        backgroundColor: primaryBlue,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat pagi,\nFathir',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mari mulai langkah kecil hari ini.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [cardShadow],
          ),
          child: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 24),
        ),
      ],
    );
  }

  Widget _buildForecastAndInsightCards(AsyncValue<PredictionResult> predictionAsync) {
    return predictionAsync.when(
      data: (result) {
        return Column(
          children: [
            // Success Forecast Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [cardShadow],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUCCESS FORECAST',
                          style: GoogleFonts.inter(
                            color: Colors.blue.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Peluang Sukses\nHari Ini',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up_rounded, color: softGreen, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Tinggi',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 90,
                    width: 90,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: result.percentage / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        Center(
                          child: Text(
                            '${result.percentage.toStringAsFixed(0)}%',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Predictive Insight Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [cardShadow],
                border: const Border(left: BorderSide(color: primaryBlue, width: 4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline, color: primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insight Predictive',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.insightText,
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Error: $error'),
    );
  }

  Widget _buildHabitsSection(BuildContext context, WidgetRef ref, AsyncValue habitsAsync, AsyncValue<Set<String>> completedAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Today's Focus",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              "View All",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        habitsAsync.when(
          data: (habits) {
            if (habits.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.edit_calendar_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No habits for today.',
                        style: GoogleFonts.inter(color: Colors.black45, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            final sortedHabits = List.of(habits)
              ..sort((a, b) => a.targetWaktu.compareTo(b.targetWaktu));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedHabits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final habit = sortedHabits[index];
                final isCompleted = completedAsync.when(
                  data: (completedIds) => completedIds.contains(habit.idHabit),
                  loading: () => false,
                  error: (_, __) => false,
                );

                return Opacity(
                  opacity: isCompleted ? 0.5 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [cardShadow],
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              habit.ikon.isNotEmpty ? habit.ikon : '⭐',
                              style: const TextStyle(fontSize: 22),
                            ),
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
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Daily habit • ${habit.targetWaktu.length >= 5 ? habit.targetWaktu.substring(0, 5) : habit.targetWaktu}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: isCompleted ? null : () {
                                if (habit.idHabit != null) {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                    ),
                                    builder: (context) => ContextBottomSheet(habitId: habit.idHabit!),
                                  );
                                }
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isCompleted ? softGreen : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCompleted ? softGreen : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: isCompleted 
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => EditHabitScreen(habit: habit)),
                                  );
                                } else if (value == 'delete') {
                                  if (habit.idHabit != null) {
                                    await ref.read(habitRepositoryProvider).deleteHabit(habit.idHabit!);
                                    ref.invalidate(habitsFutureProvider);
                                  }
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit_outlined, color: primaryBlue, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Edit', style: GoogleFonts.inter(color: primaryBlue)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Hapus', style: GoogleFonts.inter(color: Colors.redAccent)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Error: $error'),
        ),
      ],
    );
  }

  Widget _buildBottomStats() {
    return Column(
      children: [
        // Top Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [cardShadow],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '14 Day',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ACTIVE STREAK',
                    style: GoogleFonts.inter(
                      color: Colors.blue.shade200,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bottom Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '32 HABITS',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completed',
                      style: GoogleFonts.outfit(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: softGreen,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '98% FOCUS',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

}
