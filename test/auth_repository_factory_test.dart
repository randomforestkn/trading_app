import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/data/auth_provider_config.dart';
import 'package:trading_app/core/data/auth_repository_factory.dart';
import 'package:trading_app/core/data/local_demo_auth_repository.dart';
import 'package:trading_app/core/data/remote_auth_repository.dart';
import 'package:trading_app/core/config/build_config.dart';

void main() {
  test('default auth mode uses demo repository', () {
    final repo = AuthRepositoryFactory.buildDefault();

    expect(repo, isA<LocalDemoAuthRepository>());
  });

  test('remote auth config parsing works', () {
    final config = AuthProviderConfig.fromValues(
      provider: 'supabase',
      useRemoteAuth: true,
      baseUrl: 'https://example.com',
      publicKey: 'public',
      redirectUrl: 'myapp://auth',
    );

    expect(config.provider, AuthProvider.supabase);
    expect(config.isRemoteEnabled, isTrue);
    expect(config.providerLabel, 'Supabase');
  });

  test('missing remote auth config falls back safely', () {
    final repo = AuthRepositoryFactory.build(
      useRemote: true,
      baseUrl: '',
      publicKey: '',
      redirectUrl: '',
      flavor: AppFlavor.production,
    );

    expect(repo, isA<LocalDemoAuthRepository>());
  });

  test('remote auth config returns remote repository when configured', () {
    final repo = AuthRepositoryFactory.build(
      useRemote: true,
      baseUrl: 'https://example.com',
      publicKey: 'public',
      redirectUrl: 'myapp://auth',
      flavor: AppFlavor.production,
      providerConfig: AuthProviderConfig.fromValues(
        provider: 'supabase',
        useRemoteAuth: true,
        baseUrl: 'https://example.com',
        publicKey: 'public',
        redirectUrl: 'myapp://auth',
      ),
    );

    expect(repo, isA<RemoteAuthRepository>());
  });
}
