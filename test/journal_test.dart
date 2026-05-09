import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/app_result.dart';
import 'package:trading_app/core/journal/journal_entry.dart';
import 'package:trading_app/core/journal/journal_insights.dart';
import 'package:trading_app/core/journal/journal_state.dart';
import 'package:trading_app/core/journal/local_journal_repository.dart';
import 'package:trading_app/core/journal/journal_store.dart';

void main() {
  group('JournalEntry', () {
    test('serializes and deserializes backward compatibly', () {
      final original = JournalEntry(
        id: 'journal-1',
        createdAt: DateTime(2025, 1, 1, 10),
        updatedAt: DateTime(2025, 1, 2, 10),
        title: 'Covered call review',
        body: 'Managed the trade by the plan.',
        linkedOrderId: 'order-1',
        linkedAssetSymbol: 'AAPL',
        linkedStrategy: JournalStrategyType.coveredCall,
        mood: JournalMood.disciplined,
        convictionRating: 4,
        riskRating: 2,
        outcome: JournalOutcome.win,
        lessonsLearned: 'Take profits earlier when the move is extended.',
        tags: const ['options', 'review'],
      );

      final restored = JournalEntry.fromJsonString(original.toJsonString());

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.body, original.body);
      expect(restored.linkedStrategy, JournalStrategyType.coveredCall);
      expect(restored.mood, JournalMood.disciplined);
      expect(restored.outcome, JournalOutcome.win);
      expect(restored.tags, original.tags);
    });
  });

  group('LocalJournalRepository', () {
    test('save, load, and delete roundtrip works', () async {
      final store = MemoryJournalStore();
      final repository = LocalJournalRepository(store: store);
      final first = _entry(
        id: 'journal-1',
        title: 'AAPL trade review',
        asset: 'AAPL',
        strategy: JournalStrategyType.stockTrade,
      );
      final second = _entry(
        id: 'journal-2',
        title: 'Wheel setup',
        asset: 'SPY',
        strategy: JournalStrategyType.wheel,
      );

      await repository.saveEntries([first, second]);
      final loaded = await repository.loadEntries();

      expect(loaded is AppSuccess<List<JournalEntry>>, isTrue);
      expect((loaded as AppSuccess<List<JournalEntry>>).data, hasLength(2));

      await repository.deleteEntry('journal-1');
      final afterDelete = await repository.loadEntries();
      expect(
        (afterDelete as AppSuccess<List<JournalEntry>>).data,
        hasLength(1),
      );
      expect(afterDelete.data.single.id, 'journal-2');

      await repository.clearEntries();
      final afterClear = await repository.loadEntries();
      expect((afterClear as AppSuccess<List<JournalEntry>>).data, isEmpty);
    });
  });

  group('JournalState', () {
    test('add, update, delete, and filtering work', () async {
      final state = JournalState(
        repository: LocalJournalRepository(store: MemoryJournalStore()),
      );
      final first = _entry(
        id: 'journal-1',
        title: 'AAPL review',
        asset: 'AAPL',
        strategy: JournalStrategyType.stockTrade,
      );
      final second = _entry(
        id: 'journal-2',
        title: 'Covered call review',
        asset: 'AAPL',
        strategy: JournalStrategyType.coveredCall,
        outcome: JournalOutcome.win,
      );

      await state.addEntry(first);
      await state.addEntry(second);

      expect(state.entries, hasLength(2));
      expect(state.entriesForSymbol('AAPL'), hasLength(2));
      expect(
        state.entriesForStrategy(JournalStrategyType.coveredCall),
        hasLength(1),
      );

      final updated = second.copyWith(
        title: 'Updated review',
        outcome: JournalOutcome.breakeven,
      );
      await state.updateEntry(updated);

      expect(state.entryById('journal-2')?.title, 'Updated review');
      expect(state.entriesForOutcome(JournalOutcome.breakeven), hasLength(1));

      await state.deleteEntry('journal-1');
      expect(state.entries, hasLength(1));
      expect(state.entryById('journal-1'), isNull);
      expect(state.recentEntries, hasLength(1));
    });

    test('insights summarize outcomes and ratings', () {
      final insights = JournalInsights.fromEntries([
        _entry(
          id: 'journal-1',
          title: 'Win',
          asset: 'AAPL',
          strategy: JournalStrategyType.stockTrade,
          mood: JournalMood.confident,
          conviction: 5,
          risk: 2,
          outcome: JournalOutcome.win,
        ),
        _entry(
          id: 'journal-2',
          title: 'Loss',
          asset: 'SPY',
          strategy: JournalStrategyType.coveredCall,
          mood: JournalMood.confident,
          conviction: 3,
          risk: 4,
          outcome: JournalOutcome.loss,
        ),
      ]);

      expect(insights.totalEntries, 2);
      expect(insights.mostCommonMood, JournalMood.confident);
      expect(insights.averageConviction, closeTo(4, 0.001));
      expect(insights.averageRisk, closeTo(3, 0.001));
      expect(insights.outcomeSummary, '1W / 1L / 0BE');
      expect(insights.mostTaggedStrategy, JournalStrategyType.stockTrade);
    });
  });
}

JournalEntry _entry({
  required String id,
  required String title,
  required String asset,
  required JournalStrategyType strategy,
  JournalMood? mood,
  JournalOutcome? outcome,
  int conviction = 4,
  int risk = 2,
}) {
  return JournalEntry(
    id: id,
    createdAt: DateTime(2025, 1, 1, 10),
    updatedAt: DateTime(2025, 1, 2, 10),
    title: title,
    body: 'Notes for $title.',
    linkedAssetSymbol: asset,
    linkedStrategy: strategy,
    mood: mood,
    convictionRating: conviction,
    riskRating: risk,
    outcome: outcome,
    lessonsLearned: 'Stay systematic.',
    tags: const ['review'],
  );
}
