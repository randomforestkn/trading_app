import 'dart:convert';

import '../data/app_result.dart';
import '../utils/app_logger.dart';
import 'journal_entry.dart';
import 'journal_repository.dart';
import 'journal_store.dart';

class LocalJournalRepository implements JournalRepository {
  const LocalJournalRepository({this.store});

  final JournalStore? store;

  @override
  Future<AppResult<List<JournalEntry>>> loadEntries() async {
    final savedEntries = await store?.read();
    if (savedEntries == null) {
      return const AppSuccess(<JournalEntry>[]);
    }

    try {
      final decoded = jsonDecode(savedEntries);
      if (decoded is! List) {
        throw const FormatException('Saved journal entries must be a list.');
      }
      final entries = decoded
          .map((item) {
            if (item is! Map) {
              return null;
            }
            return JournalEntry.fromJson(
              Map<String, Object?>.from(item.cast<String, dynamic>()),
            );
          })
          .whereType<JournalEntry>()
          .toList(growable: false);
      return AppSuccess(entries);
    } on FormatException catch (error, stackTrace) {
      AppLogger.warn(
        'Journal storage contained invalid data',
        error: error,
        stackTrace: stackTrace,
      );
      await store?.clear();
      return const AppSuccess(<JournalEntry>[]);
    } on TypeError catch (error, stackTrace) {
      AppLogger.warn(
        'Journal storage contained invalid types',
        error: error,
        stackTrace: stackTrace,
      );
      await store?.clear();
      return const AppSuccess(<JournalEntry>[]);
    }
  }

  @override
  Future<AppResult<void>> saveEntries(List<JournalEntry> entries) async {
    await store?.write(
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> deleteEntry(String entryId) async {
    final currentEntries = await loadEntries();
    switch (currentEntries) {
      case AppSuccess<List<JournalEntry>>(data: final entries):
        final updatedEntries = entries
            .where((entry) => entry.id != entryId)
            .toList(growable: false);
        return saveEntries(updatedEntries);
      case AppFailure<List<JournalEntry>>(message: final message):
        return AppFailure(message);
    }
  }

  @override
  Future<AppResult<void>> clearEntries() async {
    await store?.clear();
    return const AppSuccess(null);
  }
}
