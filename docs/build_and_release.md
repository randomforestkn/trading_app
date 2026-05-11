# Build and Release

## Local checks

```bash
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
```

## Demo build

```bash
flutter build apk --release \
  --dart-define=APP_FLAVOR=demo \
  --dart-define=APP_VERSION_LABEL=MVP\ Demo \
  --dart-define=APP_BUILD_LABEL=MVP\ Demo\ -\ Demo
```

## Staging build

```bash
flutter build appbundle --release \
  --dart-define=APP_FLAVOR=staging \
  --dart-define=USE_REMOTE_MARKET_DATA=true \
  --dart-define=MARKET_API_PROVIDER=twelvedata \
  --dart-define=MARKET_API_BASE_URL=https://example.com/api \
  --dart-define=MARKET_API_KEY=placeholder
```

## Production build

```bash
flutter build ios --release --no-codesign \
  --dart-define=APP_FLAVOR=production \
  --dart-define=APP_VERSION_LABEL=1.0.0 \
  --dart-define=APP_BUILD_LABEL=1.0.0
```

```bash
flutter build macos --release \
  --dart-define=APP_FLAVOR=production
```

## Remote market data

Remote market data is optional and must be enabled with Dart defines. Do not commit API keys or server URLs.

Example Twelve Data run:

```bash
flutter run \
  --dart-define=APP_FLAVOR=staging \
  --dart-define=USE_REMOTE_MARKET_DATA=true \
  --dart-define=MARKET_API_PROVIDER=twelvedata \
  --dart-define=MARKET_API_BASE_URL=https://api.twelvedata.com \
  --dart-define=MARKET_API_KEY=YOUR_KEY
```

Example Finnhub run:

```bash
flutter run \
  --dart-define=APP_FLAVOR=staging \
  --dart-define=USE_REMOTE_MARKET_DATA=true \
  --dart-define=MARKET_API_PROVIDER=finnhub \
  --dart-define=MARKET_API_BASE_URL=https://finnhub.io/api/v1 \
  --dart-define=MARKET_API_KEY=YOUR_KEY
```

## Notes

- Demo/local-first remains the default.
- Do not commit secrets, tokens, or real brokerage credentials.
- Remote market data stays optional and should be configured outside source control.
- Splash and launcher icon configuration is intentionally placeholder-safe until branded assets are finalized.
