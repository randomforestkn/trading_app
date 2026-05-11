# Store Submission Checklist

## Android

- [ ] App icon is finalized and tested against adaptive masks.
- [ ] Splash screen is finalized and matches the dark theme.
- [ ] Package name is correct.
- [ ] Release build signs correctly.
- [ ] Screenshots are prepared in the correct sizes.
- [ ] Store listing text matches the shipping app behavior.

## iOS

- [ ] App icon is finalized.
- [ ] Splash / launch screen is finalized.
- [ ] Bundle identifier is correct.
- [ ] Archive builds succeed.
- [ ] Screenshots are prepared in the correct sizes.
- [ ] TestFlight build uses the intended flavor and Dart defines.

## Verification

- [ ] Paper trading disclaimer is visible.
- [ ] No investment advice claim is present.
- [ ] No real brokerage execution is claimed.
- [ ] Export and restore flows work locally.
- [ ] Provider diagnostics show safe config presence only.
- [ ] No secret values appear in the UI, logs, or screenshots.
- [ ] Onboarding and legal surfaces are validated.
- [ ] Demo account instructions are ready for testers.

## Demo / test account notes

- [ ] Demo mode remains the default release path.
- [ ] Local-first data storage is documented.
- [ ] Reset instructions are available for a clean demo state.
- [ ] Journal, options, and insights can be seeded with example data.

## Packaging notes

- [ ] Launcher icon assets are ready.
- [ ] Splash assets are ready.
- [ ] Branding placeholders have been replaced or intentionally kept.
- [ ] Placeholder URLs and contact values are not shipped as real claims.

## Internal testing

- [ ] Verify the app in compact and wide layouts.
- [ ] Verify onboarding and disclaimer acceptance.
- [ ] Verify market, auth, sync, and options fallbacks.
- [ ] Verify export / restore, journaling, and options lifecycle flows.

## Final sign-off

- [ ] No real-money trading.
- [ ] No brokerage integration.
- [ ] No investment advice.
- [ ] No secrets in source control.
- [ ] Store metadata matches the app’s educational positioning.
