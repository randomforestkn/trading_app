import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/analytics/options_analytics.dart';
import '../../core/config/app_config.dart';
import '../../core/data/market_state.dart';
import '../../core/data/paper_trading_state.dart';
import '../../core/journal/journal_entry.dart';
import '../../core/models/asset.dart';
import '../../core/options_data/options_chain_models.dart';
import '../../core/options_data/options_chain_state.dart';
import '../../core/strategies/option_contract.dart';
import '../../core/strategies/cash_secured_put_simulator.dart';
import '../../core/strategies/covered_call_simulator.dart';
import '../../core/strategies/option_strategy.dart';
import '../../core/strategies/strategy_simulator.dart';
import '../../core/strategies/wheel_strategy_simulator.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_pill_chip.dart';
import '../../core/widgets/app_stat_tile.dart';
import '../../core/widgets/section_header.dart';
import '../journal/journal_editor_screen.dart';
import '../options_portfolio/option_position_editor_screen.dart';
import '../options_portfolio/options_portfolio_screen.dart';

class StrategySimulatorScreen extends StatefulWidget {
  const StrategySimulatorScreen({super.key});

  static const routeName = '/strategy-simulator';

  @override
  State<StrategySimulatorScreen> createState() =>
      _StrategySimulatorScreenState();
}

class _StrategySimulatorScreenState extends State<StrategySimulatorScreen> {
  final TextEditingController _sharesController = TextEditingController();
  final TextEditingController _putStrikeController = TextEditingController();
  final TextEditingController _putPremiumController = TextEditingController();
  final TextEditingController _callStrikeController = TextEditingController();
  final TextEditingController _callPremiumController = TextEditingController();
  final TextEditingController _contractsController = TextEditingController(
    text: '1',
  );
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _assignedSharePriceController =
      TextEditingController();
  OptionStrategy _strategy = OptionStrategy.coveredCall;
  String? _selectedSymbol;
  Object? _result;
  String? _errorMessage;
  bool _didInit = false;

  @override
  void dispose() {
    _sharesController.dispose();
    _putStrikeController.dispose();
    _putPremiumController.dispose();
    _callStrikeController.dispose();
    _callPremiumController.dispose();
    _contractsController.dispose();
    _expiryController.dispose();
    _assignedSharePriceController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) {
      return;
    }
    final marketState = MarketScope.of(context);
    final paperState = PaperTradingScope.of(context);
    final chainState = OptionsChainScope.maybeOf(context);
    _didInit = true;
    _seedForSelection(
      marketState.latestFor(marketState.assets.first),
      marketState,
      paperState,
      chainState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final marketState = MarketScope.of(context);
    final paperState = PaperTradingScope.of(context);
    final selectedAsset = _selectedAsset(marketState);
    final currentPrice = selectedAsset.price;
    final ownedShares = paperState.quantityFor(selectedAsset.symbol);
    final availableCash = paperState.cashBalance;
    final chainState = OptionsChainScope.maybeOf(context);
    final remoteChain = chainState?.dataMode == OptionsChainDataMode.remote
        ? chainState
        : null;

    return AppPage(
      title: 'Strategy simulator',
      subtitle: 'Options-selling workflows',
      children: [
        AppInfoBanner(
          title: 'Simulation only',
          message:
              '${AppConfig.paperTradingDisclaimer} ${AppConfig.simulatedPricesDisclaimer} Simulation only - not investment advice.',
          accentColor: AppTheme.secondary,
        ),
        const SizedBox(height: 12),
        _StrategySelector(strategy: _strategy, onSelected: _setStrategy),
        const SizedBox(height: 12),
        _AssetSelector(
          assets: marketState.assets,
          selectedAsset: selectedAsset,
          onChanged: (asset) =>
              _seedForSelection(asset, marketState, paperState, chainState),
        ),
        const SizedBox(height: 12),
        if (remoteChain == null) ...[
          const AppInfoBanner(
            title: 'Manual options input',
            message:
                'Remote options data is not configured. Manual strikes and premiums remain available.',
            icon: Icons.edit_note_outlined,
            accentColor: AppTheme.secondary,
          ),
          const SizedBox(height: 12),
        ] else ...[
          _RemoteChainCard(
            chainState: remoteChain,
            symbol: selectedAsset.symbol,
            onPrefillQuote: (quote) =>
                _applyQuoteToFields(quote, quote.expirationDate),
            money: _money,
          ),
          const SizedBox(height: 12),
        ],
        AppCard(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Underlying',
                  value: _money(currentPrice),
                ),
              ),
              if (_strategy == OptionStrategy.coveredCall)
                SizedBox(
                  width: 170,
                  child: AppStatTile(
                    label: 'Owned shares',
                    value: ownedShares.toStringAsFixed(2),
                    subtitle: 'Prefilled from portfolio',
                  ),
                ),
              if (_strategy == OptionStrategy.cashSecuredPut)
                SizedBox(
                  width: 170,
                  child: AppStatTile(
                    label: 'Cash available',
                    value: _money(availableCash),
                    subtitle: 'Prefilled from paper account',
                  ),
                ),
              if (_strategy == OptionStrategy.wheel)
                SizedBox(
                  width: 170,
                  child: AppStatTile(
                    label: 'Selected price',
                    value: _money(currentPrice),
                    subtitle: 'Prefilled from market data',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildInputs(
          context,
          selectedAsset,
          currentPrice,
          ownedShares,
          availableCash,
        ),
        const SizedBox(height: 12),
        AppPrimaryButton(
          label: 'Run simulation',
          icon: Icons.play_arrow_rounded,
          onPressed: _runSimulation,
        ),
        const SizedBox(height: 12),
        AppSecondaryButton(
          label: 'Save strategy note',
          icon: Icons.note_add_outlined,
          onPressed: () =>
              _openStrategyNote(context, selectedAsset, currentPrice),
        ),
        const SizedBox(height: 10),
        AppSecondaryButton(
          label: 'Track option position',
          icon: Icons.receipt_long_outlined,
          onPressed: () =>
              _openOptionPositionEditor(context, selectedAsset, currentPrice),
        ),
        const SizedBox(height: 10),
        AppSecondaryButton(
          label: 'Open options portfolio',
          icon: Icons.arrow_forward_rounded,
          onPressed: () =>
              Navigator.of(context).pushNamed(OptionsPortfolioScreen.routeName),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          AppInfoBanner(
            title: 'Validation',
            message: _errorMessage!,
            icon: Icons.warning_amber_outlined,
            accentColor: AppTheme.warning,
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 16),
          const SectionHeader('Results'),
          _ResultCard(result: _result!),
        ],
      ],
    );
  }

  void _setStrategy(OptionStrategy strategy) {
    setState(() => _strategy = strategy);
    final marketState = MarketScope.of(context);
    final paperState = PaperTradingScope.of(context);
    _seedForSelection(
      _selectedAsset(marketState),
      marketState,
      paperState,
      OptionsChainScope.maybeOf(context),
    );
  }

  void _seedForSelection(
    TradingAsset asset,
    MarketState marketState,
    PaperTradingState paperState,
    OptionsChainState? chainState,
  ) {
    final selected = marketState.latestFor(asset);
    final currentPrice = selected.price;
    setState(() {
      _selectedSymbol = selected.symbol;
      _result = null;
      _errorMessage = null;
      _contractsController.text = '1';
      _expiryController.text = DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String()
          .split('T')
          .first;
      _assignedSharePriceController.text = currentPrice.toStringAsFixed(2);

      if (_strategy == OptionStrategy.coveredCall) {
        final ownedShares = paperState.quantityFor(selected.symbol);
        _sharesController.text = ownedShares.toStringAsFixed(2);
        _putStrikeController.text = (currentPrice * 1.05).toStringAsFixed(2);
        _putPremiumController.text = (currentPrice * 0.02).toStringAsFixed(2);
        _callStrikeController.text = (currentPrice * 1.05).toStringAsFixed(2);
        _callPremiumController.text = (currentPrice * 0.02).toStringAsFixed(2);
      } else if (_strategy == OptionStrategy.cashSecuredPut) {
        _sharesController.clear();
        _putStrikeController.text = (currentPrice * 0.95).toStringAsFixed(2);
        _putPremiumController.text = (currentPrice * 0.02).toStringAsFixed(2);
        _callStrikeController.text = (currentPrice * 1.05).toStringAsFixed(2);
        _callPremiumController.text = (currentPrice * 0.02).toStringAsFixed(2);
      } else {
        _sharesController.clear();
        _putStrikeController.text = (currentPrice * 0.95).toStringAsFixed(2);
        _putPremiumController.text = (currentPrice * 0.02).toStringAsFixed(2);
        _callStrikeController.text = (currentPrice * 1.05).toStringAsFixed(2);
        _callPremiumController.text = (currentPrice * 0.02).toStringAsFixed(2);
      }
    });
    if (chainState != null) {
      unawaited(chainState.setUnderlying(selected.symbol));
    }
  }

  void _applyQuoteToFields(OptionQuote quote, DateTime expirationDate) {
    setState(() {
      _selectedSymbol = quote.underlyingSymbol;
      _callStrikeController.text = quote.strike.toStringAsFixed(2);
      _callPremiumController.text = quote.mid.toStringAsFixed(2);
      _putStrikeController.text = quote.strike.toStringAsFixed(2);
      _putPremiumController.text = quote.mid.toStringAsFixed(2);
      _expiryController.text = expirationDate
          .toIso8601String()
          .split('T')
          .first;
      _result = null;
      _errorMessage = null;
    });
  }

  TradingAsset _selectedAsset(MarketState marketState) {
    final symbol = _selectedSymbol;
    if (symbol != null) {
      final existing = marketState.assets.where(
        (asset) => asset.symbol == symbol,
      );
      if (existing.isNotEmpty) {
        return existing.first;
      }
    }
    return marketState.assets.first;
  }

  Widget _buildInputs(
    BuildContext context,
    TradingAsset asset,
    double currentPrice,
    double ownedShares,
    double availableCash,
  ) {
    final fields = switch (_strategy) {
      OptionStrategy.coveredCall => [
        _NumberField(
          controller: _sharesController,
          label: 'Owned shares',
          prefixIcon: Icons.inventory_2_outlined,
        ),
        _NumberField(
          controller: _putStrikeController,
          label: 'Call strike',
          prefixIcon: Icons.flag_outlined,
        ),
        _NumberField(
          controller: _putPremiumController,
          label: 'Premium per share',
          prefixIcon: Icons.local_atm_outlined,
        ),
        _NumberField(
          controller: _contractsController,
          label: 'Contracts',
          prefixIcon: Icons.confirmation_num_outlined,
        ),
        _NumberField(
          controller: _expiryController,
          label: 'Expiration (YYYY-MM-DD)',
          prefixIcon: Icons.event_outlined,
        ),
      ],
      OptionStrategy.cashSecuredPut => [
        _NumberField(
          controller: _putStrikeController,
          label: 'Put strike',
          prefixIcon: Icons.flag_outlined,
        ),
        _NumberField(
          controller: _putPremiumController,
          label: 'Premium per share',
          prefixIcon: Icons.local_atm_outlined,
        ),
        _NumberField(
          controller: _contractsController,
          label: 'Contracts',
          prefixIcon: Icons.confirmation_num_outlined,
        ),
        _NumberField(
          controller: _expiryController,
          label: 'Expiration (YYYY-MM-DD)',
          prefixIcon: Icons.event_outlined,
        ),
      ],
      OptionStrategy.wheel => [
        _NumberField(
          controller: _putStrikeController,
          label: 'Put strike',
          prefixIcon: Icons.flag_outlined,
        ),
        _NumberField(
          controller: _putPremiumController,
          label: 'Put premium',
          prefixIcon: Icons.local_atm_outlined,
        ),
        _NumberField(
          controller: _callStrikeController,
          label: 'Call strike',
          prefixIcon: Icons.flag_circle_outlined,
        ),
        _NumberField(
          controller: _callPremiumController,
          label: 'Call premium',
          prefixIcon: Icons.local_atm_outlined,
        ),
        _NumberField(
          controller: _contractsController,
          label: 'Contracts',
          prefixIcon: Icons.confirmation_num_outlined,
        ),
        _NumberField(
          controller: _expiryController,
          label: 'Expiration (YYYY-MM-DD)',
          prefixIcon: Icons.event_outlined,
        ),
        _NumberField(
          controller: _assignedSharePriceController,
          label: 'Assigned share price',
          prefixIcon: Icons.price_change_outlined,
          helperText: 'Optional',
        ),
      ],
    };

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_strategy.label} inputs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: fields
                .map((field) => SizedBox(width: field.maxWidth, child: field))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _runSimulation() {
    final marketState = MarketScope.of(context);
    final paperState = PaperTradingScope.of(context);
    final asset = _selectedAsset(marketState);
    final currentPrice = marketState.latestFor(asset).price;
    final contracts = _parseInt(_contractsController.text);
    final expiration = DateTime.tryParse(_expiryController.text.trim());

    if (contracts == null || contracts <= 0) {
      setState(
        () => _errorMessage = 'Contracts must be a positive whole number.',
      );
      return;
    }
    if (expiration == null) {
      setState(
        () => _errorMessage =
            'Enter a valid expiration date in YYYY-MM-DD format.',
      );
      return;
    }

    switch (_strategy) {
      case OptionStrategy.coveredCall:
        final shares = _parseDouble(_sharesController.text);
        final strike = _parseDouble(_putStrikeController.text);
        final premium = _parseDouble(_putPremiumController.text);
        if (shares == null || shares <= 0) {
          setState(
            () => _errorMessage = 'Owned shares must be greater than zero.',
          );
          return;
        }
        if (strike == null || strike <= 0 || premium == null || premium <= 0) {
          setState(
            () => _errorMessage = 'Enter valid strike and premium values.',
          );
          return;
        }
        final result = CoveredCallSimulator(
          underlyingSymbol: asset.symbol,
          ownedShares: shares.floor(),
          currentUnderlyingPrice: currentPrice,
          strikePrice: strike,
          premium: premium,
          contractsCount: contracts,
          expirationDate: expiration,
        ).simulate();
        setState(() {
          _result = result;
          _errorMessage = result.validationWarning;
        });
        return;
      case OptionStrategy.cashSecuredPut:
        final strike = _parseDouble(_putStrikeController.text);
        final premium = _parseDouble(_putPremiumController.text);
        if (strike == null || strike <= 0 || premium == null || premium <= 0) {
          setState(
            () => _errorMessage = 'Enter valid strike and premium values.',
          );
          return;
        }
        final result = CashSecuredPutSimulator(
          underlyingSymbol: asset.symbol,
          cashAvailable: paperState.cashBalance,
          currentUnderlyingPrice: currentPrice,
          strikePrice: strike,
          premium: premium,
          contractsCount: contracts,
          expirationDate: expiration,
        ).simulate();
        setState(() {
          _result = result;
          _errorMessage = result.validationWarning;
        });
        return;
      case OptionStrategy.wheel:
        final putStrike = _parseDouble(_putStrikeController.text);
        final putPremium = _parseDouble(_putPremiumController.text);
        final callStrike = _parseDouble(_callStrikeController.text);
        final callPremium = _parseDouble(_callPremiumController.text);
        final assignedSharePrice = _parseDouble(
          _assignedSharePriceController.text,
        );
        if (putStrike == null ||
            putStrike <= 0 ||
            putPremium == null ||
            putPremium <= 0 ||
            callStrike == null ||
            callStrike <= 0 ||
            callPremium == null ||
            callPremium <= 0) {
          setState(() => _errorMessage = 'Enter valid wheel strategy values.');
          return;
        }
        final result = WheelStrategySimulator(
          underlyingSymbol: asset.symbol,
          currentUnderlyingPrice: currentPrice,
          putStrikePrice: putStrike,
          putPremium: putPremium,
          callStrikePrice: callStrike,
          callPremium: callPremium,
          contractsCount: contracts,
          expirationDate: expiration,
          assignedSharePrice: assignedSharePrice,
        ).simulate();
        setState(() {
          _result = result;
          _errorMessage = result.validationWarning;
        });
    }
  }

  void _openStrategyNote(
    BuildContext context,
    TradingAsset asset,
    double currentPrice,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalEditorScreen(
          prefillTitle: '${_strategy.label} note - ${asset.symbol}',
          prefillBody: _strategyBody(asset, currentPrice),
          prefillLinkedAssetSymbol: asset.symbol,
          prefillLinkedStrategy: _journalStrategy(),
          prefillMood: JournalMood.disciplined,
          prefillOutcome: JournalOutcome.open,
          prefillTags: const ['strategy', 'options'],
        ),
      ),
    );
  }

  void _openOptionPositionEditor(
    BuildContext context,
    TradingAsset asset,
    double currentPrice,
  ) {
    final strategy = _strategy == OptionStrategy.wheel
        ? OptionStrategy.cashSecuredPut
        : _strategy;
    final optionType = switch (strategy) {
      OptionStrategy.coveredCall => OptionType.call,
      OptionStrategy.cashSecuredPut => OptionType.put,
      OptionStrategy.wheel => OptionType.put,
    };
    final strike = switch (_strategy) {
      OptionStrategy.coveredCall => _parseDouble(_callStrikeController.text),
      OptionStrategy.cashSecuredPut => _parseDouble(_putStrikeController.text),
      OptionStrategy.wheel => _parseDouble(_putStrikeController.text),
    };
    final premium = switch (_strategy) {
      OptionStrategy.coveredCall => _parseDouble(_callPremiumController.text),
      OptionStrategy.cashSecuredPut => _parseDouble(_putPremiumController.text),
      OptionStrategy.wheel => _parseDouble(_putPremiumController.text),
    };
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OptionPositionEditorScreen(
          prefillUnderlyingSymbol: asset.symbol,
          prefillUnderlyingName: asset.name,
          prefillOptionType: optionType,
          prefillSide: OptionSide.sell,
          prefillStrikePrice: strike,
          prefillPremium: premium,
          prefillContractsCount: _parseInt(_contractsController.text),
          prefillExpirationDate:
              DateTime.tryParse(_expiryController.text) ??
              DateTime.now().add(const Duration(days: 30)),
          prefillLinkedStrategy: strategy,
          prefillNotes:
              'Strategy simulation from ${asset.symbol} at ${currentPrice.toStringAsFixed(2)}',
        ),
      ),
    );
  }

  String _strategyBody(TradingAsset asset, double currentPrice) {
    final buffer = StringBuffer();
    buffer.writeln('Strategy: ${_strategy.label}');
    buffer.writeln(
      'Underlying: ${asset.symbol} at \$${currentPrice.toStringAsFixed(2)}',
    );
    if (_result != null) {
      buffer.writeln('Simulation completed successfully.');
    } else {
      buffer.writeln(
        'Record your assumptions, risk controls, and follow-up plan.',
      );
    }
    return buffer.toString().trim();
  }

  JournalStrategyType _journalStrategy() {
    return switch (_strategy) {
      OptionStrategy.coveredCall => JournalStrategyType.coveredCall,
      OptionStrategy.cashSecuredPut => JournalStrategyType.cashSecuredPut,
      OptionStrategy.wheel => JournalStrategyType.wheel,
    };
  }
}

class _StrategySelector extends StatelessWidget {
  const _StrategySelector({required this.strategy, required this.onSelected});

  final OptionStrategy strategy;
  final ValueChanged<OptionStrategy> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: OptionStrategy.values
            .map(
              (item) => AppPillChip(
                label: item.label,
                selected: item == strategy,
                onSelected: (selected) {
                  if (selected) {
                    onSelected(item);
                  }
                },
                selectedColor: item == strategy ? AppTheme.primary : null,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AssetSelector extends StatelessWidget {
  const _AssetSelector({
    required this.assets,
    required this.selectedAsset,
    required this.onChanged,
  });

  final List<TradingAsset> assets;
  final TradingAsset selectedAsset;
  final ValueChanged<TradingAsset> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<TradingAsset>(
        initialValue: selectedAsset,
        decoration: const InputDecoration(
          labelText: 'Underlying asset',
          prefixIcon: Icon(Icons.swap_horiz_outlined),
        ),
        items: assets
            .map(
              (asset) => DropdownMenuItem(
                value: asset,
                child: Text('${asset.symbol} • ${asset.name}'),
              ),
            )
            .toList(),
        onChanged: (asset) {
          if (asset != null) {
            onChanged(asset);
          }
        },
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final String? helperText;

  double get maxWidth => 220;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        helperText: helperText,
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final Object result;

  @override
  Widget build(BuildContext context) {
    return switch (result) {
      CoveredCallSimulationResult data => _CoveredCallResultCard(result: data),
      CashSecuredPutSimulationResult data => _CashSecuredPutResultCard(
        result: data,
      ),
      WheelStrategySimulationResult data => _WheelResultCard(result: data),
      _ => const SizedBox.shrink(),
    };
  }
}

class _CoveredCallResultCard extends StatelessWidget {
  const _CoveredCallResultCard({required this.result});

  final CoveredCallSimulationResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _resultTile('Premium income', _money(result.premiumIncome)),
              _resultTile('Max profit', _money(result.maxProfit)),
              _resultTile('Breakeven', _money(result.breakeven)),
              _resultTile(
                'Called-away return',
                _money(result.calledAwayReturn),
              ),
              _resultTile(
                'Downside buffer',
                _percent(result.downsideBufferPercent),
              ),
              _resultTile('Shares covered', result.requiredShares.toString()),
              _resultTile(
                'Annualized yield',
                _percent(result.annualizedPremiumYieldPercent),
              ),
              _resultTile('Assignment risk', result.assignmentRiskLabel.label),
            ],
          ),
          if (result.validationWarning != null) ...[
            const SizedBox(height: 12),
            AppInfoBanner(
              title: 'Coverage warning',
              message: result.validationWarning!,
              icon: Icons.warning_amber_outlined,
              accentColor: AppTheme.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _CashSecuredPutResultCard extends StatelessWidget {
  const _CashSecuredPutResultCard({required this.result});

  final CashSecuredPutSimulationResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _resultTile('Premium income', _money(result.premiumIncome)),
              _resultTile('Capital required', _money(result.capitalRequired)),
              _resultTile('Breakeven', _money(result.breakeven)),
              _resultTile('Max profit', _money(result.maxProfit)),
              _resultTile('Max loss estimate', _money(result.maxLossEstimate)),
              _resultTile(
                'Return on cash',
                _percent(result.returnOnCashSecuredPercent),
              ),
              _resultTile('Assignment cost', _money(result.assignmentCost)),
              _resultTile(
                'Annualized yield',
                _percent(result.annualizedPremiumYieldPercent),
              ),
              _resultTile('Assignment risk', result.assignmentRiskLabel.label),
            ],
          ),
          if (result.validationWarning != null) ...[
            const SizedBox(height: 12),
            AppInfoBanner(
              title: 'Capital warning',
              message: result.validationWarning!,
              icon: Icons.warning_amber_outlined,
              accentColor: AppTheme.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _WheelResultCard extends StatelessWidget {
  const _WheelResultCard({required this.result});

  final WheelStrategySimulationResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _resultTile(
                'Premium cycle income',
                _money(result.totalPremiumCycleIncome),
              ),
              _resultTile(
                'Capital required',
                _money(result.estimatedCapitalRequired),
              ),
              _resultTile('Put breakeven', _money(result.putBreakeven)),
              _resultTile(
                'Covered call breakeven',
                _money(result.coveredCallBreakeven),
              ),
              _resultTile(
                'Assigned cost basis',
                _money(result.assignedCostBasisAfterPutPremium),
              ),
              _resultTile(
                'Exit profit estimate',
                _money(result.exitCalledAwayProfitEstimate),
              ),
              _resultTile(
                'Return on capital',
                _percent(result.returnOnCapitalPercent),
              ),
              _resultTile(
                'Days to expiration',
                result.daysToExpiration.toString(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...result.scenarios.map(
            (scenario) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppInfoBanner(
                title: scenario.title,
                message: scenario.description,
                icon: Icons.info_outline,
                accentColor: scenario.severity == StrategySeverity.danger
                    ? AppTheme.danger
                    : scenario.severity == StrategySeverity.warning
                    ? AppTheme.warning
                    : AppTheme.secondary,
              ),
            ),
          ),
          if (result.validationWarning != null) ...[
            const SizedBox(height: 6),
            AppInfoBanner(
              title: 'Validation',
              message: result.validationWarning!,
              icon: Icons.warning_amber_outlined,
              accentColor: AppTheme.warning,
            ),
          ],
        ],
      ),
    );
  }
}

Widget _resultTile(String label, String value) {
  return SizedBox(
    width: 180,
    child: AppStatTile(label: label, value: value),
  );
}

String _money(double value) {
  return '\$${value.toStringAsFixed(value.abs() >= 1000 ? 0 : 2)}';
}

String _percent(double value) => '${value.toStringAsFixed(1)}%';

double? _parseDouble(String value) {
  final parsed = double.tryParse(value.trim());
  return parsed;
}

int? _parseInt(String value) {
  final parsed = int.tryParse(value.trim());
  return parsed;
}

class _RemoteChainCard extends StatelessWidget {
  const _RemoteChainCard({
    required this.chainState,
    required this.symbol,
    required this.onPrefillQuote,
    required this.money,
  });

  final OptionsChainState chainState;
  final String symbol;
  final ValueChanged<OptionQuote> onPrefillQuote;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final chain = chainState.chain;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Options chain'),
          Text(
            '${chainState.config.dataModeLabel} · ${chainState.config.providerLabel}',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 12),
          if (chainState.errorMessage != null) ...[
            AppInfoBanner(
              title: 'Chain unavailable',
              message: chainState.errorMessage!,
              icon: Icons.warning_amber_outlined,
              accentColor: AppTheme.warning,
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<DateTime>(
            initialValue: chainState.selectedExpiration,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Expiration',
              prefixIcon: Icon(Icons.event_outlined),
            ),
            items: chainState.expirations
                .map(
                  (expiration) => DropdownMenuItem<DateTime>(
                    value: expiration,
                    child: Text(expiration.toIso8601String().split('T').first),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => chainState.setExpiration(value),
          ),
          if (chain != null && chain.quotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chain.quotes
                  .take(8)
                  .map((quote) {
                    final label =
                        '${quote.optionType.label} ${quote.strike.toStringAsFixed(0)} · ${quote.mid.toStringAsFixed(2)}';
                    return ActionChip(
                      label: Text(label),
                      onPressed: () => onPrefillQuote(quote),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _quoteTile('Bid', money(chain.quotes.first.bid)),
                _quoteTile('Ask', money(chain.quotes.first.ask)),
                _quoteTile('Mid', money(chain.quotes.first.mid)),
                _quoteTile(
                  'Open interest',
                  chain.quotes.first.openInterest.toString(),
                ),
                _quoteTile('Volume', chain.quotes.first.volume.toString()),
                if (chain.quotes.first.impliedVolatility != null)
                  _quoteTile(
                    'IV',
                    '${chain.quotes.first.impliedVolatility!.toStringAsFixed(1)}%',
                  ),
              ],
            ),
          ] else ...[
            const Text(
              'No chain quotes loaded yet.',
              style: TextStyle(color: Colors.white60),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Symbol: $symbol',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

Widget _quoteTile(String label, String value) {
  return SizedBox(
    width: 160,
    child: AppStatTile(label: label, value: value),
  );
}
