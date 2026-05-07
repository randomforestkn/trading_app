import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/auth_state.dart';
import 'package:trading_app/core/data/auth_store.dart';
import 'package:trading_app/core/data/local_demo_auth_repository.dart';

void main() {
  test('AuthRepository demo sign in and sign out', () async {
    final store = MemoryAuthStore();
    final repository = LocalDemoAuthRepository(store: store);

    final signIn = await repository.signInDemo();
    signIn.when(
      success: (session) {
        expect(session.user.email, 'demo@cleartrade.local');
        expect(store.value, isNotNull);
      },
      failure: fail,
    );

    final currentUser = await repository.currentUser();
    currentUser.when(
      success: (user) => expect(user?.displayName, 'Demo Trader'),
      failure: fail,
    );

    await repository.signOut();
    final restored = await repository.restoreSession();
    restored.when(success: (session) => expect(session, isNull), failure: fail);
    expect(store.value, isNull);
  });

  test('AuthState restores persisted session', () async {
    final store = MemoryAuthStore();
    final repository = LocalDemoAuthRepository(store: store);
    await repository.signInDemo();
    final authState = AuthState(repository: repository);

    await authState.restoreSession();

    expect(authState.isAuthenticated, isTrue);
    expect(authState.currentUser?.displayName, 'Demo Trader');
    expect(authState.isLoading, isFalse);
    expect(authState.errorMessage, isNull);
  });

  test('email password sign in returns not implemented failure', () async {
    final repository = LocalDemoAuthRepository(store: MemoryAuthStore());

    final result = await repository.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password',
    );

    result.when(
      success: (_) => fail('Expected not implemented failure'),
      failure: (message) => expect(message, contains('not implemented')),
    );
  });
}
