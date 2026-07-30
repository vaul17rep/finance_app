class DiagnosticMetrics {
  final int totalEmbeddings;
  final Map<String, int> bySourceType;
  final int emptyVectors;
  final int invalidVectors;
  final int avgDimension;
  final int minDimension;
  final int maxDimension;
  final int duplicates;
  final int staleEmbeddings;
  final double top1Accuracy;
  final double top3Accuracy;
  final double avgCosineSimilarity;
  final int avgSearchTimeMs;
  final int healthScore;

  DiagnosticMetrics({
    required this.totalEmbeddings,
    required this.bySourceType,
    required this.emptyVectors,
    required this.invalidVectors,
    required this.avgDimension,
    required this.minDimension,
    required this.maxDimension,
    required this.duplicates,
    required this.staleEmbeddings,
    required this.top1Accuracy,
    required this.top3Accuracy,
    required this.avgCosineSimilarity,
    required this.avgSearchTimeMs,
    required this.healthScore,
  });
}
