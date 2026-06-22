import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../logs/log_repository.dart';
import '../habits/habit_repository.dart';
import '../../models/log_model.dart';
import '../../models/habit_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final logs = allLogs.where((log) => activeHabitIds.contains(log.idHabit)).toList();

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

  final recentLog = logs.first;

  int daysMissed = 0;
  if (recentLog.timestamp != null) {
    final lastLogDate = DateTime(recentLog.timestamp!.year, recentLog.timestamp!.month, recentLog.timestamp!.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    daysMissed = todayDate.difference(lastLogDate).inDays;
  }

  // Last recorded mood
  final int lastMood = recentLog.moodLevel;

  int totalSuccess = 0;
  int totalFail = 0;

  int successOnDay = 0;
  int failOnDay = 0;

  int successOnTime = 0;
  int failOnTime = 0;

  int successOnMood = 0;
  int failOnMood = 0;

  final int lastBusy = recentLog.busyLevel;
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

  // Alpha = 1.0 (Laplace smoothing parameter)
  double alpha = 1.0;

  // Prior Probabilities with Laplace Smoothing (2 classes: Success and Fail)
  double priorSuccess = (totalSuccess + alpha) / (totalLogs + (alpha * 2));
  double priorFail = (totalFail + alpha) / (totalLogs + (alpha * 2));

  // Likelihoods with Laplace Smoothing
  // Day (7 states), Time (2 states), Mood (5 states), Busy (5 states)
  double lDaySuccess = (successOnDay + alpha) / (totalSuccess + (alpha * 7));
  double lDayFail = (failOnDay + alpha) / (totalFail + (alpha * 7));

  double lTimeSuccess = (successOnTime + alpha) / (totalSuccess + (alpha * 2));
  double lTimeFail = (failOnTime + alpha) / (totalFail + (alpha * 2));

  double lMoodSuccess = (successOnMood + alpha) / (totalSuccess + (alpha * 5));
  double lMoodFail = (failOnMood + alpha) / (totalFail + (alpha * 5));

  double lBusySuccess = (successOnBusy + alpha) / (totalSuccess + (alpha * 5));
  double lBusyFail = (failOnBusy + alpha) / (totalFail + (alpha * 5));

  // Posterior Probabilities (Raw Scores)
  double rawSuccessScore = priorSuccess * lDaySuccess * lTimeSuccess * lMoodSuccess * lBusySuccess;
  double rawFailureScore = priorFail * lDayFail * lTimeFail * lMoodFail * lBusyFail;

  double percentage = 0.0;

  if (rawSuccessScore + rawFailureScore > 0) {
    double probability = rawSuccessScore / (rawSuccessScore + rawFailureScore);
    
    // Implementasi Time Decay (Momentum Inactivity)
    if (daysMissed > 1) {
      double decayFactor = pow(0.8, daysMissed - 1).toDouble();
      probability = probability * decayFactor;
    }
    
    percentage = (probability * 100).clamp(0.0, 100.0).toDouble();
  }

  // Insight Generation
  String insightText = '';

  String getMoodText(int level) {
    switch (level) {
      case 1: return 'Sangat Buruk';
      case 2: return 'Buruk';
      case 3: return 'Netral';
      case 4: return 'Baik';
      case 5: return 'Sangat Baik';
      default: return 'Netral';
    }
  }

  String getBusyText(int level) {
    switch (level) {
      case 1: return 'Santai';
      case 2: return 'Sedang';
      case 3: return 'Sangat Sibuk';
      default: return 'Sedang';
    }
  }

  final moodStr = getMoodText(lastMood);
  final busyStr = getBusyText(lastBusy);
  
  final bool isBadConditions = lastMood <= 2 || lastBusy == 3;
  final bool isGoodConditions = !isBadConditions;
  
  if (percentage >= 70.0) {
    if (isBadConditions) {
      insightText = 'Luar biasa! Meski mood sedang **$moodStr** dan jadwal **$busyStr**, rekam jejakmu membuktikan kamu tetap tangguh. Pertahankan fokusmu!';
    } else {
      insightText = 'Peluang suksesmu ${percentage.toStringAsFixed(0)}%. Dengan mood **$moodStr** dan jadwal yang **$busyStr**, ini adalah momentum sempurna untuk produktif!';
    }
  } else if (percentage < 40.0) {
    if (isGoodConditions) {
      insightText = 'Peluang masa lalu rendah, tapi mumpung mood sedang **$moodStr**, jadikan ini energi untuk mendobrak kebiasaan buruk!';
    } else {
      insightText = 'Kondisi jadwal **$busyStr** dan mood **$moodStr** memang berat. Tidak apa-apa, turunkan ekspektasi dan fokus 1 langkah kecil hari ini.';
    }
  } else {
    insightText = 'Peluangmu ${percentage.toStringAsFixed(0)}%. Di tengah jadwal **$busyStr** dan mood **$moodStr**, fokus selesaikan 1-2 habit prioritas.';
  }

  return PredictionResult(percentage, insightText, loggedDaysCount: loggedDaysCount);
}

final predictionProvider = FutureProvider<PredictionResult>((ref) async {
  final habitRepo = ref.watch(habitRepositoryProvider);
  final habits = await habitRepo.getHabits();
  
  if (habits.isEmpty) {
    return const PredictionResult(
      0.0, 
      'Mulai centang habit pertamamu hari ini untuk melatih AI.', 
      loggedDaysCount: 0,
    );
  }

  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  if (userId == null) {
    return const PredictionResult(0.0, 'Silakan login untuk melihat prediksi.', loggedDaysCount: 0);
  }

  final response = await Supabase.instance.client
      .from('logs')
      .select()
      .eq('user_id', userId)
      .not('habit_name', 'is', null)
      .gte('timestamp', sevenDaysAgo.toIso8601String())
      .lte('timestamp', now.toIso8601String())
      .order('timestamp', ascending: false);

  final recentLogs = response.map((json) => LogModel.fromJson(json)).toList();

  if (recentLogs.isEmpty) {
    return const PredictionResult(
      0.0,
      'Belum ada data 7 hari terakhir. Mulai catat habit untuk melatih AI.',
      loggedDaysCount: 0,
    );
  }

  // Jalankan kalkulasi berat di background isolate
  return await compute(_calculatePredictionIsolate, _PredictionData(recentLogs, habits));
});
