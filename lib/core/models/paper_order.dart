enum PaperOrderSide { buy, sell }

extension PaperOrderSideLabel on PaperOrderSide {
  String get label {
    return switch (this) {
      PaperOrderSide.buy => 'Buy',
      PaperOrderSide.sell => 'Sell',
    };
  }
}

enum PaperOrderStatus { filled, rejected }

extension PaperOrderStatusLabel on PaperOrderStatus {
  String get label {
    return switch (this) {
      PaperOrderStatus.filled => 'Filled',
      PaperOrderStatus.rejected => 'Rejected',
    };
  }
}

class PaperOrder {
  const PaperOrder({
    required this.assetSymbol,
    required this.assetName,
    required this.side,
    required this.quantity,
    required this.executionPrice,
    required this.estimatedTotal,
    required this.timestamp,
    required this.status,
  });

  final String assetSymbol;
  final String assetName;
  final PaperOrderSide side;
  final double quantity;
  final double executionPrice;
  final double estimatedTotal;
  final DateTime timestamp;
  final PaperOrderStatus status;
}
