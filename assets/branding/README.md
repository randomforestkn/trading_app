# Branding Assets

This folder is the placeholder landing zone for store and release artwork.
Use original artwork only. Do not commit copyrighted or licensed imagery
unless you have the rights to do so.

## Expected files

- `app_icon.png`
- `adaptive_icon_foreground.png`
- `adaptive_icon_background.png`
- `splash_logo.png`
- `store_feature_graphic.png`
- `screenshots/`

## Recommended sizes

- App icon: at least 1024x1024 PNG
- Adaptive foreground: transparent PNG, centered artwork, at least 432x432
- Adaptive background: solid or simple PNG, at least 432x432
- Splash logo: transparent PNG, optimized for dark background
- Feature graphic: 1024x500 PNG
- Screenshots: full-size device captures, crisp and uncluttered

## Guidance

- Keep the icon readable at small sizes.
- Avoid thin text inside the icon.
- Make the splash logo work on the dark theme background used by the app.
- Ensure screenshots match the shipping dark fintech UI.
- Use consistent spacing and do not include marketing claims that conflict with
  the paper trading / educational positioning.

## Android adaptive icon notes

- Foreground should be isolated from the background.
- Keep important details away from the edges.
- Test against circular and squircle masks.

## Replacement workflow

1. Add the finished artwork to this folder.
2. Update `flutter_launcher_icons.yaml` and `flutter_native_splash.yaml`.
3. Run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Store screenshot guidance

- Capture the app in dark mode only.
- Use the production-looking demo data path, not empty screens unless needed.
- Include the key product surfaces:
  - Home
  - Portfolio
  - Analytics
  - Strategy simulator
  - Options portfolio
  - Journal
  - Insights
  - Export / Restore
  - Settings / Diagnostics

## Placeholder status

- Native platform launcher icons and splash assets already exist.
- This folder is a staging area for centralized branding files.
- Release packaging should not depend on secret or proprietary artwork.
