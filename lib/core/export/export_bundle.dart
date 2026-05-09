import '../analytics/performance_snapshot.dart';
import '../analytics/trading_analytics.dart';
import '../config/app_config.dart';
import '../data/paper_trading_account.dart';
import '../insights/trader_behavior_analytics.dart';
import '../journal/journal_entry.dart';
import '../models/auth_session.dart';
import '../options_portfolio/options_income_analytics.dart';
import '../options_portfolio/options_portfolio_account.dart';
import '../analytics/portfolio_analytics.dart';
import '../sync/sync_metadata.dart';
import 'export_format.dart';

class ExportBundle {
  const ExportBundle({
    required this.createdAt,
    required this.appVersionLabel,
    required this.buildModeLabel,
    required this.marketModeLabel,
    required this.exportFormat,
    required this.includedSections,
    this.paperTradingAccount,
    this.journalEntries = const [],
    this.optionsPortfolioAccount,
    this.performanceSnapshot,
    this.portfolioAnalytics,
    this.activityAnalytics,
    this.optionsIncomeAnalytics,
    this.behaviorAnalytics,
    this.syncMetadata,
    this.authSession,
  });

  final DateTime createdAt;
  final String appVersionLabel;
  final String buildModeLabel;
  final String marketModeLabel;
  final ExportFormat exportFormat;
  final List<String> includedSections;
  final PaperTradingAccount? paperTradingAccount;
  final List<JournalEntry> journalEntries;
  final OptionsPortfolioAccount? optionsPortfolioAccount;
  final PerformanceSnapshot? performanceSnapshot;
  final PortfolioAnalytics? portfolioAnalytics;
  final TradingActivityAnalytics? activityAnalytics;
  final OptionsIncomeAnalytics? optionsIncomeAnalytics;
  final TraderBehaviorAnalytics? behaviorAnalytics;
  final SyncMetadata? syncMetadata;
  final AuthSession? authSession;

  Map<String, Object?> toJson() {
    return {
      'backupVersion': AppConfig.backupFormatVersion,
      'export': {
        'createdAt': createdAt.toIso8601String(),
        'format': exportFormat.name,
        'includedSections': includedSections,
        'backupVersion': AppConfig.backupFormatVersion,
      },
      'app': {
        'name': AppConfig.appName,
        'versionLabel': appVersionLabel,
        'buildModeLabel': buildModeLabel,
        'marketModeLabel': marketModeLabel,
      },
      'paperTrading': paperTradingAccount?.toJson(),
      'journal': {
        'entries': journalEntries.map((entry) => entry.toJson()).toList(),
      },
      'optionsPortfolio': optionsPortfolioAccount?.toJson(),
      'performance': performanceSnapshot?.toJson(),
      'analytics': {
        'portfolio': portfolioAnalytics == null
            ? null
            : _portfolioSummary(portfolioAnalytics!),
        'activity': activityAnalytics == null
            ? null
            : _activitySummary(activityAnalytics!),
        'optionsIncome': optionsIncomeAnalytics == null
            ? null
            : _optionsIncomeSummary(optionsIncomeAnalytics!),
        'behavior': behaviorAnalytics == null
            ? null
            : _behaviorSummary(behaviorAnalytics!),
      },
      'sync': syncMetadata?.toJson(),
      'auth': authSession?.toJson(),
    };
  }
}

Map<String, Object?> _portfolioSummary(PortfolioAnalytics analytics) {
  return {
    'totalPortfolioValue': analytics.totalPortfolioValue,
    'cashBalance': analytics.cashBalance,
    'investedValue': analytics.investedValue,
    'unrealizedProfitLoss': analytics.unrealizedProfitLoss,
    'unrealizedProfitLossPercent': analytics.unrealizedProfitLossPercent,
    'realizedProfitLoss': analytics.realizedProfitLoss,
    'totalProfitLoss': analytics.totalProfitLoss,
    'returnPercent': analytics.returnPercent,
    'cashAllocationPercent': analytics.cashAllocationPercent,
    'investedAllocationPercent': analytics.investedAllocationPercent,
    'openPositionsCount': analytics.openPositionsCount,
    'concentrationRiskPercent': analytics.concentrationRiskPercent,
    'hasConcentrationWarning': analytics.hasConcentrationWarning,
    'largestPosition': analytics.largestPosition == null
        ? null
        : {
            'symbol': analytics.largestPosition!.asset.symbol,
            'name': analytics.largestPosition!.asset.name,
            'marketValue': analytics.largestPosition!.marketValue,
            'weightPercent': analytics.largestPosition!.weightPercent,
          },
    'bestPosition': analytics.bestPosition == null
        ? null
        : {
            'symbol': analytics.bestPosition!.asset.symbol,
            'name': analytics.bestPosition!.asset.name,
            'marketValue': analytics.bestPosition!.marketValue,
            'weightPercent': analytics.bestPosition!.weightPercent,
            'unrealizedProfitLoss':
                analytics.bestPosition!.unrealizedProfitLoss,
          },
    'worstPosition': analytics.worstPosition == null
        ? null
        : {
            'symbol': analytics.worstPosition!.asset.symbol,
            'name': analytics.worstPosition!.asset.name,
            'marketValue': analytics.worstPosition!.marketValue,
            'weightPercent': analytics.worstPosition!.weightPercent,
            'unrealizedProfitLoss':
                analytics.worstPosition!.unrealizedProfitLoss,
          },
    'allocationByAsset': analytics.allocationByAsset
        .map(
          (allocation) => {
            'symbol': allocation.asset.symbol,
            'name': allocation.asset.name,
            'quantity': allocation.quantity,
            'marketValue': allocation.marketValue,
            'weightPercent': allocation.weightPercent,
            'unrealizedProfitLoss': allocation.unrealizedProfitLoss,
            'unrealizedProfitLossPercent':
                allocation.unrealizedProfitLossPercent,
          },
        )
        .toList(growable: false),
  };
}

Map<String, Object?> _activitySummary(TradingActivityAnalytics analytics) {
  return {
    'totalOrders': analytics.totalOrders,
    'buyOrderCount': analytics.buyOrderCount,
    'sellOrderCount': analytics.sellOrderCount,
    'totalBuyVolume': analytics.totalBuyVolume,
    'totalSellVolume': analytics.totalSellVolume,
    'averageOrderSize': analytics.averageOrderSize,
    'largestOrder': analytics.largestOrder == null
        ? null
        : {
            'assetSymbol': analytics.largestOrder!.assetSymbol,
            'assetName': analytics.largestOrder!.assetName,
            'side': analytics.largestOrder!.side.name,
            'quantity': analytics.largestOrder!.quantity,
            'executionPrice': analytics.largestOrder!.executionPrice,
            'estimatedTotal': analytics.largestOrder!.estimatedTotal,
            'timestamp': analytics.largestOrder!.timestamp.toIso8601String(),
            'status': analytics.largestOrder!.status.name,
            'averageCostAtExecution':
                analytics.largestOrder!.averageCostAtExecution,
            'realizedProfitLoss': analytics.largestOrder!.realizedProfitLoss,
          },
    'mostTradedAsset': analytics.mostTradedAsset == null
        ? null
        : {
            'symbol': analytics.mostTradedAsset!.symbol,
            'name': analytics.mostTradedAsset!.name,
            'orderCount': analytics.mostTradedAsset!.orderCount,
            'totalQuantity': analytics.mostTradedAsset!.totalQuantity,
            'totalNotional': analytics.mostTradedAsset!.totalNotional,
          },
    'lastTradeDate': analytics.lastTradeDate?.toIso8601String(),
  };
}

Map<String, Object?> _optionsIncomeSummary(OptionsIncomeAnalytics analytics) {
  return {
    'totalPremiumCollected': analytics.totalPremiumCollected,
    'premiumCollectedThisMonth': analytics.premiumCollectedThisMonth,
    'realizedOptionsProfitLoss': analytics.realizedOptionsProfitLoss,
    'openPremiumAtRisk': analytics.openPremiumAtRisk,
    'averagePremiumPerTrade': analytics.averagePremiumPerTrade,
    'annualizedPremiumYieldAverage': analytics.annualizedPremiumYieldAverage,
    'premiumByStrategy': analytics.premiumByStrategy.map(
      (strategy, value) => MapEntry(strategy.name, value),
    ),
    'premiumByUnderlying': analytics.premiumByUnderlying,
    'openContractsCount': analytics.openContractsCount,
    'upcomingExpirations': analytics.upcomingExpirations
        .map((position) => position.toJson())
        .toList(growable: false),
    'assignmentsCount': analytics.assignmentsCount,
    'expiredWorthlessCount': analytics.expiredWorthlessCount,
    'openPositionsCount': analytics.openPositionsCount,
    'latestUpdatedAt': analytics.latestUpdatedAt?.toIso8601String(),
  };
}

Map<String, Object?> _behaviorSummary(TraderBehaviorAnalytics analytics) {
  return {
    'generatedAt': analytics.generatedAt.toIso8601String(),
    'totalInsights': analytics.totalInsights,
    'positiveCount': analytics.positiveCount,
    'warningCount': analytics.warningCount,
    'criticalCount': analytics.criticalCount,
    'journalAnalysis': {
      'totalEntries': analytics.journalAnalysis.totalEntries,
      'averageConviction': analytics.journalAnalysis.averageConviction,
      'averageRisk': analytics.journalAnalysis.averageRisk,
      'mostCommonMood': analytics.journalAnalysis.mostCommonMood?.name,
      'highConvictionPoorOutcomeCount':
          analytics.journalAnalysis.highConvictionPoorOutcomeCount,
      'highRiskEntryCount': analytics.journalAnalysis.highRiskEntryCount,
      'repeatedTags': analytics.journalAnalysis.repeatedTags,
      'disciplineSignals': analytics.journalAnalysis.disciplineSignals,
      'disciplineSignalCount': analytics.journalAnalysis.disciplineSignalCount,
    },
    'strategyAnalysis': {
      'bestStrategy': analytics.strategyAnalysis.bestStrategy?.name,
      'worstStrategy': analytics.strategyAnalysis.worstStrategy?.name,
      'mostJournaledStrategy':
          analytics.strategyAnalysis.mostJournaledStrategy?.name,
      'mostTradedAssetSymbol': analytics.strategyAnalysis.mostTradedAssetSymbol,
      'symbolsWithRepeatedLosses':
          analytics.strategyAnalysis.symbolsWithRepeatedLosses,
      'strategiesWithHighRiskRatings': analytics
          .strategyAnalysis
          .strategiesWithHighRiskRatings
          .map((strategy) => strategy.name)
          .toList(growable: false),
      'premiumConcentrationByUnderlying':
          analytics.strategyAnalysis.premiumConcentrationByUnderlying,
      'wheelCyclesWithPoorOutcomes': analytics
          .strategyAnalysis
          .wheelCyclesWithPoorOutcomes
          .map((cycle) => cycle.toJson())
          .toList(growable: false),
    },
    'optionsInsights': analytics.optionsInsights
        .map((insight) => insight.toJson())
        .toList(),
    'insights': analytics.insights.map((insight) => insight.toJson()).toList(),
  };
}
