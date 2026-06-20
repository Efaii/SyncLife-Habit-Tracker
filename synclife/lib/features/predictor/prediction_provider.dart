import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../logs/log_repository.dart';
import '../habits/habit_repository.dart';
import '../../models/log_model.dart';
import '../../models/habit_model.dart';

class PredictionResult {
  final double percentage;
  final String insightText;
  final int loggedDaysCount;

  const PredictionResult(this.percentage, this.insightText, {this.loggedDaysCount = 7});
}

class _PredictionData {
  final List<LogModel> logs;
  final List<HabitModel> habits;

  const _PredictionData(this.logs, this.habits);
}

PredictionResult _calculatePredictionIsolate(_PredictionData data) {
  final allLogs = data.logs;
  final habits = data.habits;

  final activeHabitIds = habits.map((h) => h.idHabit).toSet();
  final logs = allLogs; // Preserve historical logs of soft-deleted habits

  final loggedDays = logs.map((l) {
    if (l.timestamp != null) {
      return DateTime(l.timestamp!.year, l.timestamp!.month, l.timestamp!.day);
    }
    return null;
  }).whereType<DateTime>().toSet();

  final int loggedDaysCount = loggedDays.length;

  if (loggedDaysCount == 0) {
    return const PredictionResult(
      0.0,
      'Mulai centang habit pertamamu hari ini untuk melatih AI.',
      loggedDaysCount: 0,
    );
  } else if (loggedDaysCount < 7) {
    return PredictionResult(
      0.0,
      'AI sedang mempelajari polamu. Terus konsisten! (${7 - loggedDaysCount} hari lagi menuju insight pertama)',
      loggedDaysCount: loggedDaysCount,
    );
  }

  // Determine current variables
  final now = DateTime.now();
  final int currentDay = now.weekday; // 1 = Mon, 7 = Sun
  final bool isMorning = now.hour < 15; // < 3 PM is morning
  final todayLogs = logs.where((l) {
        return l.status &&
            l.timestamp != null &&
            l.timestamp!.year == now.year &&
            l.timestamp!.month == now.month &&
            l.timestamp!.day == now.day;
      }).toList();

      final completedToday =
          todayLogs.where((e) => e.idHabit != null).map((e) => e.idHabit).toSet().length;

      final totalHabits = habits.length;

      final focusScore = totalHabits == 0
          ? 0
          : ((completedToday / totalHabits) * 100);
  
  // Last recorded mood
  final int lastMood = logs.isNotEmpty ? logs.first.moodLevel : 3;

  int totalSuccess = 0;
  int totalFail = 0;

  int successOnDay = 0;
  int failOnDay = 0;

  int successOnTime = 0;
  int failOnTime = 0;

  int successOnMood = 0;
  int failOnMood = 0;

  final int lastBusy = logs.isNotEmpty ? logs.first.busyLevel : 3;
  int successOnBusy = 0;
  int failOnBusy = 0;

  for (var log in logs) {
    bool isSuccess = log.status;
    
    if (isSuccess) {
      totalSuccess++;
    } else {
      totalFail++;
    }

    if (log.timestamp != null) {
      // Day
      if (log.timestamp!.weekday == currentDay) {
        if (isSuccess) {
          successOnDay++;
        } else {
          failOnDay++;
        }
      }
      
      // Time (Morning vs Evening)
      bool logIsMorning = log.timestamp!.hour < 15;
      if (logIsMorning == isMorning) {
        if (isSuccess) {
          successOnTime++;
        } else {
          failOnTime++;
        }
      }
    }

    // Mood
    if (log.moodLevel == lastMood) {
      if (isSuccess) {
        successOnMood++;
      } else {
        failOnMood++;
      }
    }

    // Busy
    if (log.busyLevel == lastBusy) {
      if (isSuccess) {
        successOnBusy++;
      } else {
        failOnBusy++;
      }
    }
  }

  final int totalLogs = totalSuccess + totalFail;
  if (totalLogs == 0) return const PredictionResult(0.0, 'Belum ada cukup data untuk prediksi hari ini.');

  // Prior Probabilities
  double priorSuccess = totalSuccess / totalLogs;
  double priorFail = totalFail / totalLogs;

  // Likelihoods with Laplace Smoothing
  // Day (7 states), Time (2 states), Mood (5 states)
  double lDaySuccess = (successOnDay + 1) / (totalSuccess + 7);
  double lDayFail = (failOnDay + 1) / (totalFail + 7);

  double lTimeSuccess = (successOnTime + 1) / (totalSuccess + 2);
  double lTimeFail = (failOnTime + 1) / (totalFail + 2);

  double lMoodSuccess = (successOnMood + 1) / (totalSuccess + 5);
  double lMoodFail = (failOnMood + 1) / (totalFail + 5);

  double lBusySuccess = (successOnBusy + 1) / (totalSuccess + 5);
  double lBusyFail = (failOnBusy + 1) / (totalFail + 5);

  // Posterior Probabilities
  double postSuccess = priorSuccess * lDaySuccess * lTimeSuccess * lMoodSuccess * lBusySuccess;
  double postFail = priorFail * lDayFail * lTimeFail * lMoodFail * lBusyFail;

  double percentage = focusScore.toDouble();

    if (postSuccess + postFail > 0) {
      final aiScore =
          (postSuccess / (postSuccess + postFail)) * 100;

          percentage = ((focusScore * 0.7) +
              (aiScore * 0.3));

          percentage = percentage.clamp(0.0, 100.0).toDouble();
    }

  // Insight Generation
  String insightText = '';
  
  if (percentage >= 70.0) {
    insightText = 'Insight: Konsistensi Anda luar biasa! Prediksi peluang sukses hari ini sangat tinggi.';
  } else if (percentage >= 40.0) {
    insightText = 'Insight: Hari ini mungkin terasa cukup padat. Fokus selesaikan 2 habit prioritas Anda terlebih dahulu.';
  } else {
    insightText = 'Insight: Performa sedang menurun. Jangan menyerah, mulai dengan satu langkah kecil hari ini!';
  }

  return PredictionResult(percentage, insightText, loggedDaysCount: loggedDaysCount);
}

final predictionProvider = FutureProvider<PredictionResult>((ref) async {
  final logRepo = ref.watch(logRepositoryProvider);
  final allLogs = await logRepo.getLogs();
  final habitRepo = ref.watch(habitRepositoryProvider);
  final habits = await habitRepo.getHabits();

  // Jalankan kalkulasi berat di background isolate
  return await compute(_calculatePredictionIsolate, _PredictionData(allLogs, habits));
});
