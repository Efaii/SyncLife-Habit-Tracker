import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/dashboard_screen.dart';
import '../../models/log_model.dart';
import 'log_repository.dart';
import '../predictor/frequency_repository.dart';
import '../predictor/prediction_provider.dart';

class ContextBottomSheet extends ConsumerStatefulWidget {
  final String habitId;

  const ContextBottomSheet({super.key, required this.habitId});

  @override
  ConsumerState<ContextBottomSheet> createState() => _ContextBottomSheetState();
}

class _ContextBottomSheetState extends ConsumerState<ContextBottomSheet> {
  int _selectedMood = 3; 
  int _selectedBusy = 2; 
  bool _isLoading = false;

  void _submit() async {
    setState(() => _isLoading = true);

    try {
      // 1. Create Log Entry
      final logRepo = ref.read(logRepositoryProvider);
      final newLog = LogModel(
        idHabit: widget.habitId,
        moodLevel: _selectedMood,
        busyLevel: _selectedBusy,
        status: true, // Success marked
        timestamp: DateTime.now(),
      );
      await logRepo.createLog(newLog);

      // 2. Increment Frequencies for Naive Bayes Cache
      final freqRepo = ref.read(frequencyRepositoryProvider);
      await freqRepo.incrementFrequency(
        variableType: 'mood',
        variableValue: _selectedMood.toString(),
        isSuccess: true,
      );
      await freqRepo.incrementFrequency(
        variableType: 'busy',
        variableValue: _selectedBusy.toString(),
        isSuccess: true,
      );

      // 3. Trigger State Refresh (Invalidate cache to recalculate probability)
      ref.invalidate(predictionProvider);
      ref.invalidate(todayCompletedHabitsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Habit logged! Forecast updated.', style: GoogleFonts.inter()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Bagaimana perasaanmu?',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    emojis[index],
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 36),
          Text(
            'Tingkat Kesibukan',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBusyOption(1, 'Santai'),
              const SizedBox(width: 12),
              _buildBusyOption(2, 'Sedang'),
              const SizedBox(width: 12),
              _buildBusyOption(3, 'Sangat Sibuk'),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Simpan & Update Prediksi',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusyOption(int value, String label) {
    bool isSelected = _selectedBusy == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedBusy = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
