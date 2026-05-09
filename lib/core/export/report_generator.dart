import '../config/app_config.dart';
import '../journal/journal_entry.dart';
import '../insights/trader_behavior_analytics.dart';
import '../options_portfolio/options_income_analytics.dart';
import 'export_format.dart';
import 'export_bundle.dart';

class ReportGenerator {
  const ReportGenerator._();

  static String generate(ExportBundle bundle) {
    final buffer = StringBuffer();
    buffer.writeln('# ${AppConfig.appName} performance report');
    buffer.writeln();
    buffer.writeln('- Created: ${_formatDateTime(bundle.createdAt)}');
    buffer.writeln('- Version: ${bundle.appVersionLabel}');
    buffer.writeln('- Build: ${bundle.buildModeLabel}');
    buffer.writeln('- Market mode: ${bundle.marketModeLabel}');
    buffer.writeln('- Format: ${bundle.exportFormat.label}');
    buffer.writeln();
    buffer.writeln('> ${AppConfig.paperTradingDisclaimer}');
    buffer.writeln('> ${AppConfig.simulatedPricesDisclaimer}');
    buffer.writeln('> ${AppConfig.exportReportDisclaimer}');
    buffer.writeln();

    final performance = bundle.performanceSnapshot;
    if (performance != null) {
      buffer.writeln('## Portfolio summary');
      buffer.writeln(
        '- Realized P/L: ${_money(performance.realizedProfitLoss)}',
      );
      buffer.writeln(
        '- Unrealized P/L: ${_money(performance.unrealizedProfitLoss)}',
      );
      buffer.writeln('- Total P/L: ${_money(performance.totalProfitLoss)}');
      buffer.writeln('- Return: ${_percent(performance.returnPercent)}');
      buffer.writeln(
        '- Cash allocation: ${_percent(performance.cashAllocationPercent)}',
      );
      buffer.writeln(
        '- Invested allocation: ${_percent(performance.investedAllocationPercent)}',
      );
      if (performance.hasConcentrationWarning) {
        buffer.writeln(
          '- Risk notice: concentration is above ${(AppConfig.analyticsConcentrationThreshold * 100).toStringAsFixed(0)}%.',
        );
      }
      buffer.writeln();
    }

    if (bundle.optionsIncomeAnalytics != null) {
      _writeOptionsSection(buffer, bundle.optionsIncomeAnalytics!);
    }

    if (bundle.behaviorAnalytics != null) {
      _writeBehaviorSection(buffer, bundle.behaviorAnalytics!);
    }

    if (bundle.includedSections.isNotEmpty) {
      buffer.writeln('## Included sections');
      for (final section in bundle.includedSections) {
        buffer.writeln('- $section');
      }
      buffer.writeln();
    }

    buffer.writeln('## Notes');
    buffer.writeln(
      '- This report is educational only and is not investment advice.',
    );
    buffer.writeln(
      '- All figures are based on local paper trading, mock options, and simulated market data.',
    );

    return buffer.toString();
  }

  static void _writeOptionsSection(
    StringBuffer buffer,
    OptionsIncomeAnalytics analytics,
  ) {
    buffer.writeln('## Options income');
    buffer.writeln(
      '- Total premium collected: ${_money(analytics.totalPremiumCollected)}',
    );
    buffer.writeln(
      '- Premium collected this month: ${_money(analytics.premiumCollectedThisMonth)}',
    );
    buffer.writeln(
      '- Realized options P/L: ${_money(analytics.realizedOptionsProfitLoss)}',
    );
    buffer.writeln(
      '- Open premium at risk: ${_money(analytics.openPremiumAtRisk)}',
    );
    buffer.writeln(
      '- Average premium per trade: ${_money(analytics.averagePremiumPerTrade)}',
    );
    buffer.writeln(
      '- Annualized premium yield: ${_percent(analytics.annualizedPremiumYieldAverage)}',
    );
    buffer.writeln('- Open contracts: ${analytics.openContractsCount}');
    buffer.writeln(
      '- Upcoming expirations: ${analytics.upcomingExpirations.length}',
    );
    buffer.writeln('- Assignments: ${analytics.assignmentsCount}');
    buffer.writeln('- Expired worthless: ${analytics.expiredWorthlessCount}');
    buffer.writeln();
  }

  static void _writeBehaviorSection(
    StringBuffer buffer,
    TraderBehaviorAnalytics analytics,
  ) {
    buffer.writeln('## Trader behavior');
    buffer.writeln(
      '- Journal entries analyzed: ${analytics.journalAnalysis.totalEntries}',
    );
    buffer.writeln('- Total insights: ${analytics.totalInsights}');
    buffer.writeln('- Positive signals: ${analytics.positiveCount}');
    buffer.writeln('- Warnings: ${analytics.warningCount}');
    buffer.writeln('- Critical: ${analytics.criticalCount}');
    if (analytics.insights.isNotEmpty) {
      buffer.writeln('- Key signals:');
      for (final insight in analytics.insights.take(5)) {
        buffer.writeln('  - ${insight.title}');
      }
    }
    if (analytics.journalAnalysis.mostCommonMood != null) {
      buffer.writeln(
        '- Most common mood: ${analytics.journalAnalysis.mostCommonMood!.label}',
      );
    }
    buffer.writeln();
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _percent(double value) => '${value.toStringAsFixed(1)}%';

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
