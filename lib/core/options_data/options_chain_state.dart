import 'package:flutter/widgets.dart';

import '../data/app_result.dart';
import '../utils/app_logger.dart';
import '../strategies/option_contract.dart';
import 'options_chain_models.dart';
import 'options_chain_repository.dart';
import 'options_chain_repository_factory.dart';
import 'options_provider_config.dart';

class OptionsChainState extends ChangeNotifier {
  OptionsChainState({OptionsChainRepository? repository})
    : _repository = repository ?? OptionsChainRepositoryFactory.buildDefault();

  final OptionsChainRepository _repository;
  String? _selectedSymbol;
  DateTime? _selectedExpiration;
  List<DateTime> _expirations = const [];
  OptionChain? _chain;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  OptionsChainDataMode get dataMode => _repository.isRemoteOptionsData
      ? OptionsChainDataMode.remote
      : OptionsChainDataMode.manual;

  String? get selectedSymbol => _selectedSymbol;
  DateTime? get selectedExpiration => _selectedExpiration;
  List<DateTime> get expirations => List.unmodifiable(_expirations);
  OptionChain? get chain => _chain;
  bool get hasRemoteData => _chain != null && _chain!.quotes.isNotEmpty;

  static Future<OptionsChainState> load({
    OptionsChainRepository? repository,
    String? initialSymbol,
  }) async {
    final state = OptionsChainState(repository: repository);
    if (initialSymbol != null) {
      await state.setUnderlying(initialSymbol);
    }
    return state;
  }

  Future<void> setUnderlying(String symbol) async {
    if (_selectedSymbol == symbol) {
      return;
    }
    _selectedSymbol = symbol;
    _selectedExpiration = null;
    _chain = null;
    _expirations = const [];
    notifyListeners();
    await refreshExpirations();
  }

  Future<void> setExpiration(DateTime? expiration) async {
    _selectedExpiration = expiration;
    notifyListeners();
    if (expiration != null) {
      await refreshChain();
    }
  }

  Future<void> refreshExpirations() async {
    final symbol = _selectedSymbol;
    if (symbol == null || symbol.trim().isEmpty) {
      return;
    }
    _setLoading(true);
    late final AppResult<List<DateTime>> result;
    try {
      result = await _repository.fetchExpirations(symbol);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Options expirations refresh threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to load options expirations.';
      _setLoading(false);
      return;
    }
    result.when(
      success: (expirations) {
        _expirations = expirations;
        _errorMessage = null;
        if (_selectedExpiration == null && expirations.isNotEmpty) {
          _selectedExpiration = expirations.first;
        }
      },
      failure: (message) {
        AppLogger.warn('Options expirations refresh failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
    if (_selectedExpiration != null && _repository.isRemoteOptionsData) {
      await refreshChain();
    }
  }

  Future<void> refreshChain() async {
    final symbol = _selectedSymbol;
    final expiration = _selectedExpiration;
    if (symbol == null || expiration == null) {
      return;
    }
    _setLoading(true);
    late final AppResult<OptionChain> result;
    try {
      result = await _repository.fetchChain(symbol, expiration);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Options chain refresh threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to load options chain.';
      _setLoading(false);
      return;
    }
    result.when(
      success: (chain) {
        _chain = chain;
        _errorMessage = null;
        _lastUpdated = chain.updatedAt;
      },
      failure: (message) {
        AppLogger.warn('Options chain refresh failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
    notifyListeners();
  }

  OptionQuote? quoteFor({required OptionType type, required double strike}) {
    final chain = _chain;
    if (chain == null) {
      return null;
    }
    return chain.quoteFor(type: type, strike: strike);
  }

  OptionsProviderConfig get config => OptionsProviderConfig.current;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

class OptionsChainScope extends InheritedNotifier<OptionsChainState> {
  const OptionsChainScope({
    required OptionsChainState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static OptionsChainState of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OptionsChainScope>();
    assert(
      scope != null,
      'OptionsChainScope was not found in the widget tree.',
    );
    return scope!.notifier!;
  }

  static OptionsChainState? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OptionsChainScope>();
    return scope?.notifier;
  }
}
