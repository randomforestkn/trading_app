#!/usr/bin/env bash
set -euo pipefail

# Replace placeholder values locally before running.
# Do not commit credentials, tokens, or URLs.

flutter run \
  --dart-define=APP_FLAVOR=staging \
  --dart-define=USE_REMOTE_MARKET_DATA=true \
  --dart-define=MARKET_API_PROVIDER=twelvedata \
  --dart-define=MARKET_API_BASE_URL=https://example.com/market \
  --dart-define=MARKET_API_KEY=YOUR_MARKET_API_KEY \
  --dart-define=USE_REMOTE_AUTH=true \
  --dart-define=AUTH_PROVIDER=supabase \
  --dart-define=AUTH_BASE_URL=https://example.com/auth \
  --dart-define=AUTH_PUBLIC_KEY=YOUR_AUTH_PUBLIC_KEY \
  --dart-define=USE_REMOTE_SYNC=true \
  --dart-define=SYNC_PROVIDER=supabase \
  --dart-define=SYNC_BASE_URL=https://example.com/sync \
  --dart-define=SYNC_PUBLIC_KEY=YOUR_SYNC_PUBLIC_KEY \
  --dart-define=SYNC_NAMESPACE=cleartrade_demo \
  --dart-define=USE_REMOTE_OPTIONS_DATA=true \
  --dart-define=OPTIONS_PROVIDER=tradier \
  --dart-define=OPTIONS_BASE_URL=https://example.com/options \
  --dart-define=OPTIONS_API_KEY=YOUR_OPTIONS_API_KEY \
  --dart-define=OPTIONS_MARKET_DATA_DELAYED=true
