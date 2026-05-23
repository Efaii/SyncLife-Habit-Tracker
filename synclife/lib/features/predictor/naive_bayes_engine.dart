import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'frequency_repository.dart';

// Provide the NaiveBayesEngine, injecting the FrequencyRepository
final predictorEngineProvider = Provider<NaiveBayesEngine>((ref) {
  final frequencyRepo = ref.watch(frequencyRepositoryProvider);
  return NaiveBayesEngine(frequencyRepo);
});

class NaiveBayesEngine {
  final FrequencyRepository _frequencyRepo;

  NaiveBayesEngine(this._frequencyRepo);

  /// Calculates the success probability of a habit given a mood level and busy level
  /// Returns a percentage between 0.0 and 100.0
  Future<double> calculateSuccessProbability({
    required int moodLevel,
    required int busyLevel,
  }) async {
    // Fetch all frequency data to compute totals and specific counts
    final allFreqs = await _frequencyRepo.getFrequencies();

    // 1. Calculate Total Historical Data
    // We derive total successes and fails by summing up all 'mood' frequencies.
    // This works because every log inherently records exactly one mood level.
    final moodFreqs = allFreqs.where((f) => f.variableType == 'mood').toList();
    
    int totalSuccess = 0;
    int totalFail = 0;
    for (var f in moodFreqs) {
      totalSuccess += f.countSuccess;
      totalFail += f.countFail;
    }
    
    int totalLogs = totalSuccess + totalFail;

    // Rule 1: Check for sufficient data
    // If we have less than 5 historical logs, we return a safe default of 50.0%
    if (totalLogs < 5) {
      return 50.0;
    }

    // Rule 2: Calculate Prior Probabilities
    double priorSuccess = totalSuccess / totalLogs;
    double priorFail = totalFail / totalLogs;

    // Fetch the specific counts for the given mood and busy level
    var moodRecord = allFreqs.where((f) => f.variableType == 'mood' && f.variableValue == moodLevel.toString()).firstOrNull;
    var busyRecord = allFreqs.where((f) => f.variableType == 'busy' && f.variableValue == busyLevel.toString()).firstOrNull;

    int moodSuccessCount = moodRecord?.countSuccess ?? 0;
    int moodFailCount = moodRecord?.countFail ?? 0;
    
    int busySuccessCount = busyRecord?.countSuccess ?? 0;
    int busyFailCount = busyRecord?.countFail ?? 0;

    // Rule 3: Calculate Likelihoods (with Laplace Smoothing)
    // We apply Laplace Smoothing (+1 to count, +N to total) to prevent the Zero-Frequency problem.
    // Mood has 5 possible states (1-5). Busy has 3 possible states (1-3).
    
    double likelihoodMoodSuccess = (moodSuccessCount + 1) / (totalSuccess + 5);
    double likelihoodMoodFail = (moodFailCount + 1) / (totalFail + 5);

    double likelihoodBusySuccess = (busySuccessCount + 1) / (totalSuccess + 3);
    double likelihoodBusyFail = (busyFailCount + 1) / (totalFail + 3);

    // Rule 4: Calculate Posterior Probabilities
    // P(Success | Evidence) is proportional to Prior * Likelihood(Mood) * Likelihood(Busy)
    double posteriorSuccess = priorSuccess * likelihoodMoodSuccess * likelihoodBusySuccess;
    double posteriorFail = priorFail * likelihoodMoodFail * likelihoodBusyFail;

    // Rule 5: Normalize the result to return a clear percentage (0.0 to 100.0)
    double probability = (posteriorSuccess / (posteriorSuccess + posteriorFail)) * 100;

    return probability;
  }
}
