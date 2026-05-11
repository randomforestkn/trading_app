# QA Checklist

Use this checklist before a release candidate build.

## First launch
- [ ] Onboarding appears on first launch.
- [ ] User can acknowledge paper trading, no-advice, and local-data responsibility.
- [ ] Onboarding does not reappear after acceptance.
- [ ] "View onboarding again" works from Settings.

## Core trading flow
- [ ] Market refresh works on Home and Watchlist.
- [ ] Buy and sell orders validate quantity and cash/shares correctly.
- [ ] Trade preview shows the order summary before execution.
- [ ] Portfolio updates after a successful trade.
- [ ] Activity updates after a successful trade.

## Portfolio and account controls
- [ ] Portfolio reset restores the default mock account.
- [ ] Clear order history removes activity without touching positions or cash.
- [ ] Demo auth sign-in and sign-out work.
- [ ] Sign-out does not erase paper trading or other local data.

## Analytics and strategy tools
- [ ] Analytics renders portfolio, activity, options income, and performance.
- [ ] Strategy simulator renders and calculates covered call, CSP, and wheel outputs.
- [ ] Options portfolio renders open and closed positions.
- [ ] Lifecycle actions such as close, expire, assign, and delete are confirmed.

## Journal and insights
- [ ] Journal add, edit, delete, and filter flows work.
- [ ] Insights render from journal, trading, and options data.
- [ ] Insight copy stays rule-based and does not claim real AI predictions.

## Export, restore, and sync
- [ ] JSON backup export works.
- [ ] CSV exports work for paper trades, journal, options positions, and options trades.
- [ ] Performance reports generate successfully.
- [ ] Restore preview validates a backup before applying it.
- [ ] Restore replaces local data only after confirmation.
- [ ] Sync diagnostics render and safe failures do not crash the app.

## Settings, legal, and diagnostics
- [ ] Disclaimer and data/privacy screens render.
- [ ] Diagnostics show flavor, version, sync mode, auth mode, and storage mode.
- [ ] Local-first, paper-trading-only, and no-advice disclaimers are visible.

## Layout and accessibility
- [ ] Compact phone layout does not overflow.
- [ ] Wide/tablet layout does not stretch content awkwardly.
- [ ] Icon-only actions have tooltips or semantic labels.
- [ ] Charts have semantic labels.
- [ ] Empty states remain readable.

## Offline and local-first behavior
- [ ] App remains usable without network access.
- [ ] Demo mode works without API keys.
- [ ] No real brokerage or real-money claims appear in the UI.

