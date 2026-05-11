#!/bin/sh
set -eu

echo "Running release candidate validation for ClearTrade"
# flutter clean # Optional: use when you need a full rebuild.
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test

echo "Optional release build checks:"
echo "  flutter build apk --debug"
echo "  flutter build macos --debug"
echo "Use release build commands from docs/build_and_release.md for final packaging."
