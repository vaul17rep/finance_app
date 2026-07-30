import '../diagnostic_metrics.dart';

class HealthScoreCalculator {
  int calculate(DiagnosticMetrics metrics) {
    int score = 100;

    if (metrics.emptyVectors > 0) {
      score -= 10;
    }
    if (metrics.invalidVectors > 0) {
      score -= 20;
    }
    if (metrics.avgDimension != 1536) {
      score -= 10;
    }
    if (metrics.duplicates > 0) {
      score -= (metrics.duplicates * 5).clamp(0, 20);
    }
    if (metrics.staleEmbeddings > 0) {
      score -= (metrics.staleEmbeddings * 2).clamp(0, 10);
    }

    if (metrics.top3Accuracy < 0.3) {
      score -= 30;
    } else if (metrics.top3Accuracy < 0.5) {
      score -= 20;
    } else if (metrics.top3Accuracy < 0.7) {
      score -= 10;
    }

    return score.clamp(0, 100);
  }
}
