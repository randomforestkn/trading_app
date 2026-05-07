import 'package:flutter/widgets.dart';

import '../models/app_user.dart';
import '../utils/app_logger.dart';
import 'auth_repository.dart';
import 'local_demo_auth_repository.dart';

class AuthState extends ChangeNotifier {
  AuthState({AuthRepository? repository})
    : _repository = repository ?? const LocalDemoAuthRepository();

  final AuthRepository _repository;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    _setLoading(true);
    final result = await _repository.restoreSession();
    result.when(
      success: (session) {
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
    final result = await _repository.signInDemo();
    result.when(
      success: (session) {
        _currentUser = session.user;
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Demo sign-in failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
  }

  Future<void> signOut() async {
    _setLoading(true);
    final result = await _repository.signOut();
    result.when(
      success: (_) {
        _currentUser = null;
        _errorMessage = null;
      },
      failure: (message) {
        AppLogger.warn('Sign-out failed', error: message);
        _errorMessage = message;
      },
    );
    _setLoading(false);
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
