import 'package:flutter/widgets.dart';

import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../sync/sync_operation.dart';
import '../sync/sync_snapshots.dart';
import '../sync/sync_state.dart';
import 'app_result.dart';
import 'auth_repository.dart';
import 'local_demo_auth_repository.dart';
import '../utils/app_logger.dart';

class AuthState extends ChangeNotifier {
  AuthState({AuthRepository? repository, SyncState? syncState})
    : _repository = repository ?? const LocalDemoAuthRepository(),
      _syncState = syncState;

  final AuthRepository _repository;
  final SyncState? _syncState;
  AppUser? _currentUser;
  AuthSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;

  AuthSession? get currentSession => _currentSession;

  bool get isAuthenticated => _currentUser != null;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    _setLoading(true);
    late final AppResult<AuthSession?> result;
    try {
      result = await _repository.restoreSession();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Auth session restore threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to restore demo session.';
      _setLoading(false);
      return;
    }
    result.when(
      success: (session) {
        _currentSession = session;
        _currentUser = session?.user;
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Auth session restore failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
  }

  Future<void> signInDemo() async {
    _setLoading(true);
    late final AppResult<AuthSession> result;
    AuthSession? signedInSession;
    try {
      result = await _repository.signInDemo();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Demo sign-in threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to sign in to demo account.';
      _setLoading(false);
      return;
    }
    result.when(
      success: (session) {
        signedInSession = session;
        _currentSession = session;
        _currentUser = session.user;
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Demo sign-in failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
    if (_errorMessage == null && signedInSession != null) {
      await _enqueueSyncOperation(
        operationType: SyncOperationType.create,
        entityId: signedInSession!.user.id,
        payload: authSessionSnapshot(signedInSession),
      );
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    late final AppResult<void> result;
    final previousUserId = _currentUser?.id ?? 'auth-session';
    try {
      result = await _repository.signOut();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Demo sign-out threw unexpectedly',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Unable to sign out of demo account.';
      _setLoading(false);
      return;
    }
    result.when(
      success: (_) {
        _currentUser = null;
        _currentSession = null;
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Sign-out failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
    if (_errorMessage == null) {
      await _enqueueSyncOperation(
        operationType: SyncOperationType.delete,
        entityId: previousUserId,
        payload: authSessionSnapshot(null),
      );
    }
  }

  Future<void> _enqueueSyncOperation({
    required SyncOperationType operationType,
    required String entityId,
    required Map<String, Object?> payload,
  }) async {
    final syncState = _syncState;
    if (syncState == null) {
      return;
    }
    try {
      await syncState.enqueueOperation(
        buildSyncOperation(
          id: 'auth-${operationType.name}-${DateTime.now().microsecondsSinceEpoch}',
          entityType: SyncEntityType.authSession,
          operationType: operationType,
          entityId: entityId,
          createdAt: DateTime.now(),
          payload: payload,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Auth sync enqueue failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

class AuthScope extends InheritedNotifier<AuthState> {
  const AuthScope({required AuthState state, required super.child, super.key})
    : super(notifier: state);

  static AuthState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
