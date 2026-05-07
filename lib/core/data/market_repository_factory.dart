import 'local_mock_market_repository.dart';
import 'market_api_client.dart';
import 'market_repository.dart';
import 'remote_market_repository.dart';

class MarketRepositoryFactory {
  const MarketRepositoryFactory._();

  static MarketRepository buildDefault() {
    const useRemote = bool.fromEnvironment(
      'USE_REMOTE_MARKET_DATA',
      defaultValue: false,
    );
    const baseUrl = String.fromEnvironment('MARKET_API_BASE_URL');
    const apiKey = String.fromEnvironment('MARKET_API_KEY');

    if (useRemote && baseUrl.isNotEmpty && apiKey.isNotEmpty) {
      return RemoteMarketRepository(
        apiClient: HttpMarketApiClient(baseUrl: baseUrl, apiKey: apiKey),
      );
    }

    return LocalMockMarketRepository();
  }
}
