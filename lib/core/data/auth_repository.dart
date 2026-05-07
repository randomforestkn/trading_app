import '../models/app_user.dart';
import '../models/auth_session.dart';
import 'app_result.dart';

abstract class AuthRepository {
  Future<AppResult<AppUser?>> currentUser();

  Future<AppResult<AuthSession?>> restoreSession();

  Future<AppResult<AuthSession>> signInDemo();

  Future<AppResult<void>> signOut();

  Future<AppResult<AuthSession>> signInWithEmailPassword({
    required String email,
    required String password,
  });
}
