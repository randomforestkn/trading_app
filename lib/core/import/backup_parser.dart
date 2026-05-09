import 'dart:convert';

import '../config/app_config.dart';
import '../data/app_result.dart';
import '../data/paper_trading_account.dart';
import '../data/mock_market_data.dart';
import '../export/export_format.dart';
import '../journal/journal_entry.dart';
import '../models/auth_session.dart';
import '../options_portfolio/option_position.dart';
import '../options_portfolio/option_trade.dart';
import '../options_portfolio/options_portfolio_account.dart';
import '../options_portfolio/wheel_cycle.dart';
import '../sync/sync_metadata.dart';
import 'import_validation.dart';
import 'restore_plan.dart';

class BackupParser {
  const BackupParser._();

  static AppResult<RestorePlan> parse(String backupJson) {
    try {
      final decoded = jsonDecode(backupJson);
      if (decoded is! Map) {
        return const AppFailure('Backup must be a JSON object.');
      }
      final root = Map<String, Object?>.from(decoded.cast<String, dynamic>());
      final export = _requireMap(root['export']);
      if (export == null) {
        return const AppFailure('Backup is missing its export metadata.');
      }

      final backupVersion =
          _readInt(root['backupVersion']) ??
          _readInt(export['backupVersion']) ??
          AppConfig.backupFormatVersion;
      if (backupVersion != AppConfig.backupFormatVersion) {
        return AppFailure(
          'Unsupported backup version $backupVersion. Expected ${AppConfig.backupFormatVersion}.',
        );
      }

      final includedSections = _readStringList(export['includedSections']);
      if (includedSections.isEmpty) {
        return const AppFailure('Backup does not include any sections.');
      }

      final validationIssues = <ImportValidationIssue>[];
      final unsupportedSections = _detectUnsupportedSections(root);

      final createdAt =
          _readDateTime(export['createdAt']) ??
          _readDateTime(root['createdAt']) ??
          DateTime.now();
      final format = _exportFormatFromName(
        _readString(export, ['format']) ?? _readString(root, ['format']),
      );

      final paperTradingJson = _requireMap(root['paperTrading']);
      if (paperTradingJson == null) {
        return const AppFailure(
          'Backup is missing the paper trading snapshot.',
        );
      }
      final paperTradingAccount = _parsePaperTradingAccount(
        paperTradingJson,
        validationIssues,
      );

      final journalJson = _requireMap(root['journal']);
      if (journalJson == null) {
        return const AppFailure('Backup is missing the journal snapshot.');
      }
      final journalEntries = _parseJournalEntries(
        journalJson,
        validationIssues,
      );

      final optionsJson = _requireMap(root['optionsPortfolio']);
      if (optionsJson == null) {
        return const AppFailure(
          'Backup is missing the options portfolio snapshot.',
        );
      }
      final optionsPortfolioAccount = _parseOptionsPortfolioAccount(
        optionsJson,
        validationIssues,
      );

      final syncMetadataJson = _requireMap(root['sync']);
      final syncMetadata = syncMetadataJson == null
          ? null
          : _parseSyncMetadata(syncMetadataJson, validationIssues);

      final authJson = _requireMap(root['auth']);
      final authSession = authJson == null
          ? null
          : _parseAuthSession(authJson, validationIssues);

      final hasData =
          paperTradingAccount.orders.isNotEmpty ||
          paperTradingAccount.positions.isNotEmpty ||
          journalEntries.isNotEmpty ||
          optionsPortfolioAccount.positions.isNotEmpty ||
          optionsPortfolioAccount.trades.isNotEmpty ||
          optionsPortfolioAccount.wheelCycles.isNotEmpty;
      if (!hasData) {
        return const AppFailure('Backup does not contain any restorable data.');
      }

      final validation = ImportValidation(issues: validationIssues);
      if (validation.hasErrors) {
        return AppFailure(
          validation.errors.map((issue) => issue.message).join(' '),
        );
      }

      return AppSuccess(
        RestorePlan(
          backupVersion: backupVersion,
          createdAt: createdAt,
          exportFormat: format,
          includedSections: includedSections,
          paperTradingAccount: paperTradingAccount,
          journalEntries: journalEntries,
          optionsPortfolioAccount: optionsPortfolioAccount,
          syncMetadata: syncMetadata,
          authSession: authSession,
          unsupportedSections: unsupportedSections,
          validation: validation,
        ),
      );
    } on FormatException catch (error) {
      return AppFailure('Invalid backup JSON: ${error.message}');
    } catch (error) {
      return AppFailure('Unable to parse backup: $error');
    }
  }
}

PaperTradingAccount _parsePaperTradingAccount(
  Map<String, Object?> json,
  List<ImportValidationIssue> issues,
) {
  if (!_hasRequiredKeys(json, const ['cashBalance', 'positions', 'orders']) ||
      json['cashBalance'] is! num ||
      json['positions'] is! List ||
      json['orders'] is! List) {
    issues.add(
      const ImportValidationIssue(
        message: 'Paper trading snapshot is corrupt.',
        severity: ImportValidationSeverity.error,
      ),
    );
    return PaperTradingAccount.defaultAccount();
  }

  final positions = json['positions'] as List;
  final orders = json['orders'] as List;
  if (!_validatePaperPositions(positions, issues) ||
      !_validatePaperOrders(orders, issues)) {
    return PaperTradingAccount.defaultAccount();
  }

  final account = PaperTradingAccount.fromJson(json);
  if (account.cashBalance < 0) {
    issues.add(
      const ImportValidationIssue(
        message: 'Paper trading cash balance is invalid.',
        severity: ImportValidationSeverity.error,
      ),
    );
  }
  return account;
}

bool _validatePaperPositions(List items, List<ImportValidationIssue> issues) {
  for (final item in items) {
    if (item is! Map) {
      issues.add(
        const ImportValidationIssue(
          message: 'Paper trading position is malformed.',
          severity: ImportValidationSeverity.error,
        ),
      );
      return false;
    }
    final positionJson = Map<String, Object?>.from(
      item.cast<String, dynamic>(),
    );
    final symbol = _readString(positionJson, ['symbol']);
    if (symbol == null ||
        _readDoubleValue(positionJson['quantity']) == null ||
        _readDoubleValue(positionJson['averageCost']) == null ||
        !_assetExists(symbol)) {
      issues.add(
        const ImportValidationIssue(
          message: 'Paper trading position is corrupt.',
          severity: ImportValidationSeverity.error,
        ),
      );
      return false;
    }
  }
  return true;
}

bool _validatePaperOrders(List items, List<ImportValidationIssue> issues) {
  for (final item in items) {
    if (item is! Map) {
      issues.add(
        const ImportValidationIssue(
          message: 'Paper trading order is malformed.',
          severity: ImportValidationSeverity.error,
        ),
      );
      return false;
    }
    final orderJson = Map<String, Object?>.from(item.cast<String, dynamic>());
    final requiredStrings = [
      _readString(orderJson, ['assetSymbol']),
      _readString(orderJson, ['assetName']),
      _readString(orderJson, ['side']),
      _readString(orderJson, ['status']),
      _readString(orderJson, ['timestamp']),
    ];
    if (requiredStrings.any((value) => value == null) ||
        _readDoubleValue(orderJson['quantity']) == null ||
        _readDoubleValue(orderJson['executionPrice']) == null ||
        _readDoubleValue(orderJson['estimatedTotal']) == null ||
        _readDateTime(orderJson['timestamp']) == null ||
        !_assetExists(_readString(orderJson, ['assetSymbol']) ?? '') ||
        !_isKnownPaperOrderSide(_readString(orderJson, ['side']) ?? '') ||
        !_isKnownPaperOrderStatus(_readString(orderJson, ['status']) ?? '')) {
      issues.add(
        const ImportValidationIssue(
          message: 'Paper trading order is corrupt.',
          severity: ImportValidationSeverity.error,
        ),
      );
      return false;
    }
  }
  return true;
}

List<JournalEntry> _parseJournalEntries(
  Map<String, Object?> json,
  List<ImportValidationIssue> issues,
) {
  final entriesValue = json['entries'];
  if (entriesValue is! List) {
    issues.add(
      const ImportValidationIssue(
        message: 'Journal snapshot is corrupt.',
        severity: ImportValidationSeverity.error,
      ),
    );
    return const [];
  }

  final entries = <JournalEntry>[];
  final ids = <String>{};
  for (final item in entriesValue) {
    if (item is! Map) {
      issues.add(
        const ImportValidationIssue(
          message: 'Journal entry is malformed.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    final entryJson = Map<String, Object?>.from(item.cast<String, dynamic>());
    if (!_hasRequiredKeys(entryJson, const ['id', 'createdAt', 'updatedAt'])) {
      issues.add(
        const ImportValidationIssue(
          message: 'Journal entry is missing required fields.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    final entry = JournalEntry.fromJson(entryJson);
    final hasBody =
        _readString(entryJson, ['body']) != null ||
        _readString(entryJson, ['notes']) != null;
    if (entry.id.trim().isEmpty ||
        _readString(entryJson, ['title']) == null ||
        !hasBody ||
        _readDateTime(entryJson['createdAt']) == null ||
        _readDateTime(entryJson['updatedAt']) == null) {
      issues.add(
        const ImportValidationIssue(
          message: 'Journal entry is missing required fields.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    if (!ids.add(entry.id)) {
      issues.add(
        ImportValidationIssue(
          message: 'Duplicate journal entry id: ${entry.id}.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    entries.add(entry);
  }
  return entries;
}

OptionsPortfolioAccount _parseOptionsPortfolioAccount(
  Map<String, Object?> json,
  List<ImportValidationIssue> issues,
) {
  if (!_hasRequiredKeys(json, const ['positions', 'trades', 'wheelCycles'])) {
    issues.add(
      const ImportValidationIssue(
        message: 'Options portfolio snapshot is corrupt.',
        severity: ImportValidationSeverity.error,
      ),
    );
    return OptionsPortfolioAccount.defaultAccount();
  }

  final positionItems = json['positions'];
  final tradeItems = json['trades'];
  final cycleItems = json['wheelCycles'];
  if (positionItems is! List || tradeItems is! List || cycleItems is! List) {
    issues.add(
      const ImportValidationIssue(
        message: 'Options portfolio snapshot is corrupt.',
        severity: ImportValidationSeverity.error,
      ),
    );
    return OptionsPortfolioAccount.defaultAccount();
  }

  final positions = <OptionPosition>[];
  final positionIds = <String>{};
  for (final item in positionItems) {
    if (item is! Map) {
      issues.add(
        const ImportValidationIssue(
          message: 'Option position is malformed.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    final positionJson = Map<String, Object?>.from(
      item.cast<String, dynamic>(),
    );
    if (!_hasRequiredKeys(positionJson, const [
          'id',
          'underlyingSymbol',
          'optionType',
          'side',
          'strikePrice',
          'premium',
          'contractsCount',
          'openedAt',
          'expirationDate',
          'status',
        ]) ||
        positionJson['strikePrice'] is! num ||
        positionJson['premium'] is! num ||
        positionJson['contractsCount'] is! num ||
        (positionJson['multiplier'] != null &&
            positionJson['multiplier'] is! num)) {
      issues.add(
        const ImportValidationIssue(
          message: 'Option position is missing required fields.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    final optionType = _readString(positionJson, ['optionType']);
    final side = _readString(positionJson, ['side']);
    final status = _readString(positionJson, ['status']);
    if (!_isKnownOptionType(optionType ?? '') ||
        !_isKnownOptionSide(side ?? '') ||
        !_isKnownOptionStatus(status ?? '')) {
      issues.add(
        const ImportValidationIssue(
          message: 'Option position contains unsupported values.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    if (_readDateTime(positionJson['openedAt']) == null ||
        _readDateTime(positionJson['expirationDate']) == null) {
      issues.add(
        const ImportValidationIssue(
          message: 'Option position has invalid dates.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    final position = OptionPosition.fromJson(positionJson);
    if (position.id.trim().isEmpty ||
        position.underlyingSymbol.trim().isEmpty ||
        position.strikePrice <= 0 ||
        position.premium < 0 ||
        position.contractsCount <= 0 ||
        position.multiplier <= 0 ||
        !positionIds.add(position.id)) {
      issues.add(
        ImportValidationIssue(
          message: 'Option position is invalid or duplicated: ${position.id}.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    positions.add(position);
  }

  final trades = <OptionTrade>[];
  final tradeIds = <String>{};
  for (final item in tradeItems) {
    if (item is! Map) {
      issues.add(
        const ImportValidationIssue(
          message: 'Option trade is malformed.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    final tradeJson = Map<String, Object?>.from(item.cast<String, dynamic>());
    if (!_hasRequiredKeys(tradeJson, const [
          'id',
          'positionId',
          'createdAt',
          'eventType',
          'premium',
          'quantity',
        ]) ||
        tradeJson['premium'] is! num ||
        tradeJson['quantity'] is! num ||
        _readDateTime(tradeJson['createdAt']) == null) {
      issues.add(
        const ImportValidationIssue(
          message: 'Option trade is missing required fields.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    final eventType = _readString(tradeJson, ['eventType']);
    if (!_isKnownOptionTradeEvent(eventType ?? '')) {
      issues.add(
        const ImportValidationIssue(
          message: 'Option trade contains unsupported values.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    final trade = OptionTrade.fromJson(tradeJson);
    if (trade.id.trim().isEmpty ||
        trade.positionId.trim().isEmpty ||
        trade.premium < 0 ||
        trade.quantity <= 0 ||
        !tradeIds.add(trade.id)) {
      issues.add(
        ImportValidationIssue(
          message: 'Option trade is invalid or duplicated: ${trade.id}.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    trades.add(trade);
  }

  final wheelCycles = <WheelCycle>[];
  final cycleIds = <String>{};
  for (final item in cycleItems) {
    if (item is! Map) {
      issues.add(
        const ImportValidationIssue(
          message: 'Wheel cycle is malformed.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    final cycleJson = Map<String, Object?>.from(item.cast<String, dynamic>());
    if (!_hasRequiredKeys(cycleJson, const [
          'id',
          'underlyingSymbol',
          'startedAt',
          'status',
        ]) ||
        _readDateTime(cycleJson['startedAt']) == null) {
      issues.add(
        const ImportValidationIssue(
          message: 'Wheel cycle is missing required fields.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    final status = _readString(cycleJson, ['status']);
    if (!_isKnownWheelCycleStatus(status ?? '')) {
      issues.add(
        const ImportValidationIssue(
          message: 'Wheel cycle contains unsupported values.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    final cycle = WheelCycle.fromJson(cycleJson);
    if (cycle.id.trim().isEmpty ||
        cycle.underlyingSymbol.trim().isEmpty ||
        !cycleIds.add(cycle.id)) {
      issues.add(
        ImportValidationIssue(
          message: 'Wheel cycle is invalid or duplicated: ${cycle.id}.',
          severity: ImportValidationSeverity.error,
        ),
      );
      continue;
    }
    wheelCycles.add(cycle);
  }

  return OptionsPortfolioAccount(
    positions: positions,
    trades: trades,
    wheelCycles: wheelCycles,
    lastUpdated: _readDateTime(json['lastUpdated']) ?? DateTime.now(),
  );
}

SyncMetadata? _parseSyncMetadata(
  Map<String, Object?> json,
  List<ImportValidationIssue> issues,
) {
  if (!_hasRequiredKeys(json, const ['syncMode'])) {
    issues.add(
      const ImportValidationIssue(
        message: 'Sync metadata is corrupt.',
        severity: ImportValidationSeverity.warning,
      ),
    );
    return null;
  }
  return SyncMetadata.fromJson(json);
}

AuthSession? _parseAuthSession(
  Map<String, Object?> json,
  List<ImportValidationIssue> issues,
) {
  final user = _requireMap(json['user']);
  if (user == null) {
    issues.add(
      const ImportValidationIssue(
        message: 'Auth session is corrupt.',
        severity: ImportValidationSeverity.warning,
      ),
    );
    return null;
  }
  return AuthSession.fromJson(json);
}

Map<String, Object?>? _requireMap(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.from(value.cast<String, dynamic>());
  }
  return null;
}

bool _hasRequiredKeys(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      return false;
    }
  }
  return true;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<String>()
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}

String? _readString(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

bool _isKnownOptionType(String value) {
  return value == 'call' || value == 'put';
}

bool _isKnownOptionSide(String value) {
  return value == 'sell' || value == 'buy';
}

bool _isKnownOptionStatus(String value) {
  return value == 'open' ||
      value == 'expired' ||
      value == 'assigned' ||
      value == 'closed' ||
      value == 'exercised';
}

bool _isKnownOptionTradeEvent(String value) {
  return value == 'open' ||
      value == 'close' ||
      value == 'expireWorthless' ||
      value == 'assignment' ||
      value == 'exercise';
}

bool _isKnownWheelCycleStatus(String value) {
  return value == 'sellingPuts' ||
      value == 'assigned' ||
      value == 'sellingCalls' ||
      value == 'calledAway' ||
      value == 'closed';
}

DateTime? _readDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? _readDoubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

bool _assetExists(String symbol) {
  return MockMarketData.assets.any(
    (asset) => asset.symbol.toLowerCase() == symbol.toLowerCase(),
  );
}

bool _isKnownPaperOrderSide(String value) {
  return value == 'buy' || value == 'sell';
}

bool _isKnownPaperOrderStatus(String value) {
  return value == 'filled' || value == 'rejected' || value == 'pending';
}

ExportFormat? _exportFormatFromName(String? value) {
  for (final format in ExportFormat.values) {
    if (format.name == value) {
      return format;
    }
  }
  return null;
}

List<String> _detectUnsupportedSections(Map<String, Object?> root) {
  const knownKeys = {
    'backupVersion',
    'export',
    'app',
    'paperTrading',
    'journal',
    'optionsPortfolio',
    'performance',
    'analytics',
    'sync',
    'auth',
  };
  return root.keys
      .whereType<String>()
      .where((key) => !knownKeys.contains(key))
      .toList(growable: false);
}
