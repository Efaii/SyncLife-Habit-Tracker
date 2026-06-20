import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../predictor/prediction_provider.dart';
import '../habits/habit_repository.dart';
import '../logs/context_bottom_sheet.dart';
import '../habits/add_habit_screen.dart';
import '../habits/edit_habit_screen.dart';
import '../logs/log_repository.dart';
import '../statistics/statistics_screen.dart';
import '../notifications/notification_history_screen.dart';
import '../../utils/ui_helper.dart';
import '../habit_sync_service.dart';
import '../profile/profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Constants
const Color bgColor = Color(0xFFEEF2FF);
const Color primaryBlue = Color(0xFF2B3A8C);
const Color softGreen = Color(0xFFA5D6A7);

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
        if (log.idHabit != null) completedIds.add(log.idHabit!);
      }
    }
  }
  return completedIds;
});

// Provider for fetching habits asynchronously
final habitsProvider = StreamProvider((ref) {
  final repo = ref.watch(habitRepositoryProvider);
  return repo.watchHabits();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Selamat pagi';
    if (hour >= 11 && hour < 15) return 'Selamat siang';
    if (hour >= 15 && hour < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  String getTodayName() {
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    // --- TAMBAHKAN LOGIKA THEME DI SINI ---
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : bgColor;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
    final BoxShadow cardShadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    );

    return Scaffold(
      backgroundColor: backgroundColor, // Gunakan backgroundColor dinamis
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final profileAsync = ref.watch(profileProvider);
                  return _buildHeader(context, profileAsync, cardColor, cardShadow, textColor, subtitleColor);
                },
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, _) {
                  final predictionAsync = ref.watch(predictionProvider);
                  return _buildForecastAndInsightCards(context, predictionAsync, cardColor, cardShadow, textColor, subtitleColor);
                },
              ),
              const SizedBox(height: 32),
              Consumer(
                builder: (context, ref, _) {
                  final habitsAsync = ref.watch(habitsProvider);
                  final completedAsync = ref.watch(todayCompletedHabitsProvider);
                  return _buildHabitsSection(context, ref, habitsAsync, completedAsync, cardColor, cardShadow, textColor, subtitleColor, isDarkMode);
                },
              ),
              const SizedBox(height: 32),
              Consumer(
                builder: (context, ref, _) {
                  final completedAsync = ref.watch(todayCompletedHabitsProvider);
                  return _buildBottomStats(ref, completedAsync, cardColor, cardShadow, textColor, subtitleColor);
                },
              ),
              const SizedBox(height: 100),
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

  Widget _buildHeader(BuildContext context, AsyncValue profileAsync, Color cardColor, BoxShadow cardShadow, Color textColor, Color subtitleColor) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            profileAsync.when(
              data: (profile) {
                String userName = profile?.fullName ?? 'Pengguna';
                
                return Text(
                  '${getGreeting()},\n$userName',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.2,
                  ),
                );
              },
              loading: () => Text(
                '${getGreeting()},\n...',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.2,
                ),
              ),
              error: (_, _) => Text(
                '${getGreeting()},\nPengguna',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hari ${getTodayName()} • Mari mulai langkah kecil hari ini.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            shape: BoxShape.circle,
            boxShadow: [cardShadow],
          ),
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: Icon(Icons.notifications_outlined, color: textColor, size: 24),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationHistoryScreen()));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastAndInsightCards(BuildContext context, AsyncValue<PredictionResult> predictionAsync, Color cardColor, BoxShadow cardShadow, Color textColor, Color subtitleColor) {
    return predictionAsync.when(
      data: (result) {
        if (result.insightText == 'Belum ada cukup data untuk prediksi hari ini.') {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    result.insightText,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Success Forecast Card (Tetap biru gradient)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, const Color(0xFF1A237E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'SUCCESS FORECAST',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Peluang Sukses\nHari Ini', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: result.percentage >= 70 ? Colors.green.withValues(alpha: 0.3) : result.percentage >= 40 ? Colors.orange.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(result.percentage >= 70 ? Icons.trending_up_rounded : result.percentage >= 40 ? Icons.trending_flat_rounded : Icons.trending_down_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(result.percentage >= 70 ? 'Tinggi' : result.percentage >= 40 ? 'Sedang' : 'Rendah', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 100, width: 100,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: result.percentage / 100, strokeWidth: 10, backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(result.percentage >= 70 ? Colors.greenAccent : result.percentage >= 40 ? Colors.orangeAccent : Colors.redAccent),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${result.percentage.toStringAsFixed(0)}%', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              Text('Sukses', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
                            ],
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
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [cardShadow],
                border: Border(left: BorderSide(color: Colors.amber.shade600, width: 4)),
              ),
              child: Row(
                children: [
                  result.loggedDaysCount > 0 && result.loggedDaysCount < 7
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                value: result.loggedDaysCount / 7,
                                strokeWidth: 3,
                                backgroundColor: Colors.amber.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                              ),
                            ),
                            Icon(Icons.auto_awesome, color: Colors.amber.shade700, size: 20),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                        ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Fokus Hari Ini', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: textColor)),
                            if (result.loggedDaysCount >= 7)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                child: Text('${result.percentage.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(result.insightText, style: GoogleFonts.inter(color: subtitleColor, fontSize: 13, height: 1.4)),
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
      error: (error, _) => Text('Error: $error', style: TextStyle(color: textColor)),
    );
  }

  Widget _buildHabitsSection(BuildContext context, WidgetRef ref, AsyncValue habitsAsync, AsyncValue<Set<String>> completedAsync, Color cardColor, BoxShadow cardShadow, Color textColor, Color subtitleColor, bool isDarkMode) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("Habit Harian", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          ],
        ),
        const SizedBox(height: 16),
        habitsAsync.when(
          data: (habits) {
            if (habits.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [cardShadow]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.edit_calendar_rounded, size: 48, color: primaryBlue),
                    ),
                    const SizedBox(height: 16),
                    Text('Belum Ada Habit', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 8),
                    Text('Yuk tambah kebiasaan pertamamu\ndan mulai perjalanan produktifmu!', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: subtitleColor, height: 1.5)),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddHabitScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(20)),
                        child: Text('Tambah Habit', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              );
            }

            final sortedHabits = List.of(habits)..sort((a, b) => a.targetWaktu.compareTo(b.targetWaktu));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedHabits.length > 3 ? 3 : sortedHabits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final habit = sortedHabits[index];
                final isCompleted = completedAsync.when(data: (ids) => ids.contains(habit.idHabit), loading: () => false, error: (_, _) => false);
                final habitColor = Color(int.parse(habit.warnaTag.replaceAll('#', '0xFF')));

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isCompleted ? (isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100) : cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isCompleted ? Colors.transparent : (isDarkMode ? Colors.white10 : Colors.grey.shade200), width: 1.5),
                    boxShadow: isCompleted ? [] : [cardShadow],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 52, width: 52,
                        decoration: BoxDecoration(
                          color: isCompleted ? habitColor.withOpacity(0.2) : habitColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(child: UIHelper.renderHabitIcon(habit.ikon, size: 24, color: habitColor)),
                      ),
                      const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.namaHabit, 
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700, 
                                  fontSize: 15, 
                                  color: isCompleted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface, 
                                  decoration: isCompleted ? TextDecoration.lineThrough : null
                                )
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Habit Harian • ${habit.targetWaktu.length >= 5 ? habit.targetWaktu.substring(0, 5) : habit.targetWaktu}', 
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 12, 
                                      color: theme.colorScheme.onSurfaceVariant, 
                                      fontWeight: FontWeight.w500
                                    )
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(19),
                                onTap: () async {
                                 if (habit.idHabit == null) return;
                                 if (isCompleted) {
                                   final confirm = await UIHelper.showUncheckConfirmation(context);
                                   if (confirm == true) {
                                     try {
                                       await ref.read(habitSyncServiceProvider).removeTodayLog(habit.idHabit!);
                                       if (context.mounted) {
                                         UIHelper.showSuccessSnackbar(context, 'Log habit dibatalkan');
                                       }
                                     } catch (e) {
                                       if (context.mounted) {
                                         UIHelper.showErrorSnackbar(context, 'Error: $e');
                                       }
                                     }
                                   }
                                 } else {
                                   showModalBottomSheet(
                                     context: context,
                                     isScrollControlled: true,
                                     backgroundColor: cardColor,
                                     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                     builder: (context) => Material(
                                       color: Colors.transparent,
                                       child: ContextBottomSheet(
                                         habitId: habit.idHabit!, 
                                         habitName: habit.namaHabit
                                       ),
                                     ),
                                   );
                                 }
                               },
                              child: Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  color: isCompleted ? habitColor : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isCompleted ? habitColor : Colors.grey.shade400, width: 2),
                                ),
                                child: Center(child: isCompleted ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null),
                              ),
                             ),
                            ),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_rounded, color: subtitleColor),
                              color: cardColor, // Warna menu popup
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditHabitScreen(habit: habit)));
                                } else if (value == 'hapus') {
                                  if (habit.idHabit != null) {
                                    await ref.read(habitSyncServiceProvider).deleteHabit(habit.idHabit!);
                                  }
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, color: primaryBlue, size: 20), const SizedBox(width: 8), Text('Edit', style: GoogleFonts.inter(color: primaryBlue))])),
                                PopupMenuItem(value: 'hapus', child: Row(children: [const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), const SizedBox(width: 8), Text('Hapus', style: GoogleFonts.inter(color: Colors.redAccent))])),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Error: $error', style: TextStyle(color: textColor)),
        ),
      ],
    );
  }

  Widget _buildBottomStats(WidgetRef ref, AsyncValue<Set<String>> completedAsync, Color cardColor, BoxShadow cardShadow, Color textColor, Color subtitleColor) {
    final statsAsync = ref.watch(statisticsProvider);
    final streak = statsAsync.when(data: (stats) => stats.currentStreak, loading: () => 0, error: (_, _) => 0);
    final activeHabitIds = ref.watch(habitsProvider).when(
      data: (habits) => habits.map((h) => h.idHabit).toSet(),
      loading: () => <String>{},
      error: (_, _) => <String>{},
    );

    final totalHabits = activeHabitIds.length;

    final completedCount = completedAsync.when(
      data: (ids) => ids.where((id) => activeHabitIds.contains(id)).length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    final focusScore = totalHabits == 0
        ? 0
        : ((completedCount / totalHabits) * 100).round();

    return Column(
      children: [
        // Top Card - Streak (Tetap gradient gelap)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryBlue, const Color(0xFF1A237E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: primaryBlue.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACTIVE STREAK', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(streak == 0 ? 'Mulai streak hari ini!' : '$streak Hari Berturut-turut!', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [cardShadow]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text('$completedCount HABITS', textAlign: TextAlign.center, style: GoogleFonts.inter(color: subtitleColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                    const SizedBox(height: 4),
                    Text(completedCount == 0 ? 'Belum Ada' : 'Selesai', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [cardShadow]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.bolt_rounded, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$focusScore% FOKUS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: subtitleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Skor', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
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