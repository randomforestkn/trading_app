enum StrategySeverity { info, warning, danger }

class StrategyWarning {
  const StrategyWarning(
    this.message, {
    this.severity = StrategySeverity.warning,
  });

  final String message;
  final StrategySeverity severity;
}

class StrategyScenario {
  const StrategyScenario({
    required this.title,
    required this.description,
    this.severity = StrategySeverity.info,
  });

  final String title;
  final String description;
  final StrategySeverity severity;
}

abstract class StrategySimulator<T> {
  T simulate();
}
