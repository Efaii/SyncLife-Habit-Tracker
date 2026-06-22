import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/habit_model.dart';
import '../logs/log_repository.dart';
import '../../utils/ui_helper.dart';

class HabitHistoryScreen extends ConsumerWidget {
  final HabitModel habit;
  final Color color;

  const HabitHistoryScreen({super.key, required this.habit, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          habit.namaHabit,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: FutureBuilder(
        future: ref.read(logRepositoryProvider).getLogsByHabitId(habit.idHabit!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: textColor)));
          }

          final logs = snapshot.data ?? [];
          final completedLogs = logs.where((l) => l.status).toList();

          if (completedLogs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada riwayat pengerjaan.',
                style: GoogleFonts.inter(color: subtitleColor, fontSize: 16),
              ),
            );
          }

          final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: UIHelper.renderHabitIcon(habit.ikon, size: 32, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Total Dikerjakan',
                        style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${completedLogs.length} Kali',
                        style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Riwayat Terbaru',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedLogs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = completedLogs[index];
                    final date = log.timestamp != null ? dateFormat.format(log.timestamp!) : 'Waktu tidak diketahui';
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: color),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              date,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
