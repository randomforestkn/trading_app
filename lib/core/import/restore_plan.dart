import '../config/app_config.dart';
import '../data/paper_trading_account.dart';
import '../journal/journal_entry.dart';
import '../models/auth_session.dart';
import '../options_portfolio/options_portfolio_account.dart';
import '../sync/sync_metadata.dart';
import '../export/export_format.dart';
import 'import_validation.dart';

enum ImportRestoreMode { replace, mergeJournalEntries, mergeOptionsPortfolio }

extension ImportRestoreModeLabel on ImportRestoreMode {
  String get label {
    return switch (this) {
      ImportRestoreMode.replace => 'Replace local data',
      ImportRestoreMode.mergeJournalEntries => 'Merge journal entries',
      ImportRestoreMode.mergeOptionsPortfolio => 'Merge options portfolio',
    };
  }
}

class RestorePlan {
  const RestorePlan({
    required this.backupVersion,
    required this.createdAt,
    required this.includedSections,
    required this.validation,
    this.exportFormat,
    this.paperTradingAccount,
    this.journalEntries = const [],
    this.optionsPortfolioAccount,
    this.syncMetadata,
    this.authSession,
    this.unsupportedSections = const [],
  });

  final int backupVersion;
  final DateTime createdAt;
  final ExportFormat? exportFormat;
  final List<String> includedSections;
  final PaperTradingAccount? paperTradingAccount;
  final List<JournalEntry> journalEntries;
  final OptionsPortfolioAccount? optionsPortfolioAccount;
  final SyncMetadata? syncMetadata;
  final AuthSession? authSession;
  final List<String> unsupportedSections;
  final ImportValidation validation;

  int get paperOrdersCount => paperTradingAccount?.orders.length ?? 0;

  int get journalEntriesCount => journalEntries.length;

  int get optionsPositionsCount =>
      optionsPortfolioAccount?.positions.length ?? 0;

  int get optionsTradesCount => optionsPortfolioAccount?.trades.length ?? 0;

  int get wheelCyclesCount => optionsPortfolioAccount?.wheelCycles.length ?? 0;

  bool get hasWarnings =>
      validation.hasWarnings || unsupportedSections.isNotEmpty;

  bool get hasErrors => validation.hasErrors;

  List<String> get warnings => [
    ...validation.warnings.map((issue) => issue.message),
    ...unsupportedSections.map((section) => 'Unsupported section: $section'),
  ];

  bool get canRestore => !hasErrors;

  Map<String, Object?> toJson() {
    return {
      'backupVersion': backupVersion,
      'createdAt': createdAt.toIso8601String(),
      'exportFormat': exportFormat?.name,
      'includedSections': includedSections,
      'paperOrdersCount': paperOrdersCount,
      'journalEntriesCount': journalEntriesCount,
      'optionsPositionsCount': optionsPositionsCount,
      'optionsTradesCount': optionsTradesCount,
      'wheelCyclesCount': wheelCyclesCount,
      'unsupportedSections': unsupportedSections,
      'validation': {
        'issues': validation.issues
            .map(
              (issue) => {
                'message': issue.message,
                'severity': issue.severity.name,
              },
            )
            .toList(growable: false),
      },
      'hasBackupData':
          paperTradingAccount != null ||
          journalEntries.isNotEmpty ||
          optionsPortfolioAccount != null,
    };
  }

  static RestorePlan empty({DateTime? createdAt, String? reason}) {
    final issues = <String>[];
    if (reason != null && reason.isNotEmpty) {
      issues.add(reason);
    }
    return RestorePlan(
      backupVersion: AppConfig.backupFormatVersion,
      createdAt: createdAt ?? DateTime.now(),
      includedSections: const [],
      validation: ImportValidation(
        issues: issues
            .map(
              (message) => ImportValidationIssue(
                message: message,
                severity: ImportValidationSeverity.error,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
