import 'dart:convert';

enum JournalStrategyType { coveredCall, cashSecuredPut, wheel, stockTrade }

extension JournalStrategyTypeLabel on JournalStrategyType {
  String get label {
    return switch (this) {
      JournalStrategyType.coveredCall => 'Covered Call',
      JournalStrategyType.cashSecuredPut => 'Cash-Secured Put',
      JournalStrategyType.wheel => 'Wheel',
      JournalStrategyType.stockTrade => 'Stock Trade',
    };
  }
}

JournalStrategyType? journalStrategyTypeFromName(String? value) {
  return switch (value) {
    'coveredCall' => JournalStrategyType.coveredCall,
    'cashSecuredPut' => JournalStrategyType.cashSecuredPut,
    'wheel' => JournalStrategyType.wheel,
    'stockTrade' => JournalStrategyType.stockTrade,
    _ => null,
  };
}

enum JournalMood { calm, confident, anxious, impulsive, disciplined }

extension JournalMoodLabel on JournalMood {
  String get label {
    return switch (this) {
      JournalMood.calm => 'Calm',
      JournalMood.confident => 'Confident',
      JournalMood.anxious => 'Anxious',
      JournalMood.impulsive => 'Impulsive',
      JournalMood.disciplined => 'Disciplined',
    };
  }
}

JournalMood? journalMoodFromName(String? value) {
  return switch (value) {
    'calm' => JournalMood.calm,
    'confident' => JournalMood.confident,
    'anxious' => JournalMood.anxious,
    'impulsive' => JournalMood.impulsive,
    'disciplined' => JournalMood.disciplined,
    _ => null,
  };
}

enum JournalOutcome { open, win, loss, breakeven }

extension JournalOutcomeLabel on JournalOutcome {
  String get label {
    return switch (this) {
      JournalOutcome.open => 'Open',
      JournalOutcome.win => 'Win',
      JournalOutcome.loss => 'Loss',
      JournalOutcome.breakeven => 'Breakeven',
    };
  }
}

JournalOutcome? journalOutcomeFromName(String? value) {
  return switch (value) {
    'open' => JournalOutcome.open,
    'win' => JournalOutcome.win,
    'loss' => JournalOutcome.loss,
    'breakeven' => JournalOutcome.breakeven,
    _ => null,
  };
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.body,
    this.linkedOrderId,
    this.linkedAssetSymbol,
    this.linkedStrategy,
    this.mood,
    this.convictionRating = 3,
    this.riskRating = 3,
    this.outcome,
    this.lessonsLearned,
    this.tags = const [],
  });

  factory JournalEntry.fromJson(Map<String, Object?> json) {
    final createdAt =
        _parseDateTime(
          json['createdAt'] as String? ?? json['created_at'] as String?,
        ) ??
        DateTime.now();
    final updatedAt =
        _parseDateTime(
          json['updatedAt'] as String? ?? json['updated_at'] as String?,
        ) ??
        createdAt;

    return JournalEntry(
      id:
          _readString(json, ['id']) ??
          'legacy-${createdAt.microsecondsSinceEpoch}',
      createdAt: createdAt,
      updatedAt: updatedAt,
      title: _readString(json, ['title']) ?? '',
      body: _readString(json, ['body']) ?? _readString(json, ['notes']) ?? '',
      linkedOrderId: _readString(json, ['linkedOrderId']),
      linkedAssetSymbol:
          _readString(json, ['linkedAssetSymbol']) ??
          _readString(json, ['symbol']),
      linkedStrategy: journalStrategyTypeFromName(
        _readString(json, ['linkedStrategy']) ??
            _readString(json, ['strategy']),
      ),
      mood: journalMoodFromName(_readString(json, ['mood'])),
      convictionRating: _parseRating(json['convictionRating']),
      riskRating: _parseRating(json['riskRating']),
      outcome: journalOutcomeFromName(_readString(json, ['outcome'])),
      lessonsLearned:
          _readString(json, ['lessonsLearned']) ??
          _readString(json, ['lessons']),
      tags: _parseTags(json['tags']),
    );
  }

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String body;
  final String? linkedOrderId;
  final String? linkedAssetSymbol;
  final JournalStrategyType? linkedStrategy;
  final JournalMood? mood;
  final int convictionRating;
  final int riskRating;
  final JournalOutcome? outcome;
  final String? lessonsLearned;
  final List<String> tags;

  bool get hasLessonsLearned =>
      lessonsLearned != null && lessonsLearned!.trim().isNotEmpty;

  String get displayTitle {
    final trimmed = title.trim();
    return trimmed.isEmpty ? 'Untitled note' : trimmed;
  }

  JournalEntry copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    String? body,
    String? linkedOrderId,
    bool clearLinkedOrderId = false,
    String? linkedAssetSymbol,
    bool clearLinkedAssetSymbol = false,
    JournalStrategyType? linkedStrategy,
    bool clearLinkedStrategy = false,
    JournalMood? mood,
    bool clearMood = false,
    int? convictionRating,
    int? riskRating,
    JournalOutcome? outcome,
    bool clearOutcome = false,
    String? lessonsLearned,
    bool clearLessonsLearned = false,
    List<String>? tags,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      body: body ?? this.body,
      linkedOrderId: clearLinkedOrderId
          ? null
          : linkedOrderId ?? this.linkedOrderId,
      linkedAssetSymbol: clearLinkedAssetSymbol
          ? null
          : linkedAssetSymbol ?? this.linkedAssetSymbol,
      linkedStrategy: clearLinkedStrategy
          ? null
          : linkedStrategy ?? this.linkedStrategy,
      mood: clearMood ? null : mood ?? this.mood,
      convictionRating: convictionRating ?? this.convictionRating,
      riskRating: riskRating ?? this.riskRating,
      outcome: clearOutcome ? null : outcome ?? this.outcome,
      lessonsLearned: clearLessonsLearned
          ? null
          : lessonsLearned ?? this.lessonsLearned,
      tags: tags ?? this.tags,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'title': title,
      'body': body,
      'linkedOrderId': linkedOrderId,
      'linkedAssetSymbol': linkedAssetSymbol,
      'linkedStrategy': linkedStrategy?.name,
      'mood': mood?.name,
      'convictionRating': convictionRating,
      'riskRating': riskRating,
      'outcome': outcome?.name,
      'lessonsLearned': lessonsLearned,
      'tags': tags,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static JournalEntry fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Saved journal entry must be an object.');
    }
    return JournalEntry.fromJson(
      Map<String, Object?>.from(decoded.cast<String, dynamic>()),
    );
  }

  static String? _readString(Map<String, Object?> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static int _parseRating(Object? value) {
    final parsed = (value as num?)?.toInt() ?? 3;
    if (parsed < 1) {
      return 1;
    }
    if (parsed > 5) {
      return 5;
    }
    return parsed;
  }

  static List<String> _parseTags(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
