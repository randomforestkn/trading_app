import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/data/market_state.dart';
import '../../core/models/asset.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/asset_tile.dart';
import '../asset_detail/asset_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final TextEditingController _searchController = TextEditingController();
  AssetType? _selectedType;

  List<TradingAsset> _filteredAssets(MarketState marketState) {
    final query = _searchController.text.trim().toLowerCase();
    return marketState.assets.where((asset) {
      final matchesQuery =
          query.isEmpty ||
          asset.symbol.toLowerCase().contains(query) ||
          asset.name.toLowerCase().contains(query);
      final matchesType = _selectedType == null || asset.type == _selectedType;
      return matchesQuery && matchesType;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final marketState = MarketScope.of(context);
    final filteredAssets = _filteredAssets(marketState);

    return AppPage(
      title: 'Watchlist',
      subtitle: 'Search and filter mock markets',
      actions: [
        IconButton(
          tooltip: 'Refresh prices',
          onPressed: marketState.isLoading
              ? null
              : () => _refreshPrices(context, marketState),
          icon: const Icon(Icons.refresh),
        ),
      ],
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    marketState.lastRefreshAt == null
                        ? '${AppConfig.paperTradingDisclaimer} Not refreshed yet.'
                        : '${AppConfig.paperTradingDisclaimer} Updated ${_formatTimestamp(marketState.lastRefreshAt!)}.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (marketState.errorMessage != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                marketState.errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search symbol or name',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _selectedType == null,
                  onSelected: (_) => setState(() => _selectedType = null),
                ),
              ),
              ...AssetType.values.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type.label),
                    selected: _selectedType == type,
                    onSelected: (_) => setState(() => _selectedType = type),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (filteredAssets.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No assets match this search.'),
            ),
          )
        else
          ...filteredAssets.map(
            (asset) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AssetTile(
                asset: asset,
                history: marketState.historyFor(asset.symbol),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AssetDetailScreen(asset: asset),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _refreshPrices(
    BuildContext context,
    MarketState marketState,
  ) async {
    final result = await marketState.refreshPrices();
    if (!context.mounted) {
      return;
    }
    result.when(
      success: (_) {},
      failure: (message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }
}
