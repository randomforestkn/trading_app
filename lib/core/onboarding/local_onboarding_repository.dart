import 'dart:convert';

import '../data/app_result.dart';
import '../utils/app_logger.dart';
import 'onboarding_progress.dart';
import 'onboarding_repository.dart';
import 'onboarding_store.dart';

class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository({OnboardingStore? store})
    : _store = store ?? MemoryOnboardingStore();

  final OnboardingStore _store;

  @override
  Future<AppResult<OnboardingProgress?>> loadProgress() async {
    try {
      final raw = await _store.read();
      if (raw == null || raw.isEmpty) {
        return const AppSuccess(null);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        return const AppFailure('Saved onboarding data is invalid.');
      }
      return AppSuccess(OnboardingProgress.fromJson(decoded));
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Onboarding restore failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppFailure('Unable to restore onboarding state.');
    }
  }

  @override
  Future<AppResult<void>> saveProgress(OnboardingProgress progress) async {
    try {
      await _store.write(jsonEncode(progress.toJson()));
      return const AppSuccess(null);
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Onboarding save failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppFailure('Unable to save onboarding state.');
    }
  }

  @override
  Future<AppResult<void>> clear() async {
    try {
      await _store.clear();
      return const AppSuccess(null);
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Onboarding clear failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppFailure('Unable to clear onboarding state.');
    }
  }
}
