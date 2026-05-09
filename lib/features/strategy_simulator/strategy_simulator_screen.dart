import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/analytics/options_analytics.dart';
import '../../core/config/app_config.dart';
import '../../core/data/market_state.dart';
import '../../core/data/paper_trading_state.dart';
import '../../core/models/asset.dart';
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
    _didInit = true;
    _seedForSelection(
      marketState.latestFor(marketState.assets.first),
      marketState,
      paperState,
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
              _seedForSelection(asset, marketState, paperState),
        ),
        const SizedBox(height: 12),
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
    _seedForSelection(_selectedAsset(marketState), marketState, paperState);
  }

  void _seedForSelection(
    TradingAsset asset,
    MarketState marketState,
    PaperTradingState paperState,
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
