import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/log_model.dart';
import '../../utils/ui_helper.dart';
import 'log_repository.dart';
import '../habit_sync_service.dart';

class ContextBottomSheet extends ConsumerStatefulWidget {
  final String habitId;
  final String habitName;

  const ContextBottomSheet({super.key, required this.habitId, required this.habitName});

  @override
  ConsumerState<ContextBottomSheet> createState() => _ContextBottomSheetState();
}

class _ContextBottomSheetState extends ConsumerState<ContextBottomSheet> {
  int? _selectedMood;
  int? _selectedBusy;
  bool _isLoading = false;

  void _submit() async {
    if (_selectedMood == null || _selectedBusy == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tolong beritahu perasaan dan kesibukanmu saat ini!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final logRepo = ref.read(logRepositoryProvider);
      final logs = await logRepo.getLogs();
      final now = DateTime.now();

      // Cek duplikasi hari ini
      final hasLoggedToday = logs.any((l) =>
          l.idHabit == widget.habitId &&
          l.status == true &&
          l.timestamp?.year == now.year &&
          l.timestamp?.month == now.month &&
          l.timestamp?.day == now.day);

      if (hasLoggedToday) {
        if (mounted) {
          UIHelper.showSuccessSnackbar(context, "Habit sudah diselesaikan hari ini!");
        }
        setState(() => _isLoading = false);
        return;
      }

      final newLog = LogModel(
        idHabit: widget.habitId,
        habitName: widget.habitName,
        moodLevel: _selectedMood!,
        busyLevel: _selectedBusy!,
        status: true,
        timestamp: now,
      );

      // Gunakan HabitSyncService untuk memastikan Sinkronisasi Cerdas (SMART SYNC)
      await ref.read(habitSyncServiceProvider).submitHabitLog(newLog);
      
      if (!mounted) return;
      UIHelper.showSuccessSnackbar(context, 'Yeay! Habit berhasil diselesaikan.');
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        UIHelper.showErrorSnackbar(context, 'Terjadi kesalahan pada sistem. Silakan coba lagi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final cardBgColor = isDarkMode ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50;
    final borderColor = isDarkMode ? Colors.white24 : Colors.grey.shade300;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Bagaimana perasaanmu?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          // Emoji Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              int moodValue = index + 1;
              bool isSelected = _selectedMood == moodValue;
              List<String> emojis = ['😢', '😕', '😐', '🙂', '😄'];
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = moodValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                  child: Text(
                    emojis[index],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          Text(
            'Tingkat Kesibukan',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          // Busy Level Selection
          Row(
            children: [
              _buildBusyButton(1, 'Santai'),
              const SizedBox(width: 8),
              _buildBusyButton(2, 'Sedang'),
              const SizedBox(width: 8),
              _buildBusyButton(3, 'Sangat Sibuk'),
            ],
          ),
          const SizedBox(height: 28),
          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Simpan & Update Prediksi',
                      style: GoogleFonts.inter(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusyButton(int value, String label) {
    final isSelected = _selectedBusy == value;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedBusy = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.inter(
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
      ),
    );
  }
}