# Provider Integration Runbook

This project is local-first by default. Remote providers are optional and must
be enabled with `--dart-define` values. Do not commit keys, tokens, URLs, or
provider credentials.

## What is validated

- Market data provider
- Authentication provider
- Sync provider
- Options chain provider
- Fallback behavior when config is missing
- Error behavior when providers fail or return malformed payloads
- Safe logging and diagnostics
- Store and release implications

## Validation checklist

### Market data provider

- Config present: provider, base URL, and API key are set.
- Missing config fallback: demo simulated prices remain active.
- Invalid key failure: API returns an error and the UI keeps working.
- Network failure: refresh surfaces a safe error message.
- Malformed response: repository returns `AppFailure`.
- Successful response mapping: remote quote data updates assets.
- Settings diagnostics: provider, mode, and config presence render.
- No secret logging: keys never appear in diagnostics or logs.

### Authentication provider

- Config present: provider, base URL, and public key are set.
- Missing config fallback: demo auth remains active.
- Invalid key failure: repository returns a safe failure.
- Network failure: sign-in/sign-up fails without crashing.
- Malformed response: session mapping fails safely.
- Successful response mapping: user/session data is restored.
- Settings diagnostics: provider and config presence render.
- No secret logging: tokens and keys never appear in diagnostics or logs.

### Sync provider

- Config present: provider, base URL, and namespace are set.
- Missing config fallback: local sync queue remains active.
- Invalid key failure: sync now reports a safe error.
- Network failure: queued operations remain pending.
- Malformed response: sync result fails safely.
- Successful response mapping: queued operations are marked synced.
- Settings diagnostics: provider and queue state render.
- No secret logging: keys never appear in diagnostics or logs.

### Options chain provider

- Config present: provider, base URL, and API key are set.
- Missing config fallback: manual option input remains active.
- Invalid key failure: chain fetch fails safely.
- Network failure: strategy simulator and option editor keep working.
- Malformed response: repository returns `AppFailure`.
- Successful response mapping: strikes, expirations, and quotes populate.
- Settings diagnostics: provider and config presence render.
- No secret logging: keys never appear in diagnostics or logs.

## Safe logging checklist

- Log failures only in debug mode.
- Do not log access tokens, API keys, public keys, or redirect URLs.
- Prefer provider names and high-level status labels.
- Keep error messages user-safe and short.

## Store and release implications

- Demo/local-first is the default shipping mode.
- Remote providers are opt-in through Dart defines.
- Release builds must use placeholder-safe docs and scripts.
- Production-like flavors should fail safe when remote config is missing.
- Public store builds must not require live credentials to launch.

## Recommended validation flow

1. Run the app in demo mode and verify all flows work offline.
2. Enable one provider at a time and confirm the fallback path.
3. Verify Settings diagnostics show readiness without exposing secrets.
4. Validate malformed payload handling with fake repositories or mocked clients.
5. Confirm release builds still pass tests in local-first mode.
