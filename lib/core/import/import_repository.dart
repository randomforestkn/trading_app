import '../data/app_result.dart';
import 'import_result.dart';
import 'restore_plan.dart';

abstract class ImportRepository {
  Future<AppResult<RestorePlan>> previewBackup(String backupJson);

  Future<AppResult<ImportResult>> restoreBackup(
    String backupJson, {
    ImportRestoreMode mode = ImportRestoreMode.replace,
  });
}
