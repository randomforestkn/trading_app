import '../config/app_config.dart';
import '../data/app_result.dart';
import 'csv_exporter.dart';
import 'export_bundle.dart';
import 'export_format.dart';
import 'export_repository.dart';
import 'export_result.dart';
import 'json_backup_exporter.dart';
import 'report_generator.dart';

class LocalExportRepository implements ExportRepository {
  const LocalExportRepository();

  @override
  Future<AppResult<ExportResult>> exportJsonBackup(ExportBundle bundle) async {
    return _buildResult(
      bundle: bundle,
      format: ExportFormat.jsonBackup,
      content: JsonBackupExporter.encode(bundle),
    );
  }

  @override
  Future<AppResult<ExportResult>> exportJournalCsv(ExportBundle bundle) async {
    return _buildResult(
      bundle: bundle,
      format: ExportFormat.journalCsv,
      content: CsvExporter.journalEntries(bundle.journalEntries),
    );
  }

  @override
  Future<AppResult<ExportResult>> exportPaperTradesCsv(
    ExportBundle bundle,
  ) async {
    final account = bundle.paperTradingAccount;
    if (account == null) {
      return const AppFailure('Paper trading snapshot is missing.');
    }
    return _buildResult(
      bundle: bundle,
      format: ExportFormat.paperTradesCsv,
      content: CsvExporter.paperOrders(account.orders),
    );
  }

  @override
  Future<AppResult<ExportResult>> exportOptionsPositionsCsv(
    ExportBundle bundle,
  ) async {
    final account = bundle.optionsPortfolioAccount;
    if (account == null) {
      return const AppFailure('Options portfolio snapshot is missing.');
    }
    return _buildResult(
      bundle: bundle,
      format: ExportFormat.optionsPositionsCsv,
      content: CsvExporter.optionPositions(account.positions),
    );
  }

  @override
  Future<AppResult<ExportResult>> exportOptionsTradesCsv(
    ExportBundle bundle,
  ) async {
    final account = bundle.optionsPortfolioAccount;
    if (account == null) {
      return const AppFailure('Options portfolio snapshot is missing.');
    }
    return _buildResult(
      bundle: bundle,
      format: ExportFormat.optionsTradesCsv,
      content: CsvExporter.optionTrades(account.trades),
    );
  }

  @override
  Future<AppResult<ExportResult>> exportPerformanceReport(
    ExportBundle bundle,
  ) async {
    return _buildResult(
      bundle: bundle,
      format: ExportFormat.performanceReport,
      content: ReportGenerator.generate(bundle),
    );
  }

  Future<AppResult<ExportResult>> _buildResult({
    required ExportBundle bundle,
    required ExportFormat format,
    required String content,
  }) async {
    final createdAt = DateTime.now();
    final filename = _filename(format, createdAt);
    return AppSuccess(
      ExportResult(
        filename: filename,
        mimeType: format.mimeType,
        content: content,
        createdAt: createdAt,
        format: format,
        includedSections: bundle.includedSections,
      ),
    );
  }

  String _filename(ExportFormat format, DateTime createdAt) {
    final stamp = _stamp(createdAt);
    return switch (format) {
      ExportFormat.jsonBackup =>
        '${AppConfig.appName.toLowerCase()}_backup_$stamp.json',
      ExportFormat.journalCsv =>
        '${AppConfig.appName.toLowerCase()}_journal_$stamp.csv',
      ExportFormat.paperTradesCsv =>
        '${AppConfig.appName.toLowerCase()}_paper_trades_$stamp.csv',
      ExportFormat.optionsPositionsCsv =>
        '${AppConfig.appName.toLowerCase()}_options_positions_$stamp.csv',
      ExportFormat.optionsTradesCsv =>
        '${AppConfig.appName.toLowerCase()}_options_trades_$stamp.csv',
      ExportFormat.performanceReport =>
        '${AppConfig.appName.toLowerCase()}_performance_report_$stamp.md',
    };
  }

  String _stamp(DateTime value) {
    String twoDigits(int input) => input.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${local.year}${twoDigits(local.month)}${twoDigits(local.day)}'
        '_${twoDigits(local.hour)}${twoDigits(local.minute)}${twoDigits(local.second)}';
  }
}
