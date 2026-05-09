import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/local_paper_trading_repository.dart';
import 'package:trading_app/core/data/market_state.dart';
import 'package:trading_app/core/data/paper_trading_account.dart';
import 'package:trading_app/core/data/paper_trading_state.dart';
import 'package:trading_app/core/insights/insights_state.dart';
import 'package:trading_app/core/journal/journal_entry.dart';
import 'package:trading_app/core/journal/journal_state.dart';
import 'package:trading_app/core/journal/local_journal_repository.dart';
import 'package:trading_app/core/journal/journal_store.dart';
import 'package:trading_app/core/options_portfolio/local_options_portfolio_repository.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_state.dart';
import 'package:trading_app/core/options_portfolio/options_portfolio_store.dart';
import 'package:trading_app/features/insights/insights_screen.dart';

void main() {
  testWidgets('Insights screen renders empty state', (tester) async {
    await tester.pumpWidget(
      _harness(
        insightsState: _emptyInsightsState(),
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No insights yet'), findsOneWidget);
    expect(find.text('Trader insights'), findsOneWidget);
  });

  testWidgets('Insights screen renders populated insights', (tester) async {
    final journalState = JournalState(
      repository: LocalJournalRepository(store: MemoryJournalStore()),
    );
    await journalState.addEntry(
      JournalEntry(
        id: '1',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        title: 'Review',
        body: 'Stayed patient and followed the plan.',
        linkedAssetSymbol: 'NVO',
        linkedStrategy: JournalStrategyType.coveredCall,
        mood: JournalMood.confident,
        convictionRating: 5,
        riskRating: 2,
        outcome: JournalOutcome.win,
        lessonsLearned: 'Discipline helped.',
        tags: const ['plan', 'discipline'],
      ),
    );
    await journalState.addEntry(
      JournalEntry(
        id: '2',
        createdAt: DateTime(2025, 1, 2),
        updatedAt: DateTime(2025, 1, 2),
        title: 'Review',
        body: 'Rushed the setup.',
        linkedAssetSymbol: 'NVO',
        linkedStrategy: JournalStrategyType.wheel,
        mood: JournalMood.anxious,
        convictionRating: 4,
        riskRating: 5,
        outcome: JournalOutcome.loss,
        lessonsLearned: 'Need a checklist.',
        tags: const ['fomo', 'fomo'],
      ),
    );
    await journalState.addEntry(
      JournalEntry(
        id: '3',
        createdAt: DateTime(2025, 1, 3),
        updatedAt: DateTime(2025, 1, 3),
        title: 'Review',
        body: 'Another rushed trade.',
        linkedAssetSymbol: 'NVO',
        linkedStrategy: JournalStrategyType.wheel,
        mood: JournalMood.anxious,
        convictionRating: 4,
        riskRating: 4,
        outcome: JournalOutcome.loss,
        lessonsLearned: 'Stay patient.',
        tags: const ['fomo'],
      ),
    );

    final insightsState = InsightsState(
      journalState: journalState,
      paperTradingState: PaperTradingState.fromAccount(
        PaperTradingAccount.defaultAccount(),
        repository: const LocalPaperTradingRepository(),
      ),
      optionsState: OptionsPortfolioState(
        repository: LocalOptionsPortfolioRepository(
          store: MemoryOptionsPortfolioStore(),
        ),
      ),
      marketState: MarketState(),
    );
    await insightsState.refreshInsights();

    await tester.pumpWidget(
      _harness(
        insightsState: insightsState,
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Most common mood: Anxious'), findsOneWidget);
    expect(find.text('Risk warnings'), findsOneWidget);
    expect(find.text('How this is calculated'), findsOneWidget);
  });
}

Widget _harness({required InsightsState insightsState, required Widget child}) {
  return InsightsScope(state: insightsState, child: child);
}

InsightsState _emptyInsightsState() {
  return InsightsState(
    journalState: JournalState(
      repository: LocalJournalRepository(store: MemoryJournalStore()),
    ),
    paperTradingState: PaperTradingState.fromAccount(
      PaperTradingAccount.defaultAccount(),
      repository: const LocalPaperTradingRepository(),
    ),
    optionsState: OptionsPortfolioState(
      repository: LocalOptionsPortfolioRepository(
        store: MemoryOptionsPortfolioStore(),
      ),
    ),
    marketState: MarketState(),
  );
}
