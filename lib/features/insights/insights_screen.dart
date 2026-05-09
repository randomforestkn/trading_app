import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/insights/insights_state.dart';
import '../../core/insights/trader_behavior_analytics.dart';
import '../../core/insights/trader_insight.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_pill_chip.dart';
import '../../core/widgets/app_stat_tile.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/section_header.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const routeName = '/insights';

  @override
  Widget build(BuildContext context) {
    final insightsState = InsightsScope.of(context);

    return AnimatedBuilder(
      animation: insightsState,
      builder: (context, _) {
        final analytics = insightsState.analytics;
        final insights = insightsState.insights;
        final hasData = analytics?.hasData ?? false;

        return AppPage(
          title: 'Trader insights',
          subtitle: 'Rule-based behavior analytics',
          actions: [
            IconButton(
              tooltip: 'Refresh insights',
              onPressed: insightsState.isLoading
                  ? null
                  : () => insightsState.refreshInsights(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          children: [
            const AppInfoBanner(
              title: 'Rule-based insights',
              message:
                  '${AppConfig.insightsDisclaimer} No external AI model or network call is used.',
              icon: Icons.auto_graph_outlined,
              accentColor: AppTheme.secondary,
            ),
            if (insightsState.isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (insightsState.errorMessage != null) ...[
              const SizedBox(height: 12),
              AppInfoBanner(
                title: 'Insights unavailable',
                message: insightsState.errorMessage!,
                icon: Icons.warning_amber_outlined,
                accentColor: AppTheme.danger,
              ),
            ],
            const SizedBox(height: 12),
            _SummaryCard(analytics: analytics),
            const SizedBox(height: 12),
            if (!hasData || insights.isEmpty) ...[
              const EmptyStateView(
                title: 'No insights yet',
                message:
                    'Journal a few trades, place paper orders, or add option positions to unlock behavior analytics.',
                icon: Icons.insights_outlined,
              ),
            ] else ...[
              const SectionHeader('Positive signals'),
              _InsightGroup(
                insights: insightsState.positiveInsights,
                emptyMessage: 'No positive signals detected yet.',
              ),
              const SectionHeader('Risk warnings'),
              _InsightGroup(
                insights: [
                  ...insightsState.warnings,
                  ...insightsState.criticalInsights,
                ],
                emptyMessage: 'No risk warnings detected yet.',
              ),
              const SectionHeader('Psychology patterns'),
              _InsightGroup(
                insights: insights
                    .where(
                      (insight) =>
                          insight.category == TraderInsightCategory.psychology,
                    )
                    .toList(growable: false),
                emptyMessage: 'No psychology patterns detected yet.',
              ),
              const SectionHeader('Strategy patterns'),
              _InsightGroup(
                insights: insights
                    .where(
                      (insight) =>
                          insight.category == TraderInsightCategory.strategy ||
                          insight.category == TraderInsightCategory.execution ||
                          insight.category == TraderInsightCategory.consistency,
                    )
                    .toList(growable: false),
                emptyMessage: 'No strategy patterns detected yet.',
              ),
              const SectionHeader('Options income patterns'),
              _InsightGroup(
                insights: insights
                    .where(
                      (insight) =>
                          insight.category ==
                          TraderInsightCategory.optionsIncome,
                    )
                    .toList(growable: false),
                emptyMessage: 'No options income patterns detected yet.',
              ),
              const SectionHeader('How this is calculated'),
              const _TransparencyCard(),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.analytics});

  final TraderBehaviorAnalytics? analytics;

  @override
  Widget build(BuildContext context) {
    final journal = analytics?.journalAnalysis;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Total insights',
              value: analytics?.totalInsights.toString() ?? '0',
            ),
          ),
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Positive',
              value: analytics?.positiveCount.toString() ?? '0',
              color: AppTheme.primary,
            ),
          ),
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Warnings',
              value: analytics?.warningCount.toString() ?? '0',
              color: AppTheme.warning,
            ),
          ),
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Critical',
              value: analytics?.criticalCount.toString() ?? '0',
              color: AppTheme.danger,
            ),
          ),
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Avg conviction',
              value: journal == null
                  ? '0.0'
                  : journal.averageConviction.toStringAsFixed(1),
            ),
          ),
          SizedBox(
            width: 170,
            child: AppStatTile(
              label: 'Avg risk',
              value: journal == null
                  ? '0.0'
                  : journal.averageRisk.toStringAsFixed(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightGroup extends StatelessWidget {
  const _InsightGroup({required this.insights, required this.emptyMessage});

  final List<TraderInsight> insights;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return AppCard(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.white60),
        ),
      );
    }

    return Column(
      children: insights
          .map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InsightCard(insight: insight),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final TraderInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(insight.severity);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _SeverityBadge(label: insight.severity.label, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPillChip(
                label: insight.category.label,
                selected: true,
                onSelected: (_) {},
                selectedColor: color,
                icon: Icons.sell_outlined,
              ),
              if (insight.relatedSymbol != null)
                AppPillChip(
                  label: insight.relatedSymbol!,
                  selected: true,
                  onSelected: (_) {},
                  selectedColor: AppTheme.secondary,
                  icon: Icons.show_chart,
                ),
              if (insight.relatedStrategy != null)
                AppPillChip(
                  label: insight.relatedStrategy!,
                  selected: true,
                  onSelected: (_) {},
                  selectedColor: AppTheme.warning,
                  icon: Icons.tune,
                ),
            ],
          ),
          if (insight.actionSuggestion != null) ...[
            const SizedBox(height: 10),
            Text(
              insight.actionSuggestion!,
              style: const TextStyle(
                color: Colors.white60,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TransparencyCard extends StatelessWidget {
  const _TransparencyCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'These insights use only local app data:',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 10),
          Text(
            '• Journal mood, conviction, risk ratings, tags, and lessons learned.\n'
            '• Paper orders and their realized or unrealized outcomes.\n'
            '• Options positions, trades, wheel cycles, and premium analytics.\n'
            '• Current market snapshots for concentration and moneyness checks.\n\n'
            'The rules are transparent and deterministic. They summarize behavior patterns; they do not predict market outcomes.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

Color _severityColor(TraderInsightSeverity severity) {
  return switch (severity) {
    TraderInsightSeverity.info => AppTheme.secondary,
    TraderInsightSeverity.positive => AppTheme.primary,
    TraderInsightSeverity.warning => AppTheme.warning,
    TraderInsightSeverity.critical => AppTheme.danger,
  };
}
