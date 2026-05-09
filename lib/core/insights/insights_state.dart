import 'package:flutter/widgets.dart';

import '../data/market_state.dart';
import '../data/paper_trading_state.dart';
import '../journal/journal_state.dart';
import '../options_portfolio/options_portfolio_state.dart';
import '../utils/app_logger.dart';
import 'trader_behavior_analytics.dart';
import 'trader_insight.dart';

class InsightsState extends ChangeNotifier {
  InsightsState({
    required JournalState journalState,
    required PaperTradingState paperTradingState,
    required OptionsPortfolioState optionsState,
    required MarketState marketState,
  }) : _journalState = journalState,
       _paperTradingState = paperTradingState,
       _optionsState = optionsState,
       _marketState = marketState {
    _attachListeners();
    refreshInsights();
  }

  final JournalState _journalState;
  final PaperTradingState _paperTradingState;
  final OptionsPortfolioState _optionsState;
  final MarketState _marketState;
  late final VoidCallback _sourceListener = _onSourceChanged;
  TraderBehaviorAnalytics? _analytics;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  TraderBehaviorAnalytics? get analytics => _analytics;

  List<TraderInsight> get insights =>
      List.unmodifiable(_analytics?.insights ?? const []);

  List<TraderInsight> get positiveInsights => List.unmodifiable(
    insights
        .where((insight) => insight.severity == TraderInsightSeverity.positive)
        .toList(growable: false),
  );

  List<TraderInsight> get warnings => List.unmodifiable(
    insights
        .where((insight) => insight.severity == TraderInsightSeverity.warning)
        .toList(growable: false),
  );

  List<TraderInsight> get criticalInsights => List.unmodifiable(
    insights
        .where((insight) => insight.severity == TraderInsightSeverity.critical)
        .toList(growable: false),
  );

  Future<void> refreshInsights() async {
    if (_isDisposed) {
      return;
    }
    _setLoading(true);
    try {
      _analytics = TraderBehaviorAnalytics.fromState(
        journalState: _journalState,
        paperTradingState: _paperTradingState,
        optionsState: _optionsState,
        marketState: _marketState,
      );
      _errorMessage = null;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Insights refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to calculate trader insights.';
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _journalState.removeListener(_sourceListener);
    _paperTradingState.removeListener(_sourceListener);
    _optionsState.removeListener(_sourceListener);
    _marketState.removeListener(_sourceListener);
    super.dispose();
  }

  void _attachListeners() {
    _journalState.addListener(_sourceListener);
    _paperTradingState.addListener(_sourceListener);
    _optionsState.addListener(_sourceListener);
    _marketState.addListener(_sourceListener);
  }

  void _onSourceChanged() {
    refreshInsights();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

class InsightsScope extends InheritedNotifier<InsightsState> {
  const InsightsScope({
    required InsightsState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static InsightsState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<InsightsScope>();
    assert(scope != null, 'InsightsScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
