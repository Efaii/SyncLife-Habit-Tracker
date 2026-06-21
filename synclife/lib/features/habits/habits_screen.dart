import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/dashboard_screen.dart'; // To get habitsProvider, todayCompletedHabitsProvider, bgColor, Theme.of(context).colorScheme.primary
import '../../utils/ui_helper.dart';
import '../habit_sync_service.dart';
import '../logs/context_bottom_sheet.dart';
import '../habits/edit_habit_screen.dart';
import 'add_habit_screen.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final completedAsync = ref.watch(todayCompletedHabitsProvider);

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    final BoxShadow cardShadow = BoxShadow(
      color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Semua Kebiasaan',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Theme.of(context).colorScheme.primary,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Theme.of(context).colorScheme.primary,
        ),
      ),
      body: SafeArea(
        child: habitsAsync.when(
          data: (habits) {
            final completedIds = completedAsync.when(data: (ids) => ids, loading: () => <String>[], error: (_, _) => <String>[]);
            final completedCount = habits.where((h) => completedIds.contains(h.idHabit)).length;
            final sortedHabits = List.of(habits)..sort((a, b) => a.targetWaktu.compareTo(b.targetWaktu));

            if (habits.isEmpty) {
              return RefreshIndicator(
                color: Theme.of(context).colorScheme.primary,
                onRefresh: () async {
                  ref.invalidate(habitsProvider);
                  ref.invalidate(todayCompletedHabitsProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [cardShadow]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                            child: Icon(Icons.edit_calendar_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
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
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)),
                              child: Text('Tambah Habit', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onPrimary)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async {
                ref.invalidate(habitsProvider);
                ref.invalidate(todayCompletedHabitsProvider);
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: Column(
                children: [
                  // Minimalist Progress Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Progress",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Text(
                              "[$completedCount/${habits.length}] Habits Done",
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: habits.isEmpty ? 0.0 : completedCount / habits.length,
                            minHeight: 4,
                            backgroundColor: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: sortedHabits.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final habit = sortedHabits[index];
                        final isCompleted = completedAsync.when(
                          data: (ids) => ids.contains(habit.idHabit),
                          loading: () => false,
                          error: (_, _) => false,
                        );

                        Color habitColor = Theme.of(context).colorScheme.primary;
                        if (habit.warnaTag.isNotEmpty) {
                          final buffer = StringBuffer();
                          if (habit.warnaTag.length == 6 || habit.warnaTag.length == 7) buffer.write('ff');
                          buffer.write(habit.warnaTag.replaceFirst('#', ''));
                          try {
                            habitColor = Color(int.parse(buffer.toString(), radix: 16));
                          } catch (_) {}
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isCompleted ? (isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100) : cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isCompleted ? Colors.transparent : (isDarkMode ? Colors.white10 : Colors.grey.shade200),
                              width: 1.5,
                            ),
                            boxShadow: isCompleted ? [] : [cardShadow],
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: isCompleted ? habitColor.withValues(alpha: 0.2) : habitColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: UIHelper.renderHabitIcon(habit.ikon, size: 24, color: habitColor),
                                ),
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
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Habit Harian • ${habit.targetWaktu.length >= 5 ? habit.targetWaktu.substring(0, 5) : habit.targetWaktu}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (habit.idHabit != null) {
                                          if (!isCompleted) {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: cardColor,
                                              shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                              ),
                                              builder: (context) => ContextBottomSheet(
                                                habitId: habit.idHabit!,
                                                habitName: habit.namaHabit,
                                              ),
                                            );
                                          } else {
                                            final confirm = await UIHelper.showUncheckConfirmation(context);
                                            if (confirm == true) {
                                              try {
                                                await ref.read(habitSyncServiceProvider).removeTodayLog(habit.idHabit!);
                                                if (context.mounted) {
                                                  UIHelper.showSuccessSnackbar(context, 'Log habit dibatalkan');
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  UIHelper.showErrorSnackbar(context, 'Terjadi kesalahan pada sistem. Silakan coba lagi.');
                                                }
                                              }
                                            }
                                          }
                                        }
                                      },
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: isCompleted ? habitColor : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isCompleted
                                                ? habitColor
                                                : Colors.grey.shade400,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: isCompleted
                                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert_rounded, color: subtitleColor),
                                    color: cardColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => EditHabitScreen(habit: habit)),
                                        );
                                      } else if (value == 'hapus') {
                                        if (habit.idHabit != null) {
                                          try {
                                            await ref.read(habitSyncServiceProvider).deleteHabit(habit.idHabit!);
                                            if (!context.mounted) return;
                                            UIHelper.showSuccessSnackbar(context, 'Habit berhasil dihapus.');
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            UIHelper.showErrorSnackbar(context, 'Gagal menghapus habit.');
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                                            const SizedBox(width: 10),
                                            Text('Edit', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'hapus',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                            const SizedBox(width: 10),
                                            Text('Hapus', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Gagal memuat daftar kebiasaan.', style: TextStyle(color: textColor))),
        ),
      ),
    );
  }
}
