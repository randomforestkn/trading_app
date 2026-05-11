# Release Candidate Validation

This document defines the minimum validation pass for a demo or release-candidate build of ClearTrade.

## Validation scope
- Paper trading and options tracking
- Journal and insights
- Export and restore
- Sync diagnostics
- Onboarding and legal flows
- Accessibility and layout stability
- Offline/local-first behavior

## Required checks
1. First launch shows onboarding and accepts the required acknowledgements.
2. Home, Watchlist, Portfolio, Analytics, Journal, Strategy Simulator, Options Portfolio, Insights, Export & Reports, and Settings render without overflow.
3. Buy and sell paper trades execute locally and update portfolio and activity.
4. Options lifecycle actions render and persist correctly.
5. Journal entries can be created, edited, filtered, and deleted.
6. JSON backup export and restore preview work.
7. Restore confirmation replaces local data only after explicit approval.
8. Demo sign-in and sign-out work and do not erase unrelated local data.
9. Diagnostics show flavor, version, market mode, sync mode, auth mode, and storage mode.
10. Tooltips and semantic labels exist for icon-only or chart-like UI where practical.

## Pass criteria
- No analyzer warnings.
- No failing tests.
- No UI overflow on compact or wide smoke tests.
- No crash on startup restore failure or local repository failures.
- All disclaimers remain visible in the app.

## Notes
- The app is intentionally local-first and paper-trading-only by default.
- Do not validate with real brokerage credentials, real money, or production market keys in the release candidate path.
- If remote market data is enabled later, verify that missing configuration fails safely and does not silently expose placeholder URLs.

