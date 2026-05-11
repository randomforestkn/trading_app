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

## Remote auth

Remote auth is also optional and uses the same local-first fallback behavior. Do not commit auth URLs, public keys, or tokens.

Example remote auth run:

```bash
flutter run \
  --dart-define=APP_FLAVOR=staging \
  --dart-define=USE_REMOTE_AUTH=true \
  --dart-define=AUTH_PROVIDER=supabase \
  --dart-define=AUTH_BASE_URL=https://example.com \
  --dart-define=AUTH_PUBLIC_KEY=YOUR_PUBLIC_KEY \
  --dart-define=AUTH_REDIRECT_URL=myapp://auth
```

## Remote sync

Remote sync is optional and local-first remains the default. Do not commit sync URLs, namespaces, public keys, or tokens.

Example remote sync run:

```bash
flutter run \
  --dart-define=APP_FLAVOR=staging \
  --dart-define=USE_REMOTE_SYNC=true \
  --dart-define=SYNC_PROVIDER=supabase \
  --dart-define=SYNC_BASE_URL=https://example.com \
  --dart-define=SYNC_NAMESPACE=cleartrade_demo \
  --dart-define=SYNC_PUBLIC_KEY=YOUR_PUBLIC_KEY
```

If `USE_REMOTE_SYNC=true` is set without a valid base URL, the app falls back to local sync and keeps working offline. The cloud sync boundary is future-ready and does not auto-merge or overwrite local data.

## Notes

- Demo/local-first remains the default.
- Do not commit secrets, tokens, or real brokerage credentials.
- Do not commit auth public keys, client IDs, redirect URLs, or backend endpoints.
- Remote market data stays optional and should be configured outside source control.
- Remote sync stays optional and should be configured outside source control.
- Splash and launcher icon configuration is intentionally placeholder-safe until branded assets are finalized.
- See [provider integration runbook](provider_integration_runbook.md) for validation steps.
- See [provider environment examples](provider_env_examples.md) for placeholder Dart define templates.
- See `scripts/run_provider_validation_demo.sh` and `scripts/run_provider_validation_remote_template.sh` for local validation workflows.
- See [store listing draft](store_listing.md), [screenshot capture guide](screenshot_capture_guide.md), and [store submission checklist](store_submission_checklist.md) for store packaging.
- See `assets/branding/README.md` for branding asset requirements and replacement notes.

## Remote options chain data

Remote options chain data is optional and manual option entry remains the default. Do not commit API keys or provider URLs.

Example remote options run:

```bash
flutter run \
  --dart-define=APP_FLAVOR=staging \
  --dart-define=USE_REMOTE_OPTIONS_DATA=true \
  --dart-define=OPTIONS_PROVIDER=tradier \
  --dart-define=OPTIONS_BASE_URL=https://example.com/api \
  --dart-define=OPTIONS_API_KEY=YOUR_KEY \
  --dart-define=OPTIONS_MARKET_DATA_DELAYED=true
```

Providers may return delayed or partial data depending on the plan and endpoint. If the configuration is missing or the provider fails, the app falls back to manual/local option inputs and keeps working offline.

## Validation reminder

When validating any provider, use fake or placeholder values only. Never commit
keys, tokens, or service URLs to source control. The app should always remain
usable in demo/local-first mode if a provider is missing or fails.
