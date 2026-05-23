import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logs/log_repository.dart';

class PredictionResult {
  final double percentage;
  final String insightText;

  PredictionResult(this.percentage, this.insightText);
}

final predictionProvider = FutureProvider<PredictionResult>((ref) async {
  final logRepo = ref.watch(logRepositoryProvider);
  final logs = await logRepo.getLogs();

  if (logs.length < 5) {
    return PredictionResult(
      50.0,
      'Data sedang dikumpulkan. Tetap konsisten untuk mengaktifkan prediksi cerdas!',
    );
  }

  // Determine current variables
  final now = DateTime.now();
  final int currentDay = now.weekday; // 1 = Mon, 7 = Sun
  final bool isMorning = now.hour < 15; // < 3 PM is morning
  
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
        if (isSuccess) successOnDay++; else failOnDay++;
      }
      
      // Time (Morning vs Evening)
      bool logIsMorning = log.timestamp!.hour < 15;
      if (logIsMorning == isMorning) {
        if (isSuccess) successOnTime++; else failOnTime++;
      }
    }

    // Mood
    if (log.moodLevel == lastMood) {
      if (isSuccess) successOnMood++; else failOnMood++;
    }
  }

  final int totalLogs = totalSuccess + totalFail;
  if (totalLogs == 0) return PredictionResult(50.0, 'Belum ada data.');

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

  // Posterior Probabilities
  double postSuccess = priorSuccess * lDaySuccess * lTimeSuccess * lMoodSuccess;
  double postFail = priorFail * lDayFail * lTimeFail * lMoodFail;

  double percentage = 50.0;
  if (postSuccess + postFail > 0) {
    percentage = (postSuccess / (postSuccess + postFail)) * 100;
  }

  // Insight Generation (Identify the lowest likelihood factor for success)
  String insightText = 'Insight: Anda berada di jalur yang tepat! Pertahankan kebiasaan baik ini.';
  
  if (lMoodSuccess < lDaySuccess && lMoodSuccess < lTimeSuccess) {
    insightText = 'Insight: Mood Anda saat ini berpotensi menurunkan peluang sukses. Tetap semangat dan jangan menyerah!';
  } else if (lTimeSuccess < lDaySuccess && lTimeSuccess < lMoodSuccess) {
    String timeStr = isMorning ? 'Pagi' : 'Sore/Malam';
    insightText = 'Insight: Anda biasanya kurang produktif di waktu $timeStr. Cobalah ubah strategi Anda!';
  } else if (lDaySuccess < lTimeSuccess && lDaySuccess < lMoodSuccess) {
    List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    String dayStr = days[currentDay - 1];
    insightText = 'Insight: Hari $dayStr tampaknya menjadi tantangan buat Anda. Fokus lebih ekstra hari ini!';
  }

  return PredictionResult(percentage, insightText);
});
