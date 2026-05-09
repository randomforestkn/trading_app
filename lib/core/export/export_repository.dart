import '../data/app_result.dart';
import 'export_bundle.dart';
import 'export_result.dart';

abstract class ExportRepository {
  Future<AppResult<ExportResult>> exportJsonBackup(ExportBundle bundle);

  Future<AppResult<ExportResult>> exportJournalCsv(ExportBundle bundle);

  Future<AppResult<ExportResult>> exportPaperTradesCsv(ExportBundle bundle);

  Future<AppResult<ExportResult>> exportOptionsPositionsCsv(
    ExportBundle bundle,
  );

  Future<AppResult<ExportResult>> exportOptionsTradesCsv(ExportBundle bundle);

  Future<AppResult<ExportResult>> exportPerformanceReport(ExportBundle bundle);
}
