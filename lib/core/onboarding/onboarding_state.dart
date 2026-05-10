import 'package:flutter/widgets.dart';

import '../config/app_config.dart';
import '../data/app_result.dart';
import '../utils/app_logger.dart';
import 'local_onboarding_repository.dart';
import 'onboarding_progress.dart';
import 'onboarding_repository.dart';
import 'onboarding_store.dart';

class OnboardingState extends ChangeNotifier {
  OnboardingState({OnboardingRepository? repository})
    : _repository =
          repository ??
          LocalOnboardingRepository(store: SharedPreferencesOnboardingStore());

  final OnboardingRepository _repository;
  OnboardingProgress? _progress;
  bool _isLoading = false;
  String? _errorMessage;

  OnboardingProgress? get progress => _progress;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isAccepted =>
      _progress?.isAccepted == true &&
      (_progress?.acceptedVersion ?? 0) >= AppConfig.onboardingVersion;

  DateTime? get acceptedAt => _progress?.acceptedAt;

  DateTime? get viewedAt => _progress?.viewedAt;

  Future<void> load() async {
    _setLoading(true);
    late final AppResult<OnboardingProgress?> result;
    try {
      result = await _repository.loadProgress();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Onboarding load threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to restore onboarding state.';
      _setLoading(false);
      return;
    }
    result.when(
      success: (progress) {
        _progress = progress;
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Onboarding load failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
  }

  Future<AppResult<void>> accept() async {
    final now = DateTime.now();
    final progress = (_progress ?? _defaultProgress()).copyWith(
      viewedVersion: AppConfig.onboardingVersion,
      acceptedVersion: AppConfig.onboardingVersion,
      viewedAt: now,
      acceptedAt: now,
    );
    return _save(progress);
  }

  Future<AppResult<void>> markViewed() async {
    final now = DateTime.now();
    final progress = (_progress ?? _defaultProgress()).copyWith(
      viewedVersion: AppConfig.onboardingVersion,
      viewedAt: now,
    );
    return _save(progress);
  }

  Future<AppResult<void>> _save(OnboardingProgress progress) async {
    _setLoading(true);
    late final AppResult<void> result;
    try {
      result = await _repository.saveProgress(progress);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Onboarding save threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to save onboarding state.';
      _setLoading(false);
      return const AppFailure('Unable to save onboarding state.');
    }
    result.when(
      success: (_) {
        _progress = progress;
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Onboarding save failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
    return _errorMessage == null
        ? const AppSuccess(null)
        : AppFailure(_errorMessage!);
  }

  OnboardingProgress _defaultProgress() {
    return const OnboardingProgress(
      viewedVersion: 0,
      acceptedVersion: 0,
      viewedAt: null,
      acceptedAt: null,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

class OnboardingScope extends InheritedNotifier<OnboardingState> {
  const OnboardingScope({
    required OnboardingState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static OnboardingState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OnboardingScope>();
    assert(scope != null, 'OnboardingScope was not found in the widget tree.');
    return scope!.notifier!;
  }

  static OnboardingState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<OnboardingScope>()
        ?.notifier;
  }
}
