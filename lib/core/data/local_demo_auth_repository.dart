import 'dart:convert';

import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../config/app_config.dart';
import 'app_result.dart';
import 'auth_repository.dart';
import 'auth_store.dart';

class LocalDemoAuthRepository implements AuthRepository {
  const LocalDemoAuthRepository({this.store});

  final AuthStore? store;

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
    final savedSession = await store?.read();
    if (savedSession == null) {
      return const AppSuccess(null);
    }

    try {
      final decoded = jsonDecode(savedSession);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Saved auth session must be an object.');
      }
      return AppSuccess(AuthSession.fromJson(decoded));
    } on FormatException {
      await store?.clear();
      return const AppSuccess(null);
    } on TypeError {
      await store?.clear();
      return const AppSuccess(null);
    }
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
    );
    final result = await saveSession(session);
    return result.when(
      success: (_) => AppSuccess(session),
      failure: AppFailure.new,
    );
  }

  @override
  Future<AppResult<void>> signOut() async {
    await store?.clear();
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> saveSession(AuthSession session) async {
    await store?.write(jsonEncode(session.toJson()));
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<AuthSession>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return const AppFailure('Email/password sign-in is not implemented yet.');
  }
}
