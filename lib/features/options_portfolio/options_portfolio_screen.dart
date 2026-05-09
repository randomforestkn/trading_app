import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/analytics/options_analytics.dart';
import '../../core/data/market_state.dart';
import '../../core/journal/journal_entry.dart';
import '../../core/options_portfolio/option_position.dart';
import '../../core/options_portfolio/options_income_analytics.dart';
import '../../core/options_portfolio/options_portfolio_state.dart';
import '../../core/strategies/option_contract.dart';
import '../../core/strategies/option_strategy.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_pill_chip.dart';
import '../../core/widgets/app_stat_tile.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/section_header.dart';
import '../insights/insights_screen.dart';
import '../journal/journal_editor_screen.dart';
import 'option_position_editor_screen.dart';

class OptionsPortfolioScreen extends StatelessWidget {
  const OptionsPortfolioScreen({super.key});

  static const routeName = '/options-portfolio';

  @override
  Widget build(BuildContext context) {
    final optionsState = OptionsPortfolioScope.of(context);
    final marketState = MarketScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([optionsState, marketState]),
      builder: (context, _) {
        final analytics = OptionsIncomeAnalytics.fromState(
          state: optionsState,
          marketState: marketState,
        );
        final hasContent =
            optionsState.openPositions.isNotEmpty ||
            optionsState.closedPositions.isNotEmpty ||
            optionsState.trades.isNotEmpty;

        return AppPage(
          title: 'Options portfolio',
          subtitle: 'Income, lifecycle, and wheel tracking',
          actions: [
            IconButton(
              tooltip: 'New option position',
              onPressed: optionsState.isSaving
                  ? null
                  : () => _openEditor(context),
              icon: const Icon(Icons.add),
            ),
          ],
          children: [
            const AppInfoBanner(
              title: 'Options tracking',
              message:
                  'This is a local paper-trading ledger for strategy practice. No brokerage integration or live execution is involved.',
              icon: Icons.receipt_long_outlined,
              accentColor: AppTheme.secondary,
            ),
            const SizedBox(height: 12),
            _OverviewCard(analytics: analytics, optionsState: optionsState),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  const SizedBox(
                    width: 260,
                    child: Text(
                      'Review options behavior',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  AppSecondaryButton(
                    label: 'Open insights',
                    icon: Icons.insights_outlined,
                    onPressed: optionsState.isLoading
                        ? null
                        : () => Navigator.of(
                            context,
                          ).pushNamed(InsightsScreen.routeName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  const SizedBox(
                    width: 260,
                    child: Text(
                      'Track a new option position',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  AppSecondaryButton(
                    label: 'New position',
                    icon: Icons.add_circle_outline,
                    onPressed: optionsState.isSaving
                        ? null
                        : () => _openEditor(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (optionsState.errorMessage != null) ...[
              AppInfoBanner(
                title: 'Options portfolio unavailable',
                message: optionsState.errorMessage!,
                icon: Icons.warning_amber_outlined,
                accentColor: AppTheme.danger,
              ),
              const SizedBox(height: 12),
            ],
            if (!hasContent) ...[
              const EmptyStateView(
                title: 'No option positions yet',
                message:
                    'Add a covered call, cash-secured put, or wheel leg to start tracking premium income.',
                icon: Icons.casino_outlined,
              ),
            ] else ...[
              const SectionHeader('Upcoming expirations'),
              if (analytics.upcomingExpirations.isEmpty)
                const EmptyStateView(
                  title: 'No open expirations',
                  message: 'Open positions will appear here.',
                  icon: Icons.event_outlined,
                )
              else
                _UpcomingList(
                  positions: analytics.upcomingExpirations.take(5).toList(),
                  marketState: marketState,
                ),
              const SectionHeader('Open positions'),
              ...optionsState.openPositions.map(
                (position) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PositionCard(
                    position: position,
                    currentPrice: marketState
                        .assetBySymbol(position.underlyingSymbol)
                        .price,
                    onClose: () => _confirmClose(
                      context,
                      optionsState,
                      position,
                      marketState
                          .assetBySymbol(position.underlyingSymbol)
                          .price,
                    ),
                    onExpire: () =>
                        _confirmExpire(context, optionsState, position),
                    onAssign: () => _confirmAssign(
                      context,
                      optionsState,
                      position,
                      marketState
                          .assetBySymbol(position.underlyingSymbol)
                          .price,
                    ),
                    onDelete: () =>
                        _confirmDelete(context, optionsState, position),
                    onJournal: () => _openJournal(context, position),
                  ),
                ),
              ),
              if (optionsState.closedPositions.isNotEmpty) ...[
                const SectionHeader('Closed positions'),
                ...optionsState.closedPositions
                    .take(6)
                    .map(
                      (position) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ClosedPositionCard(
                          position: position,
                          currentPrice: marketState
                              .assetBySymbol(position.underlyingSymbol)
                              .price,
                        ),
                      ),
                    ),
              ],
            ],
          ],
        );
      },
    );
  }

  void _openEditor(BuildContext context, {OptionPosition? position}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OptionPositionEditorScreen(initialPosition: position),
      ),
    );
  }

  Future<void> _confirmClose(
    BuildContext context,
    OptionsPortfolioState state,
    OptionPosition position,
    double currentPrice,
  ) async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Close option position?',
      content:
          'This records a close on ${position.displayTitle} and preserves the trade history.',
      actionLabel: 'Close position',
    );
    if (confirmed != true) {
      return;
    }
    await state.closePosition(
      position.id,
      currentUnderlyingPrice: currentPrice,
    );
  }

  Future<void> _confirmExpire(
    BuildContext context,
    OptionsPortfolioState state,
    OptionPosition position,
  ) async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Mark expired worthless?',
      content:
          'This marks ${position.displayTitle} as expired and records premium income.',
      actionLabel: 'Mark expired',
    );
    if (confirmed != true) {
      return;
    }
    await state.markExpired(position.id);
  }

  Future<void> _confirmAssign(
    BuildContext context,
    OptionsPortfolioState state,
    OptionPosition position,
    double currentPrice,
  ) async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Mark assignment?',
      content:
          'This marks ${position.displayTitle} as assigned and updates the lifecycle metrics.',
      actionLabel: 'Mark assigned',
    );
    if (confirmed != true) {
      return;
    }
    await state.markAssigned(position.id, currentUnderlyingPrice: currentPrice);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OptionsPortfolioState state,
    OptionPosition position,
  ) async {
    final confirmed = await _confirmAction(
      context: context,
      title: 'Delete option position?',
      content:
          'This removes ${position.displayTitle} and its linked lifecycle entries from this local device.',
      actionLabel: 'Delete position',
    );
    if (confirmed != true) {
      return;
    }
    await state.deletePosition(position.id);
  }

  Future<void> _openJournal(
    BuildContext context,
    OptionPosition position,
  ) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalEditorScreen(
          prefillTitle: 'Review: ${position.displayTitle}',
          prefillBody:
              'Review the rationale, risk, and outcome for ${position.displayTitle}.',
          prefillLinkedOrderId: position.id,
          prefillLinkedAssetSymbol: position.underlyingSymbol,
          prefillLinkedStrategy: _journalStrategy(position),
          prefillLessonsLearned: position.notes,
          prefillTags: [
            'options',
            position.linkedStrategy?.label.toLowerCase() ?? 'standalone',
          ],
        ),
      ),
    );
  }

  JournalStrategyType _journalStrategy(OptionPosition position) {
    return switch (position.linkedStrategy) {
      OptionStrategy.coveredCall => JournalStrategyType.coveredCall,
      OptionStrategy.cashSecuredPut => JournalStrategyType.cashSecuredPut,
      OptionStrategy.wheel => JournalStrategyType.wheel,
      null => JournalStrategyType.stockTrade,
    };
  }

  Future<bool?> _confirmAction({
    required BuildContext context,
    required String title,
    required String content,
    required String actionLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.analytics, required this.optionsState});

  final OptionsIncomeAnalytics analytics;
  final OptionsPortfolioState optionsState;

  @override
  Widget build(BuildContext context) {
    final stats = [
      AppStatTile(
        label: 'Premium collected',
        value: _money(analytics.totalPremiumCollected),
      ),
      AppStatTile(
        label: 'Open premium',
        value: _money(analytics.openPremiumAtRisk),
      ),
      AppStatTile(
        label: 'Open contracts',
        value: analytics.openContractsCount.toString(),
      ),
      AppStatTile(
        label: 'Assignments',
        value: analytics.assignmentsCount.toString(),
      ),
    ];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Premium income overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: stats),
          const SizedBox(height: 14),
          _BarRow(
            label: 'Premium by strategy',
            segments: [
              ...analytics.premiumByStrategy.entries.map(
                (entry) => _Segment(
                  label: entry.key.label,
                  value: entry.value,
                  color: _strategyColor(entry.key),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BarRow(
            label: 'Cash-secured exposure',
            segments: [
              _Segment(
                label: 'Open premium',
                value: analytics.openPremiumAtRisk,
                color: AppTheme.primary,
              ),
              _Segment(
                label: 'Closed P/L',
                value: analytics.realizedOptionsProfitLoss.abs(),
                color: analytics.realizedOptionsProfitLoss >= 0
                    ? AppTheme.primary
                    : AppTheme.danger,
              ),
            ],
          ),
          if (optionsState.isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 8),
          Text(
            'Updated ${_formatTimestamp(optionsState.lastUpdated ?? DateTime.now())}',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({required this.positions, required this.marketState});

  final List<OptionPosition> positions;
  final MarketState marketState;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: positions
          .map(
            (position) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            position.displayTitle,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${position.linkedStrategy?.label ?? 'Standalone'} • ${position.side.label} • ${position.status.label}',
                            style: const TextStyle(color: Colors.white60),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AppPillChip(
                                label:
                                    '${position.daysToExpiration()}d to expiry',
                                selected: true,
                                onSelected: (_) {},
                                selectedColor: AppTheme.secondary,
                              ),
                              AppPillChip(
                                label:
                                    '${position.moneynessPercent(marketState.assetBySymbol(position.underlyingSymbol).price).toStringAsFixed(1)}%',
                                selected: true,
                                onSelected: (_) {},
                                selectedColor: AppTheme.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _money(position.totalPremium),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.position,
    required this.currentPrice,
    required this.onClose,
    required this.onExpire,
    required this.onAssign,
    required this.onDelete,
    required this.onJournal,
  });

  final OptionPosition position;
  final double currentPrice;
  final VoidCallback onClose;
  final VoidCallback onExpire;
  final VoidCallback onAssign;
  final VoidCallback onDelete;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    final moneyness = position.moneynessPercent(currentPrice);
    final yieldPercent = position.annualizedPremiumYieldPercent();
    final risk = position.assignmentRiskLabel(currentPrice);

    return AppCard(
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
                      position.displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${position.linkedStrategy?.label ?? 'Standalone'} • ${position.status.label} • ${position.side.label}',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(position.totalPremium),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Premium',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPillChip(
                label: '${position.contractsCount} contracts',
                selected: true,
                onSelected: (_) {},
                selectedColor: AppTheme.primary,
              ),
              AppPillChip(
                label: '${position.daysToExpiration()}d',
                selected: true,
                onSelected: (_) {},
                selectedColor: AppTheme.secondary,
              ),
              AppPillChip(
                label: '${moneyness.toStringAsFixed(1)}% moneyness',
                selected: true,
                onSelected: (_) {},
                selectedColor: AppTheme.warning,
              ),
              AppPillChip(
                label: risk.label,
                selected: true,
                onSelected: (_) {},
                selectedColor: risk == AssignmentRiskLevel.high
                    ? AppTheme.danger
                    : risk == AssignmentRiskLevel.medium
                    ? AppTheme.warning
                    : AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 155,
                child: AppStatTile(
                  label: 'Breakeven',
                  value: _money(position.breakeven),
                ),
              ),
              SizedBox(
                width: 155,
                child: AppStatTile(
                  label: 'Yield',
                  value: _percent(yieldPercent),
                ),
              ),
              SizedBox(
                width: 155,
                child: AppStatTile(
                  label: 'At risk',
                  value: _money(position.capitalAtRisk),
                ),
              ),
            ],
          ),
          if (position.notes != null && position.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              position.notes!,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              AppSecondaryButton(
                label: 'Add journal note',
                icon: Icons.menu_book_outlined,
                onPressed: onJournal,
              ),
              if (position.isOpen) ...[
                AppSecondaryButton(
                  label: 'Close',
                  icon: Icons.close,
                  onPressed: onClose,
                ),
                AppSecondaryButton(
                  label: 'Expire',
                  icon: Icons.event_busy_outlined,
                  onPressed: onExpire,
                ),
                AppSecondaryButton(
                  label: 'Assign',
                  icon: Icons.assignment_turned_in_outlined,
                  onPressed: onAssign,
                ),
              ],
              AppSecondaryButton(
                label: 'Delete',
                icon: Icons.delete_outline,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClosedPositionCard extends StatelessWidget {
  const _ClosedPositionCard({
    required this.position,
    required this.currentPrice,
  });

  final OptionPosition position;
  final double currentPrice;

  @override
  Widget build(BuildContext context) {
    final risk = position.assignmentRiskLabel(currentPrice);

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.displayTitle,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${position.status.label} • ${position.linkedStrategy?.label ?? 'Standalone'}',
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppPillChip(
                label: risk.label,
                selected: true,
                onSelected: (_) {},
                selectedColor: risk == AssignmentRiskLevel.high
                    ? AppTheme.danger
                    : AppTheme.secondary,
              ),
              const SizedBox(height: 8),
              Text(
                _money(position.totalPremium),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.segments});

  final String label;
  final List<_Segment> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (total <= 0)
          const Text('No data yet', style: TextStyle(color: Colors.white54))
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: segments
                  .map(
                    (segment) => Expanded(
                      flex:
                          (segment.value <= 0
                                  ? 1
                                  : (segment.value / total * 100).round())
                              .clamp(1, 100)
                              .toInt(),
                      child: Container(
                        height: 10,
                        color: segment.color,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: segments
              .map(
                (segment) => AppPillChip(
                  label: segment.label,
                  selected: true,
                  onSelected: (_) {},
                  selectedColor: segment.color,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _Segment {
  const _Segment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

Color _strategyColor(OptionStrategy strategy) {
  return switch (strategy) {
    OptionStrategy.coveredCall => AppTheme.primary,
    OptionStrategy.cashSecuredPut => AppTheme.secondary,
    OptionStrategy.wheel => AppTheme.warning,
  };
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _percent(double value) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';

String _formatTimestamp(DateTime timestamp) {
  final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final period = timestamp.hour >= 12 ? 'PM' : 'AM';
  return '${timestamp.month}/${timestamp.day}/${timestamp.year} $hour:$minute $period';
}
