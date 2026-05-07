import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> clear();
}

class SharedPreferencesAuthStore implements AuthStore {
  static const _storageKey = 'auth_session_v1';

  @override
  Future<String?> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_storageKey);
  }

  @override
  Future<void> write(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, value);
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}

class MemoryAuthStore implements AuthStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}
