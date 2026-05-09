import '../data/app_result.dart';
import 'journal_entry.dart';

abstract class JournalRepository {
  Future<AppResult<List<JournalEntry>>> loadEntries();

  Future<AppResult<void>> saveEntries(List<JournalEntry> entries);

  Future<AppResult<void>> deleteEntry(String entryId);

  Future<AppResult<void>> clearEntries();
}
