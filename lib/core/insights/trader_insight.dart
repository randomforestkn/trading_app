import 'dart:convert';

enum TraderInsightCategory {
  psychology,
  risk,
  strategy,
  execution,
  consistency,
  optionsIncome,
}

extension TraderInsightCategoryLabel on TraderInsightCategory {
  String get label {
    return switch (this) {
      TraderInsightCategory.psychology => 'Psychology',
      TraderInsightCategory.risk => 'Risk',
      TraderInsightCategory.strategy => 'Strategy',
      TraderInsightCategory.execution => 'Execution',
      TraderInsightCategory.consistency => 'Consistency',
      TraderInsightCategory.optionsIncome => 'Options income',
    };
  }
}

TraderInsightCategory? traderInsightCategoryFromName(String? value) {
  return switch (value) {
    'psychology' => TraderInsightCategory.psychology,
    'risk' => TraderInsightCategory.risk,
    'strategy' => TraderInsightCategory.strategy,
    'execution' => TraderInsightCategory.execution,
    'consistency' => TraderInsightCategory.consistency,
    'optionsIncome' => TraderInsightCategory.optionsIncome,
    _ => null,
  };
}

enum TraderInsightSeverity { info, positive, warning, critical }

extension TraderInsightSeverityLabel on TraderInsightSeverity {
  String get label {
    return switch (this) {
      TraderInsightSeverity.info => 'Info',
      TraderInsightSeverity.positive => 'Positive',
      TraderInsightSeverity.warning => 'Warning',
      TraderInsightSeverity.critical => 'Critical',
    };
  }
}

TraderInsightSeverity? traderInsightSeverityFromName(String? value) {
  return switch (value) {
    'info' => TraderInsightSeverity.info,
    'positive' => TraderInsightSeverity.positive,
    'warning' => TraderInsightSeverity.warning,
    'critical' => TraderInsightSeverity.critical,
    _ => null,
  };
}

class TraderInsight {
  const TraderInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.createdAt,
    this.relatedSymbol,
    this.relatedStrategy,
    this.metricValue,
    this.actionSuggestion,
  });

  factory TraderInsight.fromJson(Map<String, Object?> json) {
    return TraderInsight(
      id: _readString(json, ['id']) ?? '',
      title: _readString(json, ['title']) ?? '',
      description: _readString(json, ['description']) ?? '',
      category:
          traderInsightCategoryFromName(_readString(json, ['category'])) ??
          TraderInsightCategory.strategy,
      severity:
          traderInsightSeverityFromName(_readString(json, ['severity'])) ??
          TraderInsightSeverity.info,
      createdAt:
          DateTime.tryParse(_readString(json, ['createdAt']) ?? '') ??
          DateTime.now(),
      relatedSymbol: _readString(json, ['relatedSymbol']),
      relatedStrategy: _readString(json, ['relatedStrategy']),
      metricValue: _readNullableDouble(json['metricValue']),
      actionSuggestion: _readString(json, ['actionSuggestion']),
    );
  }

  final String id;
  final String title;
  final String description;
  final TraderInsightCategory category;
  final TraderInsightSeverity severity;
  final DateTime createdAt;
  final String? relatedSymbol;
  final String? relatedStrategy;
  final double? metricValue;
  final String? actionSuggestion;

  TraderInsight copyWith({
    String? id,
    String? title,
    String? description,
    TraderInsightCategory? category,
    TraderInsightSeverity? severity,
    DateTime? createdAt,
    String? relatedSymbol,
    bool clearRelatedSymbol = false,
    String? relatedStrategy,
    bool clearRelatedStrategy = false,
    double? metricValue,
    bool clearMetricValue = false,
    String? actionSuggestion,
    bool clearActionSuggestion = false,
  }) {
    return TraderInsight(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      relatedSymbol: clearRelatedSymbol
          ? null
          : relatedSymbol ?? this.relatedSymbol,
      relatedStrategy: clearRelatedStrategy
          ? null
          : relatedStrategy ?? this.relatedStrategy,
      metricValue: clearMetricValue ? null : metricValue ?? this.metricValue,
      actionSuggestion: clearActionSuggestion
          ? null
          : actionSuggestion ?? this.actionSuggestion,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'severity': severity.name,
      'createdAt': createdAt.toIso8601String(),
      'relatedSymbol': relatedSymbol,
      'relatedStrategy': relatedStrategy,
      'metricValue': metricValue,
      'actionSuggestion': actionSuggestion,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static TraderInsight fromJsonString(String source) {
    return TraderInsight.fromJson(
      Map<String, Object?>.from(jsonDecode(source) as Map),
    );
  }
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

double? _readNullableDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}
