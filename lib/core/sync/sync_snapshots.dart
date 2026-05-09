import 'dart:convert';

import '../data/paper_trading_account.dart';
import '../journal/journal_entry.dart';
import '../models/auth_session.dart';
import '../options_portfolio/options_portfolio_account.dart';
import 'sync_operation.dart';

Map<String, Object?> paperTradingSnapshot(PaperTradingAccount account) {
  return account.toJson();
}

Map<String, Object?> journalSnapshot(List<JournalEntry> entries) {
  return {
    'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
  };
}

Map<String, Object?> optionsPortfolioSnapshot(OptionsPortfolioAccount account) {
  return account.toJson();
}

Map<String, Object?> authSessionSnapshot(AuthSession? session) {
  return {'session': session?.toJson()};
}

String syncPayloadHash(Map<String, Object?> payload) {
  return _stableHash(jsonEncode(payload));
}

String _stableHash(String value) {
  var hash = 5381;
  for (final codeUnit in value.codeUnits) {
    hash = ((hash << 5) + hash) + codeUnit;
  }
  return hash.toUnsigned(32).toRadixString(16);
}

SyncOperation buildSyncOperation({
  required String id,
  required SyncEntityType entityType,
  required SyncOperationType operationType,
  required DateTime createdAt,
  String? entityId,
  Map<String, Object?>? payload,
}) {
  return SyncOperation(
    id: id,
    entityType: entityType,
    operationType: operationType,
    entityId: entityId,
    createdAt: createdAt,
    payload: payload,
    payloadHash: payload == null ? null : syncPayloadHash(payload),
    status: SyncOperationStatus.pending,
  );
}
