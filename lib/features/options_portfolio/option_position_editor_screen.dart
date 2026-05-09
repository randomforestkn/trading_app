import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/data/market_state.dart';
import '../../core/options_portfolio/option_position.dart';
import '../../core/options_portfolio/options_portfolio_state.dart';
import '../../core/models/asset.dart';
import '../../core/strategies/option_contract.dart';
import '../../core/strategies/option_strategy.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_info_banner.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/app_stat_tile.dart';
import '../../core/widgets/section_header.dart';

class OptionPositionEditorScreen extends StatefulWidget {
  const OptionPositionEditorScreen({
    super.key,
    this.initialPosition,
    this.prefillUnderlyingSymbol,
    this.prefillUnderlyingName,
    this.prefillOptionType,
    this.prefillSide,
    this.prefillStrikePrice,
    this.prefillPremium,
    this.prefillContractsCount,
    this.prefillExpirationDate,
    this.prefillLinkedStrategy,
    this.prefillNotes,
  });

  final OptionPosition? initialPosition;
  final String? prefillUnderlyingSymbol;
  final String? prefillUnderlyingName;
  final OptionType? prefillOptionType;
  final OptionSide? prefillSide;
  final double? prefillStrikePrice;
  final double? prefillPremium;
  final int? prefillContractsCount;
  final DateTime? prefillExpirationDate;
  final OptionStrategy? prefillLinkedStrategy;
  final String? prefillNotes;

  @override
  State<OptionPositionEditorScreen> createState() =>
      _OptionPositionEditorScreenState();
}

class _OptionPositionEditorScreenState
    extends State<OptionPositionEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _strikeController = TextEditingController();
  final TextEditingController _premiumController = TextEditingController();
  final TextEditingController _contractsController = TextEditingController(
    text: '1',
  );
  final TextEditingController _expirationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedSymbol;
  OptionType _optionType = OptionType.call;
  OptionSide _side = OptionSide.sell;
  OptionStrategy? _linkedStrategy;
  DateTime? _selectedExpirationDate;
  bool _didSeed = false;

  @override
  void dispose() {
    _strikeController.dispose();
    _premiumController.dispose();
    _contractsController.dispose();
    _expirationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSeed) {
      return;
    }
    _didSeed = true;
    final marketState = MarketScope.of(context);
    final initialAsset = widget.prefillUnderlyingSymbol == null
        ? marketState.assets.first
        : marketState.assets.firstWhere(
            (asset) => asset.symbol == widget.prefillUnderlyingSymbol,
            orElse: () => marketState.assets.first,
          );
    final selected = marketState.latestFor(initialAsset);
    final position = widget.initialPosition;
    final currentPrice = selected.price;
    _selectedSymbol = selected.symbol;
    _optionType =
        widget.prefillOptionType ?? position?.optionType ?? OptionType.call;
    _side = widget.prefillSide ?? position?.side ?? OptionSide.sell;
    _linkedStrategy = widget.prefillLinkedStrategy ?? position?.linkedStrategy;
    _selectedExpirationDate =
        widget.prefillExpirationDate ??
        position?.expirationDate ??
        DateTime.now().add(const Duration(days: 30));
    _strikeController.text =
        (widget.prefillStrikePrice ?? position?.strikePrice ?? currentPrice)
            .toStringAsFixed(2);
    _premiumController.text =
        (widget.prefillPremium ?? position?.premium ?? 1.0).toStringAsFixed(2);
    _contractsController.text =
        (widget.prefillContractsCount ?? position?.contractsCount ?? 1)
            .toString();
    _expirationController.text = _formatDate(_selectedExpirationDate!);
    _notesController.text = widget.prefillNotes ?? position?.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final optionsState = OptionsPortfolioScope.of(context);
    final marketState = MarketScope.of(context);
    final selectedAsset = _selectedAsset(marketState);
    final currentPrice = selectedAsset.price;
    final projectedPremium = _parseDouble(_premiumController.text);
    final contracts = _parseInt(_contractsController.text);

    return AppPage(
      title: widget.initialPosition == null
          ? 'New option position'
          : 'Edit option position',
      subtitle: 'Track premium, lifecycle, and income',
      actions: [
        IconButton(
          tooltip: 'Save',
          onPressed: optionsState.isSaving ? null : () => _save(context),
          icon: const Icon(Icons.save_outlined),
        ),
      ],
      children: [
        const AppInfoBanner(
          title: 'Paper options ledger',
          message:
              'Record option-selling positions locally. No brokerage integration or live execution is involved.',
          icon: Icons.receipt_long_outlined,
          accentColor: AppTheme.secondary,
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
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Contracts',
                  value: contracts.toString(),
                ),
              ),
              SizedBox(
                width: 170,
                child: AppStatTile(
                  label: 'Premium',
                  value: _money(projectedPremium * contracts * 100),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _assetCard(marketState, selectedAsset),
              const SizedBox(height: 12),
              _contractCard(context, currentPrice),
              const SizedBox(height: 12),
              _detailsCard(context),
              if (optionsState.errorMessage != null) ...[
                const SizedBox(height: 12),
                AppInfoBanner(
                  title: 'Save failed',
                  message: optionsState.errorMessage!,
                  icon: Icons.warning_amber_outlined,
                  accentColor: AppTheme.danger,
                ),
              ],
              const SizedBox(height: 12),
              AppPrimaryButton(
                label: widget.initialPosition == null
                    ? 'Save position'
                    : 'Update position',
                icon: Icons.save,
                onPressed: optionsState.isSaving ? null : () => _save(context),
              ),
              const SizedBox(height: 12),
              AppSecondaryButton(
                label: 'Cancel',
                icon: Icons.close_rounded,
                onPressed: optionsState.isSaving
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _assetCard(MarketState marketState, TradingAsset selectedAsset) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Underlying asset'),
          DropdownButtonFormField<String>(
            initialValue: _selectedSymbol,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Asset',
              prefixIcon: Icon(Icons.show_chart),
            ),
            items: marketState.assets
                .map(
                  (asset) => DropdownMenuItem<String>(
                    value: asset.symbol,
                    child: Text('${asset.symbol} - ${asset.name}'),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              final asset = marketState.assetBySymbol(value);
              setState(() {
                _selectedSymbol = asset.symbol;
                _strikeController.text = asset.price.toStringAsFixed(2);
              });
            },
          ),
          const SizedBox(height: 12),
          Text(
            selectedAsset.explanation,
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _contractCard(BuildContext context, double currentPrice) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Option contract'),
          DropdownButtonFormField<OptionType>(
            initialValue: _optionType,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Option type',
              prefixIcon: Icon(Icons.swap_vert),
            ),
            items: OptionType.values
                .map(
                  (value) => DropdownMenuItem<OptionType>(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _optionType = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<OptionSide>(
            initialValue: _side,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Side',
              prefixIcon: Icon(Icons.call_split),
            ),
            items: OptionSide.values
                .map(
                  (value) => DropdownMenuItem<OptionSide>(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _side = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _strikeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Strike price',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            validator: (value) {
              final parsed = double.tryParse(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Enter a valid strike.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _premiumController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Premium per share',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            validator: (value) {
              final parsed = double.tryParse(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Enter a valid premium.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contractsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Contracts',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
            validator: (value) {
              final parsed = int.tryParse(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Contracts must be greater than zero.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _expirationController,
            readOnly: true,
            onTap: () => _pickExpirationDate(context),
            decoration: InputDecoration(
              labelText: 'Expiration date',
              prefixIcon: const Icon(Icons.event_outlined),
              suffixIcon: IconButton(
                tooltip: 'Pick date',
                onPressed: () => _pickExpirationDate(context),
                icon: const Icon(Icons.calendar_month_outlined),
              ),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Pick an expiration date.'
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            'Current price: ${_money(currentPrice)}',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Optional notes'),
          DropdownButtonFormField<OptionStrategy?>(
            initialValue: _linkedStrategy,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Linked strategy',
              prefixIcon: Icon(Icons.tune),
            ),
            items: [
              const DropdownMenuItem<OptionStrategy?>(
                value: null,
                child: Text('Standalone'),
              ),
              ...OptionStrategy.values.map(
                (value) => DropdownMenuItem<OptionStrategy?>(
                  value: value,
                  child: Text(value.label),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _linkedStrategy = value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              prefixIcon: Icon(Icons.notes_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            minLines: 3,
          ),
        ],
      ),
    );
  }

  Future<void> _pickExpirationDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate:
          _selectedExpirationDate ??
          DateTime.now().add(const Duration(days: 30)),
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _selectedExpirationDate = selected;
      _expirationController.text = _formatDate(selected);
    });
  }

  Future<void> _save(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final optionsState = OptionsPortfolioScope.of(context);
    final marketState = MarketScope.of(context);
    final selectedAsset = _selectedAsset(marketState);
    final strike = _parseDouble(_strikeController.text);
    final premium = _parseDouble(_premiumController.text);
    final contracts = _parseInt(_contractsController.text);
    final expiration = _selectedExpirationDate;
    if (expiration == null) {
      return;
    }
    final position = OptionPosition(
      id: widget.initialPosition?.id ?? '',
      underlyingSymbol: selectedAsset.symbol,
      underlyingName: selectedAsset.name,
      optionType: _optionType,
      side: _side,
      strikePrice: strike,
      premium: premium,
      contractsCount: contracts,
      multiplier: 100,
      openedAt: widget.initialPosition?.openedAt ?? DateTime.now(),
      expirationDate: expiration,
      status: widget.initialPosition?.status ?? OptionPositionStatus.open,
      linkedStrategy: _linkedStrategy,
      linkedUnderlyingPositionId:
          widget.initialPosition?.linkedUnderlyingPositionId,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (widget.initialPosition == null) {
      await optionsState.addPosition(position);
    } else {
      await optionsState.updatePosition(position);
    }
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  TradingAsset _selectedAsset(MarketState marketState) {
    if (_selectedSymbol != null) {
      return marketState.assetBySymbol(_selectedSymbol!);
    }
    return marketState.assets.first;
  }

  double _parseDouble(String value) => double.tryParse(value) ?? 0;

  int _parseInt(String value) => int.tryParse(value) ?? 0;

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';
}
