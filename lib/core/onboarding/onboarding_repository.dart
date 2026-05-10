import '../data/app_result.dart';
import 'onboarding_progress.dart';

abstract class OnboardingRepository {
  Future<AppResult<OnboardingProgress?>> loadProgress();

  Future<AppResult<void>> saveProgress(OnboardingProgress progress);

  Future<AppResult<void>> clear();
}
