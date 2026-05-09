import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/journal/journal_editor_screen.dart';
import 'package:trading_app/core/journal/journal_entry.dart';
import 'package:trading_app/core/journal/journal_state.dart';
import 'package:trading_app/core/journal/local_journal_repository.dart';
import 'package:trading_app/core/journal/journal_store.dart';
import 'package:trading_app/features/journal/journal_screen.dart';

void main() {
  testWidgets('Journal screen renders empty state', (tester) async {
    final state = JournalState(
      repository: LocalJournalRepository(store: MemoryJournalStore()),
    );

    await tester.pumpWidget(
      _journalHarness(state: state, child: const JournalScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('No journal entries yet'), findsOneWidget);
    expect(find.text('New entry'), findsOneWidget);
  });

  testWidgets('Journal screen renders populated entries', (tester) async {
    final state = JournalState(
      repository: LocalJournalRepository(store: MemoryJournalStore()),
    );
    await state.addEntry(
      JournalEntry(
        id: 'journal-1',
        createdAt: DateTime(2025, 1, 1, 10),
        updatedAt: DateTime(2025, 1, 2, 10),
        title: 'AAPL review',
        body: 'Followed the plan.',
        linkedAssetSymbol: 'AAPL',
        linkedStrategy: JournalStrategyType.stockTrade,
        mood: JournalMood.disciplined,
        convictionRating: 4,
        riskRating: 2,
        outcome: JournalOutcome.win,
        lessonsLearned: 'Keep sizing controlled.',
        tags: const ['review'],
      ),
    );

    await tester.pumpWidget(
      _journalHarness(state: state, child: const JournalScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('AAPL review'), findsOneWidget);
    expect(find.text('Lessons learned'), findsOneWidget);
    expect(find.text('Keep sizing controlled.'), findsOneWidget);
  });

  testWidgets('Create journal entry flow saves entry', (tester) async {
    final state = JournalState(
      repository: LocalJournalRepository(store: MemoryJournalStore()),
    );

    await tester.pumpWidget(
      _journalHarness(state: state, child: const JournalEditorScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('New journal entry'), findsOneWidget);
    final formFields = find.byType(TextFormField);
    await tester.enterText(formFields.at(0), 'Trade review');
    await tester.enterText(formFields.at(1), 'Notes for the trade.');
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    expect(state.entries, hasLength(1));
    expect(state.entries.single.title, 'Trade review');
  });
}

Widget _journalHarness({required JournalState state, required Widget child}) {
  return JournalScope(
    state: state,
    child: MaterialApp(theme: ThemeData.dark(useMaterial3: true), home: child),
  );
}
