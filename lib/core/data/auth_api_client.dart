import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/auth_session.dart';
import 'app_result.dart';
import 'auth_provider_config.dart';

abstract class AuthApiClient {
  AuthProviderConfig get config;

  Future<AppResult<AuthSession>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AppResult<AuthSession>> signUpWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AppResult<void>> signOut({AuthSession? session});

  Future<AppResult<AuthSession?>> restoreSession({AuthSession? session});
}

class HttpAuthApiClient implements AuthApiClient {
  HttpAuthApiClient({required this.providerConfig, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final AuthProviderConfig providerConfig;
  final http.Client _httpClient;

  @override
  AuthProviderConfig get config => providerConfig;

  @override
  Future<AppResult<AuthSession>> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _authenticate(
      path: '/auth/sign-in',
      email: email,
      password: password,
    );
  }

  @override
  Future<AppResult<AuthSession>> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _authenticate(
      path: '/auth/sign-up',
      email: email,
      password: password,
    );
  }

  @override
  Future<AppResult<void>> signOut({AuthSession? session}) async {
    if (!providerConfig.hasRemoteConfig) {
      return const AppFailure(
        'Remote auth is not configured. Provide AUTH_BASE_URL and AUTH_PUBLIC_KEY.',
      );
    }

    final result = await _postJson(
      _buildUri(path: '/auth/sign-out'),
      body: {
        if (session?.accessToken != null) 'accessToken': session!.accessToken,
        if (session?.refreshToken != null)
          'refreshToken': session!.refreshToken,
      },
    );
    return result.when(
      success: (_) => const AppSuccess(null),
      failure: AppFailure.new,
    );
  }

  @override
  Future<AppResult<AuthSession?>> restoreSession({AuthSession? session}) async {
    if (!providerConfig.hasRemoteConfig) {
      return const AppFailure(
        'Remote auth is not configured. Provide AUTH_BASE_URL and AUTH_PUBLIC_KEY.',
      );
    }

    final storedToken = session?.accessToken ?? session?.refreshToken;
    if (storedToken == null || storedToken.isEmpty) {
      return const AppFailure('No session token available to restore.');
    }

    final result = await _postJson(
      _buildUri(path: '/auth/session'),
      body: {'token': storedToken},
    );
    return result.when(
      success: (payload) => AppSuccess(_sessionFromPayload(payload)),
      failure: AppFailure.new,
    );
  }

  Future<AppResult<AuthSession>> _authenticate({
    required String path,
    required String email,
    required String password,
  }) async {
    if (!providerConfig.hasRemoteConfig) {
      return const AppFailure(
        'Remote auth is not configured. Provide AUTH_BASE_URL and AUTH_PUBLIC_KEY.',
      );
    }

    final result = await _postJson(
      _buildUri(path: path),
      body: {'email': email, 'password': password},
    );
    return result.when(
      success: (payload) {
        final session = _sessionFromPayload(payload, fallbackEmail: email);
        if (session == null) {
          return const AppFailure('Auth response did not include a session.');
        }
        return AppSuccess(session);
      },
      failure: AppFailure.new,
    );
  }

  Uri _buildUri({required String path}) {
    final base = Uri.parse(providerConfig.baseUrl.trim());
    return base.resolve(path);
  }

  Future<AppResult<Object?>> _postJson(
    Uri uri, {
    required Map<String, Object?> body,
  }) async {
    try {
      final response = await _httpClient.post(
        uri,
        headers: {
          'content-type': 'application/json',
          if (providerConfig.hasPublicKey)
            'x-public-key': providerConfig.publicKey,
          'x-auth-provider': providerConfig.provider.label,
        },
        body: jsonEncode(body),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AppFailure(
          'Auth request failed with status ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      return AppSuccess(decoded);
    } on FormatException {
      return const AppFailure('Auth API returned invalid JSON.');
    } catch (_) {
      return const AppFailure('Auth request failed.');
    }
  }

  AuthSession? _sessionFromPayload(Object? payload, {String? fallbackEmail}) {
    final decoded = _normalizePayload(payload);
    if (decoded == null) {
      return null;
    }

    final userJson = _firstMap([
      decoded['user'],
      decoded['data'],
      decoded['profile'],
    ]);
    final user = userJson == null
        ? _userFromFlatPayload(decoded, fallbackEmail: fallbackEmail)
        : _userFromJson(userJson, fallbackEmail: fallbackEmail);
    if (user == null) {
      return null;
    }

    final sessionJson = _firstMap([decoded['session'], decoded['auth']]);
    final accessToken =
        _stringValue(
          sessionJson?['accessToken'] ??
              sessionJson?['access_token'] ??
              decoded['accessToken'] ??
              decoded['access_token'] ??
              decoded['token'],
        ) ??
        _stringValue(decoded['idToken']) ??
        _stringValue(decoded['id_token']);
    final refreshToken = _stringValue(
      sessionJson?['refreshToken'] ??
          sessionJson?['refresh_token'] ??
          decoded['refreshToken'] ??
          decoded['refresh_token'],
    );
    final provider =
        _stringValue(sessionJson?['provider'] ?? decoded['provider']) ??
        providerConfig.provider.label;
    final expiresAt = _dateTimeValue(
      sessionJson?['expiresAt'] ??
          sessionJson?['expires_at'] ??
          decoded['expiresAt'] ??
          decoded['expires_at'],
    );
    final createdAt =
        _dateTimeValue(sessionJson?['createdAt'] ?? decoded['createdAt']) ??
        DateTime.now();

    return AuthSession(
      user: user,
      createdAt: createdAt,
      accessToken: accessToken,
      refreshToken: refreshToken,
      provider: provider,
      expiresAt: expiresAt,
    );
  }

  Map<String, Object?>? _normalizePayload(Object? payload) {
    if (payload is Map<String, Object?>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, Object?>.from(payload);
    }
    return null;
  }

  Map<String, Object?>? _firstMap(List<Object?> values) {
    for (final value in values) {
      if (value is Map<String, Object?>) {
        return value;
      }
      if (value is Map) {
        return Map<String, Object?>.from(value);
      }
    }
    return null;
  }

  AppUser? _userFromJson(Map<String, Object?> json, {String? fallbackEmail}) {
    final id = _stringValue(json['id'] ?? json['userId']) ?? fallbackEmail;
    final email = _stringValue(json['email']) ?? fallbackEmail;
    final displayName =
        _stringValue(json['displayName'] ?? json['name']) ??
        (email?.split('@').first ?? 'User');
    if (id == null || email == null) {
      return null;
    }
    return AppUser(
      id: id,
      email: email,
      displayName: displayName,
      createdAt:
          _dateTimeValue(json['createdAt'] ?? json['created_at']) ??
          DateTime.now(),
    );
  }

  AppUser? _userFromFlatPayload(
    Map<String, Object?> json, {
    String? fallbackEmail,
  }) {
    final email = _stringValue(json['email']) ?? fallbackEmail;
    final id = _stringValue(json['id'] ?? json['userId']) ?? email;
    if (email == null || id == null) {
      return null;
    }
    return AppUser(
      id: id,
      email: email,
      displayName:
          _stringValue(json['displayName'] ?? json['name']) ??
          email.split('@').first,
      createdAt:
          _dateTimeValue(json['createdAt'] ?? json['created_at']) ??
          DateTime.now(),
    );
  }

  DateTime? _dateTimeValue(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String? _stringValue(Object? value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }
}
