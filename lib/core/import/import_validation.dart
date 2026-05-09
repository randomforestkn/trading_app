enum ImportValidationSeverity { info, warning, error }

class ImportValidationIssue {
  const ImportValidationIssue({required this.message, required this.severity});

  final String message;
  final ImportValidationSeverity severity;

  bool get isWarning => severity == ImportValidationSeverity.warning;

  bool get isError => severity == ImportValidationSeverity.error;
}

class ImportValidation {
  const ImportValidation({this.issues = const []});

  final List<ImportValidationIssue> issues;

  List<ImportValidationIssue> get warnings =>
      issues.where((issue) => issue.isWarning).toList(growable: false);

  List<ImportValidationIssue> get errors =>
      issues.where((issue) => issue.isError).toList(growable: false);

  bool get hasWarnings => warnings.isNotEmpty;

  bool get hasErrors => errors.isNotEmpty;

  ImportValidation addIssue(String message, ImportValidationSeverity severity) {
    return ImportValidation(
      issues: [
        ...issues,
        ImportValidationIssue(message: message, severity: severity),
      ],
    );
  }
}
