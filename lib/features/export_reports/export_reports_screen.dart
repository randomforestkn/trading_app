import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/analytics/trading_analytics.dart';
import '../../core/config/app_config.dart';
import '../../core/data/app_result.dart';
import '../../core/data/auth_state.dart';
import '../../core/data/market_state.dart';
import '../../core/data/paper_trading_account.dart';
import '../../core/data/paper_trading_state.dart';
import '../../core/export/export_bundle.dart';
import '../../core/export/export_format.dart';
import '../../core/export/export_repository.dart';
import '../../core/export/export_result.dart';
import '../../core/export/local_export_repository.dart';
import '../../core/journal/journal_state.dart';
import '../../core/insights/insights_state.dart';
import '../../core/options_portfolio/options_income_analytics.dart';
import '../../core/options_portfolio/options_portfolio_account.dart';
import '../../core/options_portfolio/options_portfolio_state.dart';
import '../../core/sync/sync_state.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/section_header.dart';

class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({super.key, this.repository});

  static const routeName = '/export-reports';

  final ExportRepository? repository;

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  ExportResult? _lastResult;
  String? _lastError;

  ExportRepository get _repository =>
      widget.repository ?? const LocalExportRepository();

  @override
  Widget build(BuildContext context) {
    final paperState = PaperTradingScope.of(context);
    final journalState = JournalScope.of(context);
    final optionsState = OptionsPortfolioScope.of(context);
    final marketState = MarketScope.of(context);
    final authState = AuthScope.of(context);
    final syncState = SyncScope.of(context);
    final insightsState = InsightsScope.of(context);

    return AppPage(
      title: 'Export & reports',
      subtitle: 'Local backups, CSV exports, and readable review reports',
      children: [
        AppInfoBanner(
          title: 'Local only',
          message: 'Exports are generated on this device. Nothing is uploaded.',
        ),
        const SectionHeader('Backup'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'JSON backup',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Portable backup with paper trading, journal, options, auth, sync, and analytics snapshots.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              AppPrimaryButton(
                label: 'Generate JSON backup',
                icon: Icons.backup_outlined,
                onPressed: () => _generate(
                  context,
                  _buildBundle(
                    format: ExportFormat.jsonBackup,
                    paperState: paperState,
                    journalState: journalState,
                    optionsState: optionsState,
                    marketState: marketState,
                    authState: authState,
                    syncState: syncState,
                    insightsState: insightsState,
                  ),
                  (repo, bundle) => repo.exportJsonBackup(bundle),
                ),
              ),
            ],
          ),
        ),
        const SectionHeader('CSV exports'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AppSecondaryButton(
                    label: 'Paper trades',
                    icon: Icons.receipt_long_outlined,
                    onPressed: () => _generate(
                      context,
                      _buildBundle(
                        format: ExportFormat.paperTradesCsv,
                        paperState: paperState,
                        journalState: journalState,
                        optionsState: optionsState,
                        marketState: marketState,
                        authState: authState,
                        syncState: syncState,
                        insightsState: insightsState,
                      ),
                      (repo, bundle) => repo.exportPaperTradesCsv(bundle),
                    ),
                  ),
                  AppSecondaryButton(
                    label: 'Journal',
                    icon: Icons.edit_note_outlined,
                    onPressed: () => _generate(
                      context,
                      _buildBundle(
                        format: ExportFormat.journalCsv,
                        paperState: paperState,
                        journalState: journalState,
                        optionsState: optionsState,
                        marketState: marketState,
                        authState: authState,
                        syncState: syncState,
                        insightsState: insightsState,
                      ),
                      (repo, bundle) => repo.exportJournalCsv(bundle),
                    ),
                  ),
                  AppSecondaryButton(
                    label: 'Options positions',
                    icon: Icons.all_inbox_outlined,
                    onPressed: () => _generate(
                      context,
                      _buildBundle(
                        format: ExportFormat.optionsPositionsCsv,
                        paperState: paperState,
                        journalState: journalState,
                        optionsState: optionsState,
                        marketState: marketState,
                        authState: authState,
                        syncState: syncState,
                        insightsState: insightsState,
                      ),
                      (repo, bundle) => repo.exportOptionsPositionsCsv(bundle),
                    ),
                  ),
                  AppSecondaryButton(
                    label: 'Options trades',
                    icon: Icons.compare_arrows_outlined,
                    onPressed: () => _generate(
                      context,
                      _buildBundle(
                        format: ExportFormat.optionsTradesCsv,
                        paperState: paperState,
                        journalState: journalState,
                        optionsState: optionsState,
                        marketState: marketState,
                        authState: authState,
                        syncState: syncState,
                        insightsState: insightsState,
                      ),
                      (repo, bundle) => repo.exportOptionsTradesCsv(bundle),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionHeader('Performance report'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Markdown review report',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'A human-readable summary of portfolio performance, options income, and trader behavior.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              AppPrimaryButton(
                label: 'Generate report',
                icon: Icons.description_outlined,
                onPressed: () => _generate(
                  context,
                  _buildBundle(
                    format: ExportFormat.performanceReport,
                    paperState: paperState,
                    journalState: journalState,
                    optionsState: optionsState,
                    marketState: marketState,
                    authState: authState,
                    syncState: syncState,
                    insightsState: insightsState,
                  ),
                  (repo, bundle) => repo.exportPerformanceReport(bundle),
                ),
              ),
            ],
          ),
        ),
        const SectionHeader('Includes'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsRow(
                label: 'App version',
                value: AppConfig.appVersionLabel,
              ),
              const Divider(height: 22),
              _SettingsRow(
                label: 'Build mode',
                value: AppConfig.buildModeLabel,
              ),
              const Divider(height: 22),
              const _SettingsRow(
                label: 'Storage',
                value: 'Local-first snapshot data',
              ),
              const Divider(height: 22),
              const Text(
                AppConfig.exportDisclaimer,
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
        const SectionHeader('Latest export'),
        _lastResult == null
            ? const EmptyStateView(
                title: 'No export generated yet',
                message:
                    'Generate a backup, CSV export, or report to preview the output here.',
                icon: Icons.archive_outlined,
              )
            : _ExportResultCard(
                result: _lastResult!,
                error: _lastError,
                onCopy: _copyLastResult,
              ),
      ],
    );
  }

  ExportBundle _buildBundle({
    required ExportFormat format,
    required PaperTradingState paperState,
    required JournalState journalState,
    required OptionsPortfolioState optionsState,
    required MarketState marketState,
    required AuthState authState,
    required SyncState syncState,
    required InsightsState insightsState,
  }) {
    final paperAccount = PaperTradingAccount.fromJson(
      Map<String, Object?>.from(paperState.toJson()),
    );
    final optionsAccount = OptionsPortfolioAccount.fromJson(
      Map<String, Object?>.from(optionsState.toJson()),
    );
    final behavior = insightsState.analytics;
    final performance = TradingAnalytics.performance(
      tradingState: paperState,
      marketState: marketState,
    );
    final portfolio = TradingAnalytics.portfolio(
      tradingState: paperState,
      marketState: marketState,
    );
    final activity = TradingAnalytics.activity(tradingState: paperState);

    final includedSections = <String>[
      'Paper trading',
      'Journal',
      'Options portfolio',
      'Performance',
      'Sync',
      'Auth',
    ];

    if (format == ExportFormat.journalCsv) {
      includedSections
        ..remove('Paper trading')
        ..remove('Options portfolio')
        ..remove('Performance')
        ..remove('Sync')
        ..remove('Auth');
    } else if (format == ExportFormat.paperTradesCsv) {
      includedSections
        ..remove('Journal')
        ..remove('Options portfolio')
        ..remove('Performance')
        ..remove('Sync')
        ..remove('Auth');
    } else if (format == ExportFormat.optionsPositionsCsv ||
        format == ExportFormat.optionsTradesCsv) {
      includedSections
        ..remove('Journal')
        ..remove('Paper trading')
        ..remove('Performance')
        ..remove('Sync')
        ..remove('Auth');
    }

    return ExportBundle(
      createdAt: DateTime.now(),
      appVersionLabel: AppConfig.appVersionLabel,
      buildModeLabel: AppConfig.buildModeLabel,
      marketModeLabel: marketState.dataMode.label,
      exportFormat: format,
      includedSections: includedSections,
      paperTradingAccount: paperAccount,
      journalEntries: journalState.entries,
      optionsPortfolioAccount: optionsAccount,
      performanceSnapshot: performance,
      portfolioAnalytics: portfolio,
      activityAnalytics: activity,
      optionsIncomeAnalytics: OptionsIncomeAnalytics.fromState(
        state: optionsState,
        marketState: marketState,
      ),
      behaviorAnalytics: behavior,
      syncMetadata: syncState.metadata,
      authSession: authState.currentSession,
    );
  }

  Future<void> _generate(
    BuildContext context,
    ExportBundle bundle,
    Future<AppResult<ExportResult>> Function(
      ExportRepository repo,
      ExportBundle bundle,
    )
    action,
  ) async {
    setState(() {
      _lastError = null;
    });
    final result = await action(_repository, bundle);
    result.when(
      success: (exportResult) {
        setState(() {
          _lastResult = exportResult;
          _lastError = null;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${exportResult.filename} generated.')),
          );
        }
      },
      failure: (message) {
        setState(() {
          _lastError = message;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );
  }

  Future<void> _copyLastResult() async {
    final result = _lastResult;
    if (result == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: result.content));
  }
}

class _ExportResultCard extends StatelessWidget {
  const _ExportResultCard({
    required this.result,
    required this.onCopy,
    this.error,
  });

  final ExportResult result;
  final VoidCallback onCopy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final preview = _preview(result.content);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsRow(label: 'Filename', value: result.filename),
          const Divider(height: 22),
          _SettingsRow(label: 'Mime type', value: result.mimeType),
          const Divider(height: 22),
          _SettingsRow(
            label: 'Sections',
            value: result.includedSections.join(', '),
          ),
          const SizedBox(height: 12),
          Text('Preview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                preview,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppSecondaryButton(
            label: 'Copy content',
            icon: Icons.copy_outlined,
            onPressed: onCopy,
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: const TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _preview(String content) {
    final lines = content.trimRight().split('\n');
    if (lines.length <= 20) {
      return content;
    }
    return [...lines.take(20), '...'].join('\n');
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white60)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
