import 'dart:convert';

import '../config/app_config.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../utils/app_logger.dart';
import 'app_result.dart';
import 'auth_api_client.dart';
import 'auth_repository.dart';
import 'auth_store.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({required AuthApiClient apiClient, AuthStore? store})
    : _apiClient = apiClient,
      _store = store ?? SharedPreferencesAuthStore();

  final AuthApiClient _apiClient;
  final AuthStore _store;

  @override
  Future<AppResult<AppUser?>> currentUser() async {
    final sessionResult = await restoreSession();
    return sessionResult.when(
      success: (session) => AppSuccess(session?.user),
      failure: AppFailure.new,
    );
  }

  @override
  Future<AppResult<AuthSession?>> restoreSession() async {
    final savedSession = await _readSavedSession();
    if (savedSession == null) {
      return const AppSuccess(null);
    }

    if (!_apiClient.config.isRemoteEnabled ||
        savedSession.provider == 'demo' ||
        (savedSession.accessToken == null &&
            savedSession.refreshToken == null)) {
      return AppSuccess(savedSession);
    }

    final remoteResult = await _apiClient.restoreSession(session: savedSession);
    if (remoteResult is AppSuccess<AuthSession?>) {
      final restored = remoteResult.data ?? savedSession;
      await _saveSession(restored);
      return AppSuccess(restored);
    }
    return AppFailure((remoteResult as AppFailure<AuthSession?>).message);
  }

  @override
  Future<AppResult<AuthSession>> signInDemo() async {
    final now = DateTime.now();
    final session = AuthSession(
      user: AppUser(
        id: AppConfig.demoUserId,
        email: AppConfig.demoUserEmail,
        displayName: AppConfig.demoUserDisplayName,
        createdAt: now,
      ),
      createdAt: now,
      provider: 'demo',
    );
    final saveResult = await _saveSession(session);
    return saveResult.when(
      success: (_) => AppSuccess(session),
      failure: AppFailure.new,
    );
  }

  @override
  Future<AppResult<void>> signOut() async {
    final session = await _readSavedSession();
    if (session != null && _apiClient.config.isRemoteEnabled) {
      await _apiClient.signOut(session: session);
    }
    await _store.clear();
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> saveSession(AuthSession session) async {
    return _saveSession(session);
  }

  @override
  Future<AppResult<AuthSession>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.signInWithEmailPassword(
      email: email,
      password: password,
    );
    if (result is AppFailure<AuthSession>) {
      return AppFailure(result.message);
    }

    final session = (result as AppSuccess<AuthSession>).data;
    final saveResult = await _saveSession(session);
    return saveResult.when(
      success: (_) => AppSuccess(session),
      failure: AppFailure.new,
    );
  }

  @override
  Future<AppResult<AuthSession>> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.signUpWithEmailPassword(
      email: email,
      password: password,
    );
    if (result is AppFailure<AuthSession>) {
      return AppFailure(result.message);
    }

    final session = (result as AppSuccess<AuthSession>).data;
    final saveResult = await _saveSession(session);
    return saveResult.when(
      success: (_) => AppSuccess(session),
      failure: AppFailure.new,
    );
  }

  Future<AppResult<void>> _saveSession(AuthSession session) async {
    try {
      await _store.write(jsonEncode(session.toJson()));
      return const AppSuccess(null);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Remote auth session save failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppFailure('Unable to save auth session.');
    }
  }

  Future<AuthSession?> _readSavedSession() async {
    try {
      final saved = await _store.read();
      if (saved == null || saved.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(saved);
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      return AuthSession.fromJson(decoded);
    } on FormatException {
      await _store.clear();
      return null;
    } on TypeError {
      await _store.clear();
      return null;
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Remote auth session load failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
