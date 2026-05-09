import '../config/app_config.dart';
import '../data/app_result.dart';
import '../data/auth_state.dart';
import '../data/paper_trading_state.dart';
import '../journal/journal_state.dart';
import '../models/auth_session.dart';
import '../options_portfolio/options_portfolio_state.dart';
import '../sync/sync_state.dart';
import '../utils/app_logger.dart';
import 'backup_parser.dart';
import 'import_repository.dart';
import 'import_result.dart';
import 'restore_plan.dart';

class LocalImportRepository implements ImportRepository {
  const LocalImportRepository({
    required this.paperTradingState,
    required this.journalState,
    required this.optionsPortfolioState,
    this.authState,
    this.syncState,
  });

  final PaperTradingState paperTradingState;
  final JournalState journalState;
  final OptionsPortfolioState optionsPortfolioState;
  final AuthState? authState;
  final SyncState? syncState;

  @override
  Future<AppResult<RestorePlan>> previewBackup(String backupJson) async {
    return BackupParser.parse(backupJson);
  }

  @override
  Future<AppResult<ImportResult>> restoreBackup(
    String backupJson, {
    ImportRestoreMode mode = ImportRestoreMode.replace,
  }) async {
    if (mode != ImportRestoreMode.replace) {
      return const AppFailure<ImportResult>(
        'Only replace restore mode is supported right now.',
      );
    }

    final previewResult = await previewBackup(backupJson);
    final preview = previewResult.when(
      success: (plan) => plan,
      failure: (message) => null,
    );
    if (preview == null) {
      return previewResult.when<AppResult<ImportResult>>(
        success: (_) =>
            const AppFailure<ImportResult>('Unable to preview backup.'),
        failure: (message) => AppFailure<ImportResult>(message),
      );
    }

    if (preview.hasErrors) {
      return AppFailure<ImportResult>(
        preview.validation.errors.map((issue) => issue.message).join(' '),
      );
    }

    final appliedSections = <String>[];
    final warnings = <String>[...preview.warnings];

    final paperResult = await paperTradingState.restoreFromAccount(
      preview.paperTradingAccount!,
      enqueueSync: true,
    );
    if (paperResult is AppFailure<void>) {
      return AppFailure<ImportResult>(paperResult.message);
    }
    appliedSections.add('Paper trading');

    final journalResult = await journalState.replaceEntries(
      preview.journalEntries,
      enqueueSync: true,
    );
    if (journalResult is AppFailure<void>) {
      return AppFailure<ImportResult>(journalResult.message);
    }
    appliedSections.add('Journal');

    final optionsResult = await optionsPortfolioState.replaceAccount(
      preview.optionsPortfolioAccount!,
      enqueueSync: true,
    );
    if (optionsResult is AppFailure<void>) {
      return AppFailure<ImportResult>(optionsResult.message);
    }
    appliedSections.add('Options portfolio');

    final authSession = preview.authSession;
    if (authSession != null) {
      final canRestoreAuth = _isSafeDemoSession(authSession);
      if (canRestoreAuth && authState != null) {
        final authResult = await authState!.restoreFromSession(authSession);
        if (authResult is AppFailure<void>) {
          return AppFailure<ImportResult>(authResult.message);
        }
        appliedSections.add('Auth');
      } else {
        warnings.add('Auth session was present but skipped for safety.');
      }
    }

    if (preview.syncMetadata != null && syncState != null) {
      await syncState!.restoreMetadata(preview.syncMetadata!);
      appliedSections.add('Sync metadata');
    } else if (preview.syncMetadata != null) {
      warnings.add('Sync metadata was present but no sync state was wired.');
    }

    final message = [
      'Restored ${appliedSections.join(', ')}.',
      if (warnings.isNotEmpty) warnings.join(' '),
    ].join(' ');

    final result = ImportResult(
      restorePlan: preview,
      restoredAt: DateTime.now(),
      appliedSections: appliedSections,
      mode: mode,
      message: message,
    );

    if (warnings.isNotEmpty) {
      AppLogger.warn(
        'Backup restore completed with warnings',
        error: warnings.join(' '),
      );
    }

    return AppSuccess(result);
  }

  bool _isSafeDemoSession(AuthSession session) {
    return session.user.id == AppConfig.demoUserId &&
        session.user.email == AppConfig.demoUserEmail &&
        session.user.displayName == AppConfig.demoUserDisplayName;
  }
}
