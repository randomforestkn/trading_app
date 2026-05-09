import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

abstract class OptionsPortfolioStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> clear();
}

class SharedPreferencesOptionsPortfolioStore implements OptionsPortfolioStore {
  static const _storageKey = AppConfig.optionsPortfolioStorageKey;

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

class MemoryOptionsPortfolioStore implements OptionsPortfolioStore {
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
