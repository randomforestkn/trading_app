import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/app_result.dart';
import 'package:trading_app/core/data/auth_api_client.dart';
import 'package:trading_app/core/data/auth_provider_config.dart';
import 'package:trading_app/core/data/auth_store.dart';
import 'package:trading_app/core/data/remote_auth_repository.dart';
import 'package:trading_app/core/models/app_user.dart';
import 'package:trading_app/core/models/auth_session.dart';

void main() {
  test('remote sign-in success maps to AuthSession', () async {
    final client = _FakeAuthApiClient(
      config: AuthProviderConfig.fromValues(
        provider: 'supabase',
        useRemoteAuth: true,
        baseUrl: 'https://example.com',
        publicKey: 'public',
        redirectUrl: 'myapp://auth',
      ),
      signInResult: AppSuccess(
        AuthSession(
          user: AppUser(
            id: 'u1',
            email: 'user@example.com',
            displayName: 'User',
            createdAt: DateTime.utc(2025),
          ),
          createdAt: DateTime.utc(2025),
          accessToken: 'access',
          refreshToken: 'refresh',
          provider: 'supabase',
        ),
      ),
    );
    final store = _MemoryStore();
    final repository = RemoteAuthRepository(apiClient: client, store: store);

    final result = await repository.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password',
    );

    result.when(
      success: (session) {
        expect(session.user.email, 'user@example.com');
        expect(store.value, isNotNull);
      },
      failure: fail,
    );
  });

  test('remote sign-in failure returns AppFailure', () async {
    final client = _FakeAuthApiClient(
      config: AuthProviderConfig.fromValues(
        provider: 'supabase',
        useRemoteAuth: true,
        baseUrl: 'https://example.com',
        publicKey: 'public',
        redirectUrl: 'myapp://auth',
      ),
      signInResult: const AppFailure('Invalid credentials'),
    );
    final repository = RemoteAuthRepository(
      apiClient: client,
      store: _MemoryStore(),
    );

    final result = await repository.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password',
    );

    result.when(
      success: (_) => fail('Expected failure'),
      failure: (message) => expect(message, contains('Invalid credentials')),
    );
  });

  test('remote sign-up success maps to AuthSession', () async {
    final client = _FakeAuthApiClient(
      config: AuthProviderConfig.fromValues(
        provider: 'supabase',
        useRemoteAuth: true,
        baseUrl: 'https://example.com',
        publicKey: 'public',
        redirectUrl: 'myapp://auth',
      ),
      signInResult: AppSuccess(
        AuthSession(
          user: AppUser(
            id: 'u2',
            email: 'new@example.com',
            displayName: 'New User',
            createdAt: DateTime.utc(2025),
          ),
          createdAt: DateTime.utc(2025),
          accessToken: 'access',
          refreshToken: 'refresh',
          provider: 'supabase',
        ),
      ),
    );
    final repository = RemoteAuthRepository(
      apiClient: client,
      store: _MemoryStore(),
    );

    final result = await repository.signUpWithEmailPassword(
      email: 'new@example.com',
      password: 'password',
    );

    result.when(
      success: (session) => expect(session.user.email, 'new@example.com'),
      failure: fail,
    );
  });

  test('remote auth falls back safely without config', () async {
    final client = _FakeAuthApiClient(
      config: AuthProviderConfig.fromValues(
        provider: 'supabase',
        useRemoteAuth: true,
        baseUrl: '',
        publicKey: '',
        redirectUrl: '',
      ),
      signInResult: const AppFailure('Missing config'),
    );
    final repository = RemoteAuthRepository(
      apiClient: client,
      store: _MemoryStore(),
    );

    final result = await repository.restoreSession();

    result.when(success: (session) => expect(session, isNull), failure: fail);
  });
}

class _FakeAuthApiClient implements AuthApiClient {
  _FakeAuthApiClient({required this.config, required this.signInResult});

  @override
  final AuthProviderConfig config;
  final AppResult<AuthSession> signInResult;

  @override
  Future<AppResult<AuthSession>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return signInResult;
  }

  @override
  Future<AppResult<AuthSession>> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return signInResult;
  }

  @override
  Future<AppResult<void>> signOut({AuthSession? session}) async {
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<AuthSession?>> restoreSession({AuthSession? session}) async {
    return const AppSuccess(null);
  }
}

class _MemoryStore implements AuthStore {
  String? value;

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}
