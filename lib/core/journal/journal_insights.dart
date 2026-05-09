import 'journal_entry.dart';

class JournalInsights {
  const JournalInsights({
    required this.totalEntries,
    required this.averageConviction,
    required this.averageRisk,
    required this.winCount,
    required this.lossCount,
    required this.breakevenCount,
    required this.openCount,
    required this.mostCommonMood,
    required this.mostTaggedStrategy,
  });

  factory JournalInsights.fromEntries(List<JournalEntry> entries) {
    final totalEntries = entries.length;
    final convictionTotal = entries.fold<int>(
      0,
      (total, entry) => total + entry.convictionRating,
    );
    final riskTotal = entries.fold<int>(
      0,
      (total, entry) => total + entry.riskRating,
    );
    final moodCounts = <JournalMood, int>{};
    final strategyCounts = <JournalStrategyType, int>{};
    var winCount = 0;
    var lossCount = 0;
    var breakevenCount = 0;
    var openCount = 0;

    for (final entry in entries) {
      final mood = entry.mood;
      if (mood != null) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
      }
      final strategy = entry.linkedStrategy;
      if (strategy != null) {
        strategyCounts[strategy] = (strategyCounts[strategy] ?? 0) + 1;
      }
      switch (entry.outcome) {
        case JournalOutcome.win:
          winCount++;
        case JournalOutcome.loss:
          lossCount++;
        case JournalOutcome.breakeven:
          breakevenCount++;
        case JournalOutcome.open:
          openCount++;
        case null:
          break;
      }
    }

    return JournalInsights(
      totalEntries: totalEntries,
      averageConviction: totalEntries == 0 ? 0 : convictionTotal / totalEntries,
      averageRisk: totalEntries == 0 ? 0 : riskTotal / totalEntries,
      winCount: winCount,
      lossCount: lossCount,
      breakevenCount: breakevenCount,
      openCount: openCount,
      mostCommonMood: _mostCommonMood(moodCounts),
      mostTaggedStrategy: _mostCommonStrategy(strategyCounts),
    );
  }

  final int totalEntries;
  final double averageConviction;
  final double averageRisk;
  final int winCount;
  final int lossCount;
  final int breakevenCount;
  final int openCount;
  final JournalMood? mostCommonMood;
  final JournalStrategyType? mostTaggedStrategy;

  bool get hasEntries => totalEntries > 0;

  String get outcomeSummary =>
      '${winCount}W / ${lossCount}L / ${breakevenCount}BE';

  static JournalMood? _mostCommonMood(Map<JournalMood, int> counts) {
    JournalMood? result;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        result = entry.key;
        bestCount = entry.value;
      }
    }
    return result;
  }

  static JournalStrategyType? _mostCommonStrategy(
    Map<JournalStrategyType, int> counts,
  ) {
    JournalStrategyType? result;
    var bestCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        result = entry.key;
        bestCount = entry.value;
      }
    }
    return result;
  }
}
