import '../models/activity_item.dart';
import '../models/asset.dart';
import '../models/learn_topic.dart';
import '../models/market_index.dart';
import '../models/portfolio_position.dart';

class MockMarketData {
  const MockMarketData._();

  static const assets = [
    TradingAsset(
      symbol: 'AAPL',
      name: 'Apple Inc.',
      type: AssetType.stock,
      price: 214.32,
      dailyChangePercent: 1.24,
      open: 211.42,
      high: 215.18,
      low: 209.76,
      volume: '58.4M',
      marketCap: '\$3.2T',
      trend: [207.4, 209.8, 208.9, 211.5, 212.8, 211.9, 214.32],
      explanation:
          'Apple is a large technology company. Buying shares means owning a small part of the business.',
      stats: {
        'Market cap': '\$3.2T',
        'P/E ratio': '32.4',
        'Dividend yield': '0.45%',
        '52W range': '\$164 - \$237',
      },
    ),
    TradingAsset(
      symbol: 'VOO',
      name: 'Vanguard S&P 500 ETF',
      type: AssetType.etf,
      price: 508.70,
      dailyChangePercent: 0.52,
      open: 505.90,
      high: 510.22,
      low: 505.14,
      volume: '6.1M',
      marketCap: '\$1.5T',
      trend: [501.4, 503.1, 504.9, 504.2, 506.8, 507.4, 508.7],
      explanation:
          'VOO tracks the S&P 500, giving exposure to hundreds of large US companies through one fund.',
      stats: {
        'Expense ratio': '0.03%',
        'Holdings': '500+',
        'Dividend yield': '1.28%',
        'Issuer': 'Vanguard',
      },
    ),
    TradingAsset(
      symbol: 'US500',
      name: 'S&P 500 Index CFD',
      type: AssetType.cfd,
      price: 5324.18,
      dailyChangePercent: -0.18,
      open: 5331.40,
      high: 5350.10,
      low: 5309.60,
      volume: 'Index',
      marketCap: 'N/A',
      trend: [5354, 5348, 5339, 5344, 5327, 5331, 5324.18],
      explanation:
          'A CFD lets you speculate on price changes without owning the underlying asset. Risk can be amplified.',
      stats: {
        'Contract type': 'Index CFD',
        'Margin': '5%',
        'Spread': '0.8 pts',
        'Market': 'US indices',
      },
    ),
    TradingAsset(
      symbol: 'AAPL C230',
      name: 'Apple Call Option',
      type: AssetType.option,
      price: 6.85,
      dailyChangePercent: 4.12,
      open: 6.45,
      high: 7.10,
      low: 6.22,
      volume: '42.8K',
      marketCap: 'N/A',
      trend: [5.88, 6.12, 6.05, 6.34, 6.58, 6.72, 6.85],
      explanation:
          'A call option gives the right, not the obligation, to buy an asset at a strike price before expiry.',
      stats: {
        'Strike': '\$230',
        'Expiry': '45 days',
        'Delta': '0.42',
        'Implied vol': '28%',
      },
    ),
    TradingAsset(
      symbol: 'BTC',
      name: 'Bitcoin',
      type: AssetType.crypto,
      price: 68240.00,
      dailyChangePercent: -1.76,
      open: 69420.00,
      high: 70110.00,
      low: 67480.00,
      volume: '\$42B',
      marketCap: '\$1.34T',
      trend: [70400, 69880, 70110, 69120, 68540, 68910, 68240],
      explanation:
          'Bitcoin is a digital asset traded around the clock. Prices can move sharply in both directions.',
      stats: {
        'Market cap': '\$1.34T',
        '24H volume': '\$42B',
        'Network': 'Bitcoin',
        'Trading': '24/7',
      },
    ),
    TradingAsset(
      symbol: 'T 4.5 2034',
      name: 'US Treasury 2034',
      type: AssetType.bond,
      price: 98.42,
      dailyChangePercent: 0.08,
      open: 98.31,
      high: 98.51,
      low: 98.12,
      volume: '\$1.8B',
      marketCap: 'US Govt',
      trend: [98.11, 98.18, 98.24, 98.22, 98.30, 98.37, 98.42],
      explanation:
          'A bond is a loan to an issuer. Investors typically receive interest and principal at maturity.',
      stats: {
        'Coupon': '4.50%',
        'Maturity': '2034',
        'Yield': '4.72%',
        'Credit': 'US Govt',
      },
    ),
    TradingAsset(
      symbol: 'ETH',
      name: 'Ethereum',
      type: AssetType.crypto,
      price: 3512.16,
      dailyChangePercent: 2.35,
      open: 3421.84,
      high: 3538.20,
      low: 3396.44,
      volume: '\$18B',
      marketCap: '\$422B',
      trend: [3340, 3388, 3412, 3450, 3428, 3496, 3512.16],
      explanation:
          'Ethereum is a programmable blockchain asset used for applications, tokens, and settlement.',
      stats: {
        'Market cap': '\$422B',
        '24H volume': '\$18B',
        'Network': 'Ethereum',
        'Trading': '24/7',
      },
    ),
  ];

  static const indices = [
    MarketIndex(name: 'S&P 500', value: 5324.18, changePercent: -0.18),
    MarketIndex(name: 'Nasdaq 100', value: 18942.40, changePercent: 0.44),
    MarketIndex(name: 'Dow Jones', value: 39284.33, changePercent: 0.12),
    MarketIndex(name: 'Euro Stoxx 50', value: 5016.84, changePercent: -0.31),
  ];

  static const activity = [
    ActivityItem(
      title: 'Bought 2 AAPL',
      subtitle: 'Market order filled today',
      amount: '-\$428.64',
      status: 'Filled',
    ),
    ActivityItem(
      title: 'Sold 0.03 BTC',
      subtitle: 'Limit order filled yesterday',
      amount: '+\$2,047.20',
      status: 'Filled',
    ),
    ActivityItem(
      title: 'Bought 5 VOO',
      subtitle: 'Market order filled Apr 28',
      amount: '-\$2,543.50',
      status: 'Filled',
    ),
    ActivityItem(
      title: 'Limit buy ETH',
      subtitle: 'Waiting at \$3,420.00',
      amount: '\$1,710.00',
      status: 'Open',
    ),
  ];

  static List<TradingAsset> get topMovers {
    final sorted = [...assets]
      ..sort(
        (a, b) =>
            b.dailyChangePercent.abs().compareTo(a.dailyChangePercent.abs()),
      );
    return sorted.take(4).toList();
  }

  static List<TradingAsset> get crypto =>
      assets.where((asset) => asset.type == AssetType.crypto).toList();

  static List<TradingAsset> get etfs =>
      assets.where((asset) => asset.type == AssetType.etf).toList();

  static List<PortfolioPosition> get positions => [
    PortfolioPosition(asset: assets[0], quantity: 12, averagePrice: 196.20),
    PortfolioPosition(asset: assets[1], quantity: 8, averagePrice: 489.00),
    PortfolioPosition(asset: assets[4], quantity: 0.16, averagePrice: 60300.00),
    PortfolioPosition(asset: assets[6], quantity: 1.8, averagePrice: 3225.00),
  ];

  static const learnTopics = [
    LearnTopic(
      type: AssetType.stock,
      title: 'Stocks',
      summary:
          'Own a slice of a public company and participate in its gains or losses.',
      takeaway:
          'Best for learning company ownership and long-term investing basics.',
    ),
    LearnTopic(
      type: AssetType.etf,
      title: 'ETFs',
      summary:
          'A basket of assets traded like one instrument, often used for diversification.',
      takeaway:
          'Useful when you want broad exposure without choosing every holding.',
    ),
    LearnTopic(
      type: AssetType.option,
      title: 'Options',
      summary: 'Contracts with defined rights, expiries, and strike prices.',
      takeaway:
          'Powerful but complex. Learn payoff diagrams before trading them.',
    ),
    LearnTopic(
      type: AssetType.cfd,
      title: 'CFDs',
      summary:
          'Speculate on price movement without owning the underlying market.',
      takeaway: 'Margin and leverage can magnify losses quickly.',
    ),
    LearnTopic(
      type: AssetType.crypto,
      title: 'Crypto',
      summary: 'Digital assets that trade globally around the clock.',
      takeaway: 'Volatility is high, so position sizing matters.',
    ),
    LearnTopic(
      type: AssetType.bond,
      title: 'Bonds',
      summary:
          'Loans to governments or companies with interest and maturity terms.',
      takeaway:
          'Often used for income, capital preservation, and rate exposure.',
    ),
  ];
}
