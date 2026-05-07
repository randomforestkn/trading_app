import 'package:shared_preferences/shared_preferences.dart';

abstract class PaperTradingStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> clear();
}

class SharedPreferencesPaperTradingStore implements PaperTradingStore {
  static const _storageKey = 'paper_trading_state_v1';

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

class MemoryPaperTradingStore implements PaperTradingStore {
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
