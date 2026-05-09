import '../config/app_config.dart';
import '../journal/journal_entry.dart';
import 'trader_insight.dart';

class JournalPatternAnalytics {
  const JournalPatternAnalytics({
    required this.totalEntries,
    required this.averageConviction,
    required this.averageRisk,
    required this.mostCommonMood,
    required this.moodOutcomeCounts,
    required this.highConvictionPoorOutcomeCount,
    required this.highRiskEntryCount,
    required this.repeatedTags,
    required this.disciplineSignals,
    required this.disciplineSignalCount,
    required this.insights,
  });

  final int totalEntries;
  final double averageConviction;
  final double averageRisk;
  final JournalMood? mostCommonMood;
  final Map<JournalMood, Map<JournalOutcome, int>> moodOutcomeCounts;
  final int highConvictionPoorOutcomeCount;
  final int highRiskEntryCount;
  final List<String> repeatedTags;
  final List<String> disciplineSignals;
  final int disciplineSignalCount;
  final List<TraderInsight> insights;

  bool get hasEntries => totalEntries > 0;

  factory JournalPatternAnalytics.fromEntries(
    List<JournalEntry> entries, {
    DateTime? asOf,
  }) {
    final analysis = JournalPatternAnalyzer.analyze(entries, asOf: asOf);
    return analysis;
  }
}

class JournalPatternAnalyzer {
  const JournalPatternAnalyzer._();

  static JournalPatternAnalytics analyze(
    List<JournalEntry> entries, {
    DateTime? asOf,
  }) {
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
    final moodOutcomeCounts = <JournalMood, Map<JournalOutcome, int>>{};
    final tagCounts = <String, int>{};
    final disciplineSignals = <String>{};
    var highConvictionPoorOutcomeCount = 0;
    var highRiskEntryCount = 0;

    for (final entry in entries) {
      if (entry.mood != null) {
        moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
      }

      if (entry.mood != null && entry.outcome != null) {
        final outcomeCounts = moodOutcomeCounts.putIfAbsent(
          entry.mood!,
          () => <JournalOutcome, int>{},
        );
        outcomeCounts[entry.outcome!] =
            (outcomeCounts[entry.outcome!] ?? 0) + 1;
      }

      if (entry.convictionRating >= 4 &&
          (entry.outcome == JournalOutcome.loss ||
              entry.outcome == JournalOutcome.breakeven)) {
        highConvictionPoorOutcomeCount++;
      }

      if (entry.riskRating >= AppConfig.insightsHighRiskRatingThreshold) {
        highRiskEntryCount++;
      }

      for (final tag in entry.tags) {
        final normalized = tag.trim().toLowerCase();
        if (normalized.isEmpty) {
          continue;
        }
        tagCounts[normalized] = (tagCounts[normalized] ?? 0) + 1;
        if (_disciplineKeywords.contains(normalized)) {
          disciplineSignals.add(normalized);
        }
      }

      final searchableText = '${entry.body} ${entry.lessonsLearned ?? ''}'
          .toLowerCase();
      for (final keyword in _disciplineKeywords) {
        if (searchableText.contains(keyword)) {
          disciplineSignals.add(keyword);
        }
      }
    }

    final repeatedTags =
        tagCounts.entries
            .where((entry) => entry.value > 1)
            .map((entry) => entry.key)
            .toList(growable: false)
          ..sort();

    final mostCommonMood = _mostCommonMood(moodCounts);
    final averageConviction = totalEntries == 0
        ? 0.0
        : convictionTotal / totalEntries;
    final averageRisk = totalEntries == 0 ? 0.0 : riskTotal / totalEntries;
    final disciplineSignalList = disciplineSignals.toList(growable: false)
      ..sort();

    final insights = <TraderInsight>[
      if (mostCommonMood != null)
        TraderInsight(
          id: _id('mood', mostCommonMood.name),
          title: 'Most common mood: ${mostCommonMood.label}',
          description:
              'Your journal uses ${mostCommonMood.label.toLowerCase()} language more often than other moods.',
          category: TraderInsightCategory.psychology,
          severity: TraderInsightSeverity.info,
          createdAt: asOf ?? DateTime.now(),
          metricValue: moodCounts[mostCommonMood]!.toDouble(),
          actionSuggestion:
              'Review whether this mood matches your best-performing setups.',
        ),
      if (highConvictionPoorOutcomeCount > 0)
        TraderInsight(
          id: _id('high-conviction-losses', highConvictionPoorOutcomeCount),
          title: 'High conviction did not always translate to wins',
          description:
              '$highConvictionPoorOutcomeCount high-conviction journal entries ended in a loss or breakeven.',
          category: TraderInsightCategory.execution,
          severity: TraderInsightSeverity.warning,
          createdAt: asOf ?? DateTime.now(),
          metricValue: highConvictionPoorOutcomeCount.toDouble(),
          actionSuggestion:
              'Check whether entry timing, sizing, or stop rules need tightening.',
        ),
      if (highRiskEntryCount > 0)
        TraderInsight(
          id: _id('high-risk-count', highRiskEntryCount),
          title: 'Risk ratings are elevated in parts of the journal',
          description:
              '$highRiskEntryCount entries were tagged with a risk rating of ${AppConfig.insightsHighRiskRatingThreshold}+.',
          category: TraderInsightCategory.risk,
          severity: highRiskEntryCount / totalEntries >= 0.4
              ? TraderInsightSeverity.warning
              : TraderInsightSeverity.info,
          createdAt: asOf ?? DateTime.now(),
          metricValue: highRiskEntryCount.toDouble(),
          actionSuggestion:
              'Look for oversized trades or setups that were taken outside your rules.',
        ),
      if (repeatedTags.isNotEmpty)
        TraderInsight(
          id: _id('repeated-tags', repeatedTags.length),
          title: 'Repeated tags reveal recurring themes',
          description:
              'You repeatedly tagged: ${repeatedTags.take(4).join(', ')}.',
          category: TraderInsightCategory.consistency,
          severity: TraderInsightSeverity.warning,
          createdAt: asOf ?? DateTime.now(),
          metricValue: repeatedTags.length.toDouble(),
          actionSuggestion:
              'Turn the repeating tag into a checklist item before the next trade.',
        ),
      if (disciplineSignalList.isNotEmpty)
        TraderInsight(
          id: _id('discipline-signals', disciplineSignalList.length),
          title: 'Journal language shows discipline signals',
          description:
              'Your notes mention discipline cues such as ${disciplineSignalList.take(4).join(', ')}.',
          category: TraderInsightCategory.consistency,
          severity: TraderInsightSeverity.positive,
          createdAt: asOf ?? DateTime.now(),
          metricValue: disciplineSignalList.length.toDouble(),
          actionSuggestion:
              'Keep using these signals as a pre-trade checklist.',
        ),
    ];

    final pairInsights = _buildMoodOutcomeInsights(
      moodOutcomeCounts,
      asOf: asOf ?? DateTime.now(),
    );
    insights.addAll(pairInsights);

    insights.sort((left, right) {
      final severityComparison = _severityRank(
        right.severity,
      ).compareTo(_severityRank(left.severity));
      if (severityComparison != 0) {
        return severityComparison;
      }
      return right.createdAt.compareTo(left.createdAt);
    });

    return JournalPatternAnalytics(
      totalEntries: totalEntries,
      averageConviction: averageConviction,
      averageRisk: averageRisk,
      mostCommonMood: mostCommonMood,
      moodOutcomeCounts: moodOutcomeCounts,
      highConvictionPoorOutcomeCount: highConvictionPoorOutcomeCount,
      highRiskEntryCount: highRiskEntryCount,
      repeatedTags: repeatedTags,
      disciplineSignals: disciplineSignalList,
      disciplineSignalCount: disciplineSignalList.length,
      insights: insights,
    );
  }

  static List<TraderInsight> _buildMoodOutcomeInsights(
    Map<JournalMood, Map<JournalOutcome, int>> moodOutcomeCounts, {
    required DateTime asOf,
  }) {
    final results = <TraderInsight>[];
    for (final moodEntry in moodOutcomeCounts.entries) {
      final total = moodEntry.value.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );
      if (total == 0) {
        continue;
      }
      final lossCount = moodEntry.value[JournalOutcome.loss] ?? 0;
      final winCount = moodEntry.value[JournalOutcome.win] ?? 0;
      if (lossCount >= 2 && lossCount / total >= 0.5) {
        results.add(
          TraderInsight(
            id: _id('mood-loss', moodEntry.key.name),
            title: '${moodEntry.key.label} trades lean toward losses',
            description:
                '${moodEntry.value[JournalOutcome.loss] ?? 0} entries marked ${moodEntry.key.label.toLowerCase()} ended in a loss.',
            category: TraderInsightCategory.psychology,
            severity: TraderInsightSeverity.warning,
            createdAt: asOf,
            metricValue: lossCount.toDouble(),
            actionSuggestion:
                'Pause before trading in this state or reduce risk.',
          ),
        );
      }
      if (winCount >= 2 && winCount / total >= 0.5) {
        results.add(
          TraderInsight(
            id: _id('mood-win', moodEntry.key.name),
            title: '${moodEntry.key.label} entries show a positive edge',
            description:
                '${moodEntry.value[JournalOutcome.win] ?? 0} ${moodEntry.key.label.toLowerCase()} notes ended in a win.',
            category: TraderInsightCategory.consistency,
            severity: TraderInsightSeverity.positive,
            createdAt: asOf,
            metricValue: winCount.toDouble(),
            actionSuggestion:
                'Capture the pre-trade conditions that showed up before these wins.',
          ),
        );
      }
    }
    return results;
  }

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

  static int _severityRank(TraderInsightSeverity severity) {
    return switch (severity) {
      TraderInsightSeverity.info => 0,
      TraderInsightSeverity.positive => 1,
      TraderInsightSeverity.warning => 2,
      TraderInsightSeverity.critical => 3,
    };
  }

  static String _id(String prefix, Object value) => '$prefix-$value';
}

const Set<String> _disciplineKeywords = {
  'discipline',
  'disciplined',
  'plan',
  'planned',
  'patient',
  'wait',
  'rules',
  'rule',
  'process',
  'review',
  'checklist',
  'size',
  'sizing',
  'manage',
  'management',
  'thesis',
};
