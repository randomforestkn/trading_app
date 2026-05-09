import 'restore_plan.dart';

class ImportResult {
  const ImportResult({
    required this.restorePlan,
    required this.restoredAt,
    required this.appliedSections,
    required this.mode,
    required this.message,
  });

  final RestorePlan restorePlan;
  final DateTime restoredAt;
  final List<String> appliedSections;
  final ImportRestoreMode mode;
  final String message;

  Map<String, Object?> toJson() {
    return {
      'restorePlan': restorePlan.toJson(),
      'restoredAt': restoredAt.toIso8601String(),
      'appliedSections': appliedSections,
      'mode': mode.name,
      'message': message,
    };
  }
}
