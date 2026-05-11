# Provider Environment Examples

Use these examples as templates only. Replace placeholder values locally and do
not commit secrets.

## Demo/default mode

```bash
flutter run
```

## Remote market only

```bash
flutter run \
  --dart-define=USE_REMOTE_MARKET_DATA=true \
  --dart-define=MARKET_API_PROVIDER=twelvedata \
  --dart-define=MARKET_API_BASE_URL=https://api.twelvedata.com \
  --dart-define=MARKET_API_KEY=YOUR_MARKET_API_KEY
```

## Remote auth only

```bash
flutter run \
  --dart-define=USE_REMOTE_AUTH=true \
  --dart-define=AUTH_PROVIDER=supabase \
  --dart-define=AUTH_BASE_URL=https://example.com \
  --dart-define=AUTH_PUBLIC_KEY=YOUR_AUTH_PUBLIC_KEY
```

## Remote sync only

```bash
flutter run \
  --dart-define=USE_REMOTE_SYNC=true \
  --dart-define=SYNC_PROVIDER=supabase \
  --dart-define=SYNC_BASE_URL=https://example.com \
  --dart-define=SYNC_PUBLIC_KEY=YOUR_SYNC_PUBLIC_KEY \
  --dart-define=SYNC_NAMESPACE=cleartrade_demo
```

## Remote options chain only

```bash
flutter run \
  --dart-define=USE_REMOTE_OPTIONS_DATA=true \
  --dart-define=OPTIONS_PROVIDER=tradier \
  --dart-define=OPTIONS_BASE_URL=https://example.com/api \
  --dart-define=OPTIONS_API_KEY=YOUR_OPTIONS_API_KEY \
  --dart-define=OPTIONS_MARKET_DATA_DELAYED=true
```

## Full remote integration example

```bash
flutter run \
  --dart-define=APP_FLAVOR=staging \
  --dart-define=USE_REMOTE_MARKET_DATA=true \
  --dart-define=MARKET_API_PROVIDER=twelvedata \
  --dart-define=MARKET_API_BASE_URL=https://api.twelvedata.com \
  --dart-define=MARKET_API_KEY=YOUR_MARKET_API_KEY \
  --dart-define=USE_REMOTE_AUTH=true \
  --dart-define=AUTH_PROVIDER=supabase \
  --dart-define=AUTH_BASE_URL=https://example.com \
  --dart-define=AUTH_PUBLIC_KEY=YOUR_AUTH_PUBLIC_KEY \
  --dart-define=USE_REMOTE_SYNC=true \
  --dart-define=SYNC_PROVIDER=supabase \
  --dart-define=SYNC_BASE_URL=https://example.com \
  --dart-define=SYNC_PUBLIC_KEY=YOUR_SYNC_PUBLIC_KEY \
  --dart-define=SYNC_NAMESPACE=cleartrade_demo \
  --dart-define=USE_REMOTE_OPTIONS_DATA=true \
  --dart-define=OPTIONS_PROVIDER=tradier \
  --dart-define=OPTIONS_BASE_URL=https://example.com/api \
  --dart-define=OPTIONS_API_KEY=YOUR_OPTIONS_API_KEY \
  --dart-define=OPTIONS_MARKET_DATA_DELAYED=true
```

## Notes

- Demo mode remains the default.
- Use fake or placeholder credentials in examples.
- Never commit secrets, tokens, keys, or backend URLs.
