import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/data/market_state.dart';
import '../../core/data/paper_trading_state.dart';
import '../../core/models/asset.dart';
import '../../core/models/paper_order.dart';

enum OrderType { market, limit }

class TradeScreen extends StatefulWidget {
  const TradeScreen({
    required this.asset,
    required this.initialSide,
    super.key,
  });

  final TradingAsset asset;
  final PaperOrderSide initialSide;

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  late PaperOrderSide _side = widget.initialSide;
  OrderType _orderType = OrderType.market;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _limitController = TextEditingController();

  double get _quantity => double.tryParse(_quantityController.text) ?? 0;

  double? get _quantityInput => double.tryParse(_quantityController.text);

  double _orderPriceFor(TradingAsset currentAsset) {
    if (_orderType == OrderType.limit) {
      return double.tryParse(_limitController.text) ?? currentAsset.price;
    }
    return currentAsset.price;
  }

  double _estimatedValueFor(TradingAsset currentAsset) =>
      _quantity * _orderPriceFor(currentAsset);

  String? _quantityError(
    PaperTradingState tradingState,
    TradingAsset currentAsset,
  ) {
    if (_quantityController.text.trim().isEmpty) {
      return 'Enter a quantity.';
    }
    final quantity = _quantityInput;
    if (quantity == null) {
      return 'Quantity must be a number.';
    }
    if (quantity <= 0) {
      return 'Quantity must be greater than zero.';
    }
    if (_side == PaperOrderSide.sell &&
        quantity > tradingState.quantityFor(widget.asset.symbol)) {
      return 'You do not own enough ${widget.asset.symbol}.';
    }
    if (_side == PaperOrderSide.buy &&
        quantity * _orderPriceFor(currentAsset) > tradingState.cashBalance) {
      return 'Insufficient cash for this order.';
    }
    return null;
  }

  String? get _priceError {
    if (_orderType == OrderType.market) {
      return null;
    }
    if (_limitController.text.trim().isEmpty) {
      return 'Enter a limit price.';
    }
    final price = double.tryParse(_limitController.text);
    if (price == null) {
      return 'Limit price must be a number.';
    }
    if (price <= 0) {
      return 'Limit price must be greater than zero.';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _limitController.text = widget.asset.price.toStringAsFixed(2);
    _quantityController.addListener(_refresh);
    _limitController.addListener(_refresh);
  }

  @override
  void dispose() {
    _quantityController
      ..removeListener(_refresh)
      ..dispose();
    _limitController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tradingState = PaperTradingScope.of(context);
    final currentAsset = MarketScope.of(context).latestFor(widget.asset);
    final isBuy = _side == PaperOrderSide.buy;
    final quantityError = _quantityError(tradingState, currentAsset);
    final priceError = _priceError;
    final canSubmit = quantityError == null && priceError == null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${isBuy ? 'Buy' : 'Sell'} ${currentAsset.symbol}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Order ticket',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        const _PaperTradingNotice(),
                        const SizedBox(height: 16),
                        SegmentedButton<PaperOrderSide>(
                          segments: const [
                            ButtonSegment(
                              value: PaperOrderSide.buy,
                              label: Text('Buy'),
                            ),
                            ButtonSegment(
                              value: PaperOrderSide.sell,
                              label: Text('Sell'),
                            ),
                          ],
                          selected: {_side},
                          onSelectionChanged: (value) {
                            setState(() => _side = value.first);
                          },
                        ),
                        const SizedBox(height: 16),
                        _AccountAvailabilityCard(
                          side: _side,
                          cashBalance: tradingState.cashBalance,
                          ownedQuantity: tradingState.quantityFor(
                            widget.asset.symbol,
                          ),
                          assetSymbol: widget.asset.symbol,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('trade_quantity_field'),
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            prefixIcon: const Icon(Icons.pin_outlined),
                            errorText: quantityError,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<OrderType>(
                          segments: const [
                            ButtonSegment(
                              value: OrderType.market,
                              label: Text('Market'),
                            ),
                            ButtonSegment(
                              value: OrderType.limit,
                              label: Text('Limit'),
                            ),
                          ],
                          selected: {_orderType},
                          onSelectionChanged: (value) {
                            setState(() => _orderType = value.first);
                          },
                        ),
                        if (_orderType == OrderType.limit) ...[
                          const SizedBox(height: 16),
                          TextField(
                            key: const Key('trade_limit_price_field'),
                            controller: _limitController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Limit price',
                              prefixIcon: const Icon(
                                Icons.price_change_outlined,
                              ),
                              errorText: priceError,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _ConfirmationSummaryCard(
                          asset: currentAsset,
                          side: _side,
                          orderType: _orderType,
                          quantity: _quantity,
                          orderPrice: _orderPriceFor(currentAsset),
                          estimatedValue: _estimatedValueFor(currentAsset),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          key: const Key('trade_submit_button'),
                          style: FilledButton.styleFrom(
                            backgroundColor: isBuy
                                ? AppTheme.primary
                                : AppTheme.danger,
                            foregroundColor: isBuy
                                ? Colors.black
                                : Colors.white,
                          ),
                          onPressed: canSubmit ? _showOrderPreview : null,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text('Preview ${isBuy ? 'buy' : 'sell'}'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOrderPreview() async {
    final tradingState = PaperTradingScope.of(context);
    final currentAsset = MarketScope.of(context).latestFor(widget.asset);
    final orderPrice = _orderPriceFor(currentAsset);
    final estimatedValue = _estimatedValueFor(currentAsset);
    final remainingCash =
        tradingState.cashBalance -
        (_side == PaperOrderSide.buy ? estimatedValue : -estimatedValue);
    final remainingShares =
        tradingState.quantityFor(widget.asset.symbol) -
        (_side == PaperOrderSide.sell ? _quantity : -_quantity);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.86,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Review paper order',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const _PaperTradingNotice(compact: true),
                  const SizedBox(height: 12),
                  _SummaryRow(label: 'Asset', value: currentAsset.symbol),
                  _SummaryRow(label: 'Side', value: _side.label),
                  _SummaryRow(
                    label: 'Quantity',
                    value: _quantity.toStringAsFixed(4),
                  ),
                  _SummaryRow(
                    label: 'Price',
                    value: '\$${orderPrice.toStringAsFixed(2)}',
                  ),
                  _SummaryRow(
                    label: 'Estimated total',
                    value: '\$${estimatedValue.toStringAsFixed(2)}',
                    emphasized: true,
                  ),
                  _SummaryRow(
                    label: _side == PaperOrderSide.buy
                        ? 'Cash after order'
                        : 'Shares after order',
                    value: _side == PaperOrderSide.buy
                        ? '\$${remainingCash.toStringAsFixed(2)}'
                        : remainingShares.toStringAsFixed(4),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('trade_confirm_execution_button'),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.verified_outlined),
                    label: Text('Place ${_side.label.toLowerCase()} order'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      await _executeConfirmedOrder();
    }
  }

  Future<void> _executeConfirmedOrder() async {
    final tradingState = PaperTradingScope.of(context);
    final currentAsset = MarketScope.of(context).latestFor(widget.asset);
    final result = await tradingState.executeOrder(
      asset: currentAsset,
      side: _side,
      quantity: _quantity,
      executionPrice: _orderPriceFor(currentAsset),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success ? AppTheme.primary : AppTheme.danger,
        content: Text(
          result.message,
          style: TextStyle(color: result.success ? Colors.black : Colors.white),
        ),
      ),
    );

    if (result.success) {
      Navigator.of(context).pop();
    }
  }
}

class _PaperTradingNotice extends StatelessWidget {
  const _PaperTradingNotice({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha: 0.10),
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppTheme.secondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${AppConfig.paperTradingDisclaimer} ${AppConfig.simulatedPricesDisclaimer}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountAvailabilityCard extends StatelessWidget {
  const _AccountAvailabilityCard({
    required this.side,
    required this.cashBalance,
    required this.ownedQuantity,
    required this.assetSymbol,
  });

  final PaperOrderSide side;
  final double cashBalance;
  final double ownedQuantity;
  final String assetSymbol;

  @override
  Widget build(BuildContext context) {
    final isBuy = side == PaperOrderSide.buy;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isBuy
                  ? Icons.account_balance_wallet_outlined
                  : Icons.inventory_2_outlined,
              color: isBuy ? AppTheme.primary : AppTheme.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isBuy
                    ? 'Available cash: \$${cashBalance.toStringAsFixed(2)}'
                    : 'Owned $assetSymbol: ${ownedQuantity.toStringAsFixed(4)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationSummaryCard extends StatelessWidget {
  const _ConfirmationSummaryCard({
    required this.asset,
    required this.side,
    required this.orderType,
    required this.quantity,
    required this.orderPrice,
    required this.estimatedValue,
  });

  final TradingAsset asset;
  final PaperOrderSide side;
  final OrderType orderType;
  final double quantity;
  final double orderPrice;
  final double estimatedValue;

  @override
  Widget build(BuildContext context) {
    final sideLabel = side.label;
    final typeLabel = orderType == OrderType.market ? 'Market' : 'Limit';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Confirmation summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Chip(label: Text(sideLabel)),
              ],
            ),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Instrument', value: asset.symbol),
            _SummaryRow(label: 'Order type', value: typeLabel),
            _SummaryRow(label: 'Quantity', value: quantity.toStringAsFixed(4)),
            _SummaryRow(
              label: orderType == OrderType.market
                  ? 'Estimated fill'
                  : 'Limit price',
              value: '\$${orderPrice.toStringAsFixed(2)}',
            ),
            const Divider(height: 22),
            _SummaryRow(
              label: 'Estimated total',
              value: '\$${estimatedValue.toStringAsFixed(2)}',
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: emphasized ? 18 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
