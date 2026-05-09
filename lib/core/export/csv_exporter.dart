import '../journal/journal_entry.dart';
import '../models/paper_order.dart';
import '../options_portfolio/option_position.dart';
import '../options_portfolio/option_trade.dart';

class CsvExporter {
  const CsvExporter._();

  static String paperOrders(List<PaperOrder> orders) {
    return _buildCsv(
      headers: const [
        'timestamp',
        'assetSymbol',
        'assetName',
        'side',
        'quantity',
        'executionPrice',
        'estimatedTotal',
        'status',
        'averageCostAtExecution',
        'realizedProfitLoss',
      ],
      rows: orders
          .map(
            (order) => [
              order.timestamp.toIso8601String(),
              order.assetSymbol,
              order.assetName,
              order.side.name,
              order.quantity.toString(),
              order.executionPrice.toStringAsFixed(4),
              order.estimatedTotal.toStringAsFixed(2),
              order.status.name,
              order.averageCostAtExecution?.toStringAsFixed(4) ?? '',
              order.realizedProfitLoss?.toStringAsFixed(2) ?? '',
            ],
          )
          .toList(growable: false),
    );
  }

  static String journalEntries(List<JournalEntry> entries) {
    return _buildCsv(
      headers: const [
        'createdAt',
        'updatedAt',
        'id',
        'title',
        'body',
        'linkedOrderId',
        'linkedAssetSymbol',
        'linkedStrategy',
        'mood',
        'convictionRating',
        'riskRating',
        'outcome',
        'lessonsLearned',
        'tags',
      ],
      rows: entries
          .map(
            (entry) => [
              entry.createdAt.toIso8601String(),
              entry.updatedAt.toIso8601String(),
              entry.id,
              entry.title,
              entry.body,
              entry.linkedOrderId ?? '',
              entry.linkedAssetSymbol ?? '',
              entry.linkedStrategy?.name ?? '',
              entry.mood?.name ?? '',
              entry.convictionRating.toString(),
              entry.riskRating.toString(),
              entry.outcome?.name ?? '',
              entry.lessonsLearned ?? '',
              entry.tags.join('; '),
            ],
          )
          .toList(growable: false),
    );
  }

  static String optionPositions(List<OptionPosition> positions) {
    return _buildCsv(
      headers: const [
        'id',
        'underlyingSymbol',
        'underlyingName',
        'optionType',
        'side',
        'strikePrice',
        'premium',
        'contractsCount',
        'multiplier',
        'openedAt',
        'expirationDate',
        'status',
        'linkedStrategy',
        'linkedUnderlyingPositionId',
        'notes',
      ],
      rows: positions
          .map(
            (position) => [
              position.id,
              position.underlyingSymbol,
              position.underlyingName ?? '',
              position.optionType.name,
              position.side.name,
              position.strikePrice.toStringAsFixed(4),
              position.premium.toStringAsFixed(4),
              position.contractsCount.toString(),
              position.multiplier.toString(),
              position.openedAt.toIso8601String(),
              position.expirationDate.toIso8601String(),
              position.status.name,
              position.linkedStrategy?.name ?? '',
              position.linkedUnderlyingPositionId ?? '',
              position.notes ?? '',
            ],
          )
          .toList(growable: false),
    );
  }

  static String optionTrades(List<OptionTrade> trades) {
    return _buildCsv(
      headers: const [
        'id',
        'positionId',
        'createdAt',
        'eventType',
        'premium',
        'quantity',
        'realizedPnl',
        'notes',
      ],
      rows: trades
          .map(
            (trade) => [
              trade.id,
              trade.positionId,
              trade.createdAt.toIso8601String(),
              trade.eventType.name,
              trade.premium.toStringAsFixed(4),
              trade.quantity.toStringAsFixed(4),
              trade.realizedPnl?.toStringAsFixed(2) ?? '',
              trade.notes ?? '',
            ],
          )
          .toList(growable: false),
    );
  }

  static String _buildCsv({
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_escape).join(','));
    }
    return buffer.toString();
  }

  static String _escape(Object? value) {
    final text = value?.toString() ?? '';
    final escaped = text.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('\n') ||
        escaped.contains('\r') ||
        escaped.contains('"')) {
      return '"$escaped"';
    }
    return escaped;
  }
}
