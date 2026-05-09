import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/journal/journal_entry.dart';
import '../../core/journal/journal_insights.dart';
import '../../core/journal/journal_state.dart';
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

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  static const routeName = '/journal';

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String? _selectedSymbol;
  JournalStrategyType? _selectedStrategy;
  JournalOutcome? _selectedOutcome;

  @override
  Widget build(BuildContext context) {
    final journalState = JournalScope.of(context);

    return AnimatedBuilder(
      animation: journalState,
      builder: (context, _) {
        final insights = JournalInsights.fromEntries(journalState.entries);
        final filteredEntries = _filteredEntries(journalState.entries);
        final hasFilters =
            _selectedSymbol != null ||
            _selectedStrategy != null ||
            _selectedOutcome != null;
        final entriesToShow = hasFilters
            ? filteredEntries
            : journalState.recentEntries;
        final title = hasFilters ? 'Filtered entries' : 'Recent entries';

        return AppPage(
          title: 'Journal',
          subtitle: 'Trade rationale, emotions, and reviews',
          actions: [
            IconButton(
              tooltip: 'New entry',
              onPressed: journalState.isSaving
                  ? null
                  : () => _openEditor(context),
              icon: const Icon(Icons.add),
            ),
          ],
          children: [
            const AppInfoBanner(
              title: 'Trading journal',
              message:
                  'Capture what you expected, how you felt, and what you will do differently next time. Notes stay on this device.',
              icon: Icons.menu_book_outlined,
              accentColor: AppTheme.secondary,
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
                    width: 250,
                    child: Text(
                      'Analyze journal patterns',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  AppSecondaryButton(
                    label: 'Open insights',
                    icon: Icons.insights_outlined,
                    onPressed: journalState.isLoading
                        ? null
                        : () => Navigator.of(
                            context,
                          ).pushNamed(InsightsScreen.routeName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InsightsCard(insights: insights),
            const SizedBox(height: 12),
            _FiltersCard(
              selectedSymbol: _selectedSymbol,
              selectedStrategy: _selectedStrategy,
              selectedOutcome: _selectedOutcome,
              entries: journalState.entries,
              onSymbolSelected: (symbol) =>
                  setState(() => _selectedSymbol = symbol),
              onStrategySelected: (strategy) =>
                  setState(() => _selectedStrategy = strategy),
              onOutcomeSelected: (outcome) =>
                  setState(() => _selectedOutcome = outcome),
              onClearFilters: hasFilters
                  ? () => setState(() {
                      _selectedSymbol = null;
                      _selectedStrategy = null;
                      _selectedOutcome = null;
                    })
                  : null,
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
                    width: 250,
                    child: Text(
                      'Create a new journal entry',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  AppPrimaryButton(
                    label: 'New entry',
                    icon: Icons.edit_note_outlined,
                    onPressed: journalState.isSaving
                        ? null
                        : () => _openEditor(context),
                  ),
                ],
              ),
            ),
            if (journalState.errorMessage != null) ...[
              const SizedBox(height: 12),
              AppInfoBanner(
                title: 'Journal unavailable',
                message: journalState.errorMessage!,
                icon: Icons.warning_amber_outlined,
                accentColor: AppTheme.danger,
              ),
            ],
            if (journalState.isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              const SectionHeader('Entry list'),
              if (journalState.entries.isEmpty)
                const EmptyStateView(
                  title: 'No journal entries yet',
                  message:
                      'Record a trade review, strategy note, or lesson learned to start building your journal.',
                  icon: Icons.book_outlined,
                )
              else if (entriesToShow.isEmpty)
                EmptyStateView(
                  title: 'No matching entries',
                  message:
                      'Adjust or clear your symbol, strategy, and outcome filters to see entries again.',
                  icon: Icons.filter_alt_off_outlined,
                  actionLabel: 'Clear filters',
                  onActionPressed: () => setState(() {
                    _selectedSymbol = null;
                    _selectedStrategy = null;
                    _selectedOutcome = null;
                  }),
                )
              else
                ...entriesToShow.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _JournalEntryCard(
                      entry: entry,
                      onEdit: () => _openEditor(context, entry: entry),
                      onDelete: () =>
                          _confirmDelete(context, journalState, entry),
                    ),
                  ),
                ),
            ],
            if (journalState.entries.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '$title ${entriesToShow.length} of ${journalState.entries.length}',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ],
        );
      },
    );
  }

  List<JournalEntry> _filteredEntries(List<JournalEntry> entries) {
    return entries
        .where((entry) {
          final matchesSymbol =
              _selectedSymbol == null ||
              entry.linkedAssetSymbol?.toLowerCase() ==
                  _selectedSymbol!.toLowerCase();
          final matchesStrategy =
              _selectedStrategy == null ||
              entry.linkedStrategy == _selectedStrategy;
          final matchesOutcome =
              _selectedOutcome == null || entry.outcome == _selectedOutcome;
          return matchesSymbol && matchesStrategy && matchesOutcome;
        })
        .toList(growable: false);
  }

  void _openEditor(BuildContext context, {JournalEntry? entry}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalEditorScreen(
          initialEntry: entry,
          prefillTitle: entry == null ? 'Trade review' : null,
          prefillLinkedAssetSymbol: _selectedSymbol,
          prefillLinkedStrategy: _selectedStrategy,
          prefillOutcome: _selectedOutcome,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    JournalState journalState,
    JournalEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete journal entry?'),
        content: const Text(
          'This note will be removed permanently from this device.',
        ),
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
            child: const Text('Delete entry'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await journalState.deleteEntry(entry.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Journal entry deleted.')));
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.insights});

  final JournalInsights insights;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      AppStatTile(label: 'Entries', value: insights.totalEntries.toString()),
      AppStatTile(
        label: 'Avg conviction',
        value: insights.totalEntries == 0
            ? '0.0'
            : insights.averageConviction.toStringAsFixed(1),
      ),
      AppStatTile(
        label: 'Avg risk',
        value: insights.totalEntries == 0
            ? '0.0'
            : insights.averageRisk.toStringAsFixed(1),
      ),
      AppStatTile(label: 'Outcomes', value: insights.outcomeSummary),
      AppStatTile(
        label: 'Most common mood',
        value: insights.mostCommonMood?.label ?? 'None',
      ),
      AppStatTile(
        label: 'Top strategy',
        value: insights.mostTaggedStrategy?.label ?? 'None',
      ),
    ];

    return AppCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: tiles
            .map((tile) => SizedBox(width: 170, child: tile))
            .toList(growable: false),
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.selectedSymbol,
    required this.selectedStrategy,
    required this.selectedOutcome,
    required this.entries,
    required this.onSymbolSelected,
    required this.onStrategySelected,
    required this.onOutcomeSelected,
    this.onClearFilters,
  });

  final String? selectedSymbol;
  final JournalStrategyType? selectedStrategy;
  final JournalOutcome? selectedOutcome;
  final List<JournalEntry> entries;
  final ValueChanged<String?> onSymbolSelected;
  final ValueChanged<JournalStrategyType?> onStrategySelected;
  final ValueChanged<JournalOutcome?> onOutcomeSelected;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final symbols =
        entries
            .where((entry) => entry.linkedAssetSymbol != null)
            .map((entry) => entry.linkedAssetSymbol!)
            .toSet()
            .toList()
          ..sort();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Filters',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (onClearFilters != null)
                AppSecondaryButton(
                  label: 'Clear',
                  icon: Icons.filter_alt_off_outlined,
                  onPressed: onClearFilters,
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Symbol', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPillChip(
                label: 'All',
                selected: selectedSymbol == null,
                onSelected: (selected) {
                  if (selected) {
                    onSymbolSelected(null);
                  }
                },
                selectedColor: AppTheme.primary,
              ),
              ...symbols.map(
                (symbol) => AppPillChip(
                  label: symbol,
                  selected: selectedSymbol == symbol,
                  onSelected: (selected) {
                    onSymbolSelected(selected ? symbol : null);
                  },
                  selectedColor: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Strategy', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPillChip(
                label: 'All',
                selected: selectedStrategy == null,
                onSelected: (selected) {
                  if (selected) {
                    onStrategySelected(null);
                  }
                },
                selectedColor: AppTheme.secondary,
              ),
              ...JournalStrategyType.values.map(
                (strategy) => AppPillChip(
                  label: strategy.label,
                  selected: selectedStrategy == strategy,
                  onSelected: (selected) {
                    onStrategySelected(selected ? strategy : null);
                  },
                  selectedColor: AppTheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Outcome', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPillChip(
                label: 'All',
                selected: selectedOutcome == null,
                onSelected: (selected) {
                  if (selected) {
                    onOutcomeSelected(null);
                  }
                },
                selectedColor: AppTheme.warning,
              ),
              ...JournalOutcome.values.map(
                (outcome) => AppPillChip(
                  label: outcome.label,
                  selected: selectedOutcome == outcome,
                  onSelected: (selected) {
                    onOutcomeSelected(selected ? outcome : null);
                  },
                  selectedColor: AppTheme.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final JournalEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.displayTitle,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (entry.linkedStrategy != null) ...[
                AppPillChip(
                  label: entry.linkedStrategy!.label,
                  selected: true,
                  onSelected: (_) {},
                  selectedColor: AppTheme.secondary,
                ),
                const SizedBox(width: 8),
              ],
              if (entry.outcome != null)
                AppPillChip(
                  label: entry.outcome!.label,
                  selected: true,
                  onSelected: (_) {},
                  selectedColor: _outcomeColor(entry.outcome!),
                ),
            ],
          ),
          if (entry.linkedAssetSymbol != null || entry.mood != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (entry.linkedAssetSymbol != null)
                  AppPillChip(
                    label: entry.linkedAssetSymbol!,
                    selected: true,
                    onSelected: (_) {},
                    selectedColor: AppTheme.primary,
                  ),
                if (entry.mood != null)
                  AppPillChip(
                    label: entry.mood!.label,
                    selected: true,
                    onSelected: (_) {},
                    selectedColor: AppTheme.warning,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(entry.body, maxLines: 4, overflow: TextOverflow.ellipsis),
          if (entry.hasLessonsLearned) ...[
            const SizedBox(height: 12),
            AppInfoBanner(
              title: 'Lessons learned',
              message: entry.lessonsLearned!,
              icon: Icons.lightbulb_outline,
              accentColor: AppTheme.secondary,
            ),
          ],
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.tags
                  .map(
                    (tag) => AppPillChip(
                      label: tag,
                      selected: true,
                      onSelected: (_) {},
                      selectedColor: AppTheme.primary,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Created ${_formatTimestamp(entry.createdAt)} • Updated ${_formatTimestamp(entry.updatedAt)}',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            children: [
              AppSecondaryButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
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

  Color _outcomeColor(JournalOutcome outcome) {
    return switch (outcome) {
      JournalOutcome.win => AppTheme.primary,
      JournalOutcome.loss => AppTheme.danger,
      JournalOutcome.breakeven => AppTheme.warning,
      JournalOutcome.open => Colors.white70,
    };
  }

  String _formatTimestamp(DateTime timestamp) {
    final month = _monthName(timestamp.month);
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$month ${timestamp.day}, ${timestamp.year} at $hour:$minute';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
