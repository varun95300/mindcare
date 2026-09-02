import 'quiz_question.dart';

/// Tracks accumulated evidence for each screening domain.
class DomainEvidence {
  final Map<ScreeningDomain, double> _scores = {
    for (final d in ScreeningDomain.values) d: 0.0,
  };

  /// Maximum possible score seen (for normalization).
  final Map<ScreeningDomain, double> _maxPossible = {
    for (final d in ScreeningDomain.values) d: 0.0,
  };

  int questionsAnswered = 0;

  /// Add evidence from a single answer.
  void addEvidence(ScreeningDomain domain, double amount, double maxAmount) {
    _scores[domain] = (_scores[domain] ?? 0) + amount;
    _maxPossible[domain] = (_maxPossible[domain] ?? 0) + maxAmount;
  }

  /// Raw score for a domain.
  double rawScore(ScreeningDomain domain) => _scores[domain] ?? 0.0;

  /// Normalized score (0.0 to 1.0) for a domain.
  double normalizedScore(ScreeningDomain domain) {
    final max = _maxPossible[domain] ?? 0.0;
    if (max == 0) return 0.0;
    return (_scores[domain] ?? 0.0) / max;
  }

  /// Get all domain scores sorted by strength (highest first).
  List<MapEntry<ScreeningDomain, double>> get sortedScores {
    final entries = ScreeningDomain.values
        .map((d) => MapEntry(d, normalizedScore(d)))
        .toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// The domain with the highest evidence.
  ScreeningDomain get leadingDomain => sortedScores.first.key;

  /// The gap between the top two domains (higher = more certain).
  double get certaintyGap {
    final sorted = sortedScores;
    if (sorted.length < 2) return 1.0;
    return sorted[0].value - sorted[1].value;
  }

  /// Domains where uncertainty is highest (close scores).
  List<ScreeningDomain> get uncertainDomains {
    final sorted = sortedScores;
    if (sorted.length < 2) return [];
    final top = sorted[0].value;
    return sorted
        .where((e) => (top - e.value).abs() < 0.15 && e.value > 0.1)
        .map((e) => e.key)
        .toList();
  }

  /// Severity label for a normalized score.
  static String severityLabel(double normalized) {
    if (normalized >= 0.65) return 'High';
    if (normalized >= 0.40) return 'Moderate';
    if (normalized >= 0.20) return 'Mild';
    return 'Low';
  }

  /// Create a snapshot copy.
  DomainEvidence copy() {
    final copy = DomainEvidence();
    copy.questionsAnswered = questionsAnswered;
    for (final d in ScreeningDomain.values) {
      copy._scores[d] = _scores[d] ?? 0.0;
      copy._maxPossible[d] = _maxPossible[d] ?? 0.0;
    }
    return copy;
  }
}
