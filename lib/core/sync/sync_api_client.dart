import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/app_result.dart';
import '../utils/app_logger.dart';
import 'sync_operation.dart';
import 'sync_provider_config.dart';

abstract class SyncApiClient {
  SyncProviderConfig get config;

  Future<AppResult<void>> uploadSnapshot(
    String userId,
    Map<String, Object?> snapshot,
  );

  Future<AppResult<Map<String, Object?>>> downloadSnapshot(String userId);

  Future<AppResult<void>> pushOperation(String userId, SyncOperation operation);

  Future<AppResult<Map<String, Object?>>> fetchRemoteMetadata(String userId);

  Future<AppResult<Map<String, Object?>>> resolveConflict(
    String userId,
    Map<String, Object?> localSnapshot,
    Map<String, Object?> remoteSnapshot,
  );
}

class HttpSyncApiClient implements SyncApiClient {
  HttpSyncApiClient({required this.providerConfig, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final SyncProviderConfig providerConfig;
  final http.Client _httpClient;

  @override
  SyncProviderConfig get config => providerConfig;

  @override
  Future<AppResult<void>> uploadSnapshot(
    String userId,
    Map<String, Object?> snapshot,
  ) async {
    return _postJson(
      _buildUri(path: '/sync/snapshot', userId: userId),
      body: snapshot,
    ).then(
      (result) => result.when(
        success: (_) => const AppSuccess(null),
        failure: AppFailure.new,
      ),
    );
  }

  @override
  Future<AppResult<Map<String, Object?>>> downloadSnapshot(String userId) {
    return _getJson(_buildUri(path: '/sync/snapshot', userId: userId));
  }

  @override
  Future<AppResult<void>> pushOperation(
    String userId,
    SyncOperation operation,
  ) {
    return _postJson(
      _buildUri(path: '/sync/operations', userId: userId),
      body: operation.toJson(),
    ).then(
      (result) => result.when(
        success: (_) => const AppSuccess(null),
        failure: AppFailure.new,
      ),
    );
  }

  @override
  Future<AppResult<Map<String, Object?>>> fetchRemoteMetadata(String userId) {
    return _getJson(_buildUri(path: '/sync/metadata', userId: userId));
  }

  @override
  Future<AppResult<Map<String, Object?>>> resolveConflict(
    String userId,
    Map<String, Object?> localSnapshot,
    Map<String, Object?> remoteSnapshot,
  ) {
    return _postJson(
      _buildUri(path: '/sync/conflict/resolve', userId: userId),
      body: {'localSnapshot': localSnapshot, 'remoteSnapshot': remoteSnapshot},
    ).then(
      (result) => result.when(
        success: (payload) {
          final normalized = _normalizeObjectMap(payload);
          if (normalized == null) {
            return const AppFailure(
              'Sync API response did not include an object.',
            );
          }
          return AppSuccess(normalized);
        },
        failure: AppFailure.new,
      ),
    );
  }

  Uri _buildUri({required String path, required String userId}) {
    final base = Uri.parse(providerConfig.baseUrl.trim());
    return base.resolveUri(
      Uri(
        path: path,
        queryParameters: {
          'userId': userId,
          'namespace': providerConfig.namespace,
        },
      ),
    );
  }

  Future<AppResult<Map<String, Object?>>> _getJson(Uri uri) async {
    try {
      final response = await _httpClient.get(uri, headers: _headers());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AppFailure(
          'Sync API request failed with status ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(response.body);
      final payload = _normalizeObjectMap(decoded);
      if (payload == null) {
        return const AppFailure('Sync API response did not include an object.');
      }
      return AppSuccess(payload);
    } on FormatException {
      return const AppFailure('Sync API returned invalid JSON.');
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Sync API request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppFailure('Sync API request failed.');
    }
  }

  Future<AppResult<Object?>> _postJson(
    Uri uri, {
    required Map<String, Object?> body,
  }) async {
    try {
      final response = await _httpClient.post(
        uri,
        headers: {..._headers(), 'content-type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AppFailure(
          'Sync API request failed with status ${response.statusCode}.',
        );
      }
      if (response.body.trim().isEmpty) {
        return const AppSuccess(null);
      }
      final decoded = jsonDecode(response.body);
      return AppSuccess(decoded);
    } on FormatException {
      return const AppFailure('Sync API returned invalid JSON.');
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Sync API request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const AppFailure('Sync API request failed.');
    }
  }

  Map<String, String> _headers() {
    return {
      'x-sync-provider': providerConfig.providerLabel,
      'x-sync-namespace': providerConfig.namespace,
      if (providerConfig.hasPublicKey) 'x-public-key': providerConfig.publicKey,
    };
  }

  Map<String, Object?>? _normalizeObjectMap(Object? decoded) {
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
    return null;
  }
}
