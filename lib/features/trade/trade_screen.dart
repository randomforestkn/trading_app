import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/asset.dart';

enum OrderSide { buy, sell }

enum OrderType { market, limit }

class TradeScreen extends StatefulWidget {
  const TradeScreen({
    required this.asset,
    required this.initialSide,
    super.key,
  });

  final TradingAsset asset;
  final OrderSide initialSide;

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  late OrderSide _side = widget.initialSide;
  OrderType _orderType = OrderType.market;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _limitController = TextEditingController();

  double get _quantity => double.tryParse(_quantityController.text) ?? 0;

  double get _orderPrice {
    if (_orderType == OrderType.limit) {
      return double.tryParse(_limitController.text) ?? widget.asset.price;
    }
    return widget.asset.price;
  }

  double get _estimatedValue => _quantity * _orderPrice;

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
    final isBuy = _side == OrderSide.buy;

    return Scaffold(
      appBar: AppBar(
        title: Text('${isBuy ? 'Buy' : 'Sell'} ${widget.asset.symbol}'),
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
                        const SizedBox(height: 16),
                        SegmentedButton<OrderSide>(
                          segments: const [
                            ButtonSegment(
                              value: OrderSide.buy,
                              label: Text('Buy'),
                            ),
                            ButtonSegment(
                              value: OrderSide.sell,
                              label: Text('Sell'),
                            ),
                          ],
                          selected: {_side},
                          onSelectionChanged: (value) {
                            setState(() => _side = value.first);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            prefixIcon: Icon(Icons.pin_outlined),
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
                            controller: _limitController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Limit price',
                              prefixIcon: Icon(Icons.price_change_outlined),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        _ConfirmationSummaryCard(
                          asset: widget.asset,
                          side: _side,
                          orderType: _orderType,
                          quantity: _quantity,
                          orderPrice: _orderPrice,
                          estimatedValue: _estimatedValue,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isBuy
                                ? AppTheme.primary
                                : AppTheme.danger,
                            foregroundColor: isBuy
                                ? Colors.black
                                : Colors.white,
                          ),
                          onPressed: _quantity > 0 ? _confirm : null,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text('Confirm ${isBuy ? 'buy' : 'sell'}'),
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

  void _confirm() {
    final sideLabel = _side == OrderSide.buy ? 'Buy' : 'Sell';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$sideLabel order simulated for $_quantity ${widget.asset.symbol}',
        ),
      ),
    );
    Navigator.of(context).pop();
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
  final OrderSide side;
  final OrderType orderType;
  final double quantity;
  final double orderPrice;
  final double estimatedValue;

  @override
  Widget build(BuildContext context) {
    final sideLabel = side == OrderSide.buy ? 'Buy' : 'Sell';
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
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: emphasized ? 18 : null,
            ),
          ),
        ],
      ),
    );
  }
}
